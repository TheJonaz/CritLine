local addonName, addon = ...

-- WoW: Forever port: the combat log is closed to addons, so hits are read from UNIT_COMBAT instead.
-- That event names neither the spell nor the attacker, so records are kept per damage school, and a hit
-- only counts while you are attacking (auto attack, auto repeat or a cast in the last few seconds).
-- Optionally (off by default) a hit is matched to the spell you just cast, to guess per-spell records.

local module = CreateFrame("Frame")
addon.unitCombat = module

local L = addon.L
local issecretvalue = issecretvalue
local GetTime = GetTime
local abs = math.abs
local GetSpellName = C_Spell.GetSpellName

-- seconds a hit may trail your cast (travel time)
local ACTION_WINDOW = 3
-- Thorns and damage shields strike back the moment you are hit
local REACTIVE_WINDOW = 0.2

-- per-spell guessing
local AUTO_ATTACK_ID = 6603
-- a spell gets its own records once this many casts were seen and enough of them hit
local CONFIRM_CASTS = 3
local CONFIRM_RATE = 0.5
-- counts are halved past this, so learned data adapts
local MAX_COUNT = 40
-- casts older than this are dropped regardless of the window setting
local MAX_WINDOW = 5
-- instant melee abilities hit right away; a physical hit later than this while auto attack is on is a swing
local MELEE_WINDOW = 0.4

local lastCastTime = -math.huge
local lastHitTakenTime = -math.huge
local meleeActive, autoRepeatActive = false, false

-- for /cl status
local lastEvent, lastEventTime, lastResult

local function isSecret(...)
	if not issecretvalue then
		return false
	end
	for i = 1, select("#", ...) do
		if issecretvalue((select(i, ...))) then
			return true
		end
	end
	return false
end

-- returns value, or fallback if the value is secret
local function readable(value, fallback)
	if isSecret(value) then
		return fallback
	end
	return value
end

-- keep the last hits and their results in CritlineDiag (SavedVariables)
local MAX_LOG = 60

local function logResult()
	if not (CritlineDiag and lastEvent) then return end
	local log = CritlineDiag.log
	log[#log + 1] = format("%s %s -> %s", date("%H:%M:%S"), lastEvent, lastResult or "?")
	if #log > MAX_LOG then
		tremove(log, 1)
	end
end

-- remember why a hit was not recorded
local function skip(reason)
	lastResult = "skipped: "..reason
	addon:Debug("Skipped hit. "..reason..".")
	logResult()
end

local function castRecently()
	return GetTime() - lastCastTime <= ACTION_WINDOW
end

local function isAttacking()
	return meleeActive or autoRepeatActive or castRecently()
end

-- your pet is attacking your target
local function petAttacking()
	if not readable(UnitExists("pet"), false) then
		return false
	end
	return readable(UnitIsUnit("pettarget", "target"), false) == true
end

-- mob tagged by someone outside your group: its damage isn't yours
local function tappedByOthers()
	return UnitIsTapDenied and readable(UnitIsTapDenied("target"), false) == true
end

--------------------------------------------------------------------------------
-- Per-spell guessing
--
-- UNIT_SPELLCAST_SUCCEEDED tells which spell you cast; UNIT_COMBAT tells that something hit your target.
-- A hit is matched to the oldest recent cast that hasn't hit yet and whose school (learned from earlier hits)
-- matches. A spell only gets its own records once most of its casts were followed by a hit, so casts that
-- deal no damage (Sunder Armor, Hunter's Mark) don't take the credit for your auto attacks.
--------------------------------------------------------------------------------

local recentCasts = {}
local channelCast

local function perSpellEnabled()
	return addon.db.profile.unitCombatPerSpell
end

local function learned()
	return addon.db.global.unitCombatSpells
end

local function getStats(spellID)
	local spells = learned()
	local stats = spells[spellID]
	if not stats then
		stats = {casts = 0, hits = 0}
		spells[spellID] = stats
	end
	return stats
end

local function halve(tbl)
	for k, v in pairs(tbl) do
		if type(v) == "number" then
			tbl[k] = floor(v / 2)
		end
	end
end

-- the school a spell's hits of this kind ("dmg" or "heal") most often had
local function learnedSchool(spellID, kind)
	local stats = learned()[spellID]
	local votes = stats and stats[kind]
	if not votes then return end
	local best, bestCount
	for mask, count in pairs(votes) do
		if not bestCount or count > bestCount then
			best, bestCount = mask, count
		end
	end
	return best
end

local function voteSchool(spellID, kind, schoolMask)
	local stats = getStats(spellID)
	local votes = stats[kind] or {}
	stats[kind] = votes
	votes[schoolMask] = (votes[schoolMask] or 0) + 1
	if votes[schoolMask] > MAX_COUNT then
		halve(votes)
	end
end

-- a spell is trusted with its own records when enough of its casts hit something
local function isConfirmed(spellID)
	local stats = learned()[spellID]
	return stats and stats.casts >= CONFIRM_CASTS and stats.hits / stats.casts >= CONFIRM_RATE
end

-- count a cast once it can no longer hit
local function closeCast(cast)
	local stats = getStats(cast.spellID)
	stats.casts = stats.casts + 1
	if cast.used then
		stats.hits = stats.hits + 1
	end
	if stats.casts > MAX_COUNT then
		halve(stats)
	end
end

local function pruneCasts(now)
	local window = min(addon.db.profile.unitCombatSpellWindow or 2.5, MAX_WINDOW)
	while recentCasts[1] and (recentCasts[1].used or now - recentCasts[1].time > window) do
		closeCast(tremove(recentCasts, 1))
	end
	-- used casts further down the list are closed when they reach the front
end

-- true if the client says the spell can be used on enemies (dmg) or friends (heal); unknown counts as yes
local function spellFits(spellID, kind)
	local name = GetSpellName(spellID)
	local isHarmful = C_Spell.IsSpellHarmful or (name and IsHarmfulSpell and function() return IsHarmfulSpell(name) end)
	local isHelpful = C_Spell.IsSpellHelpful or (name and IsHelpfulSpell and function() return IsHelpfulSpell(name) end)
	local okHarm, harmful = pcall(isHarmful or nop, spellID)
	local okHelp, helpful = pcall(isHelpful or nop, spellID)
	harmful = okHarm and readable(harmful) or nil
	helpful = okHelp and readable(helpful) or nil
	if harmful == nil and helpful == nil then
		return true
	end
	if kind == "heal" then
		return helpful and true or false
	end
	return harmful and true or false
end

local function addCast(spellID, now)
	if spellID == AUTO_ATTACK_ID then return end
	if channelCast and channelCast.spellID == spellID then return end
	pruneCasts(now)
	recentCasts[#recentCasts + 1] = {
		spellID = spellID,
		time = now,
		dmg = spellFits(spellID, "dmg"),
		heal = spellFits(spellID, "heal"),
	}
end

-- learned average seconds from cast to hit (travel time)
local function learnDelay(spellID, age)
	local stats = getStats(spellID)
	stats.delay = stats.delay and (stats.delay * 0.75 + age * 0.25) or age
end

-- how badly a cast fits a hit 'age' seconds after it: closest to the learned delay wins,
-- spells without a learned delay come after those, oldest first
local function castScore(cast, age)
	local stats = learned()[cast.spellID]
	if stats and stats.delay then
		return abs(age - stats.delay)
	end
	return MAX_WINDOW + (MAX_WINDOW - age)
end

-- find the cast that most likely caused this hit; returns spellID, periodic, seconds since the cast
local function matchHit(kind, schoolMask, now)
	pruneCasts(now)
	local maxAge = (kind == "dmg" and schoolMask == 1 and meleeActive) and MELEE_WINDOW or MAX_WINDOW
	local exact, exactScore, unknown
	for i, cast in ipairs(recentCasts) do
		local age = now - cast.time
		if not cast.used and cast[kind] and age <= maxAge then
			local school = learnedSchool(cast.spellID, kind)
			if school == schoolMask then
				local score = castScore(cast, age)
				if not exact or score < exactScore then
					exact, exactScore = cast, score
				end
			elseif school == nil and not unknown then
				unknown = cast
			end
		end
	end
	local cast = exact or unknown
	if cast then
		local age = now - cast.time
		cast.used = true
		voteSchool(cast.spellID, kind, schoolMask)
		learnDelay(cast.spellID, age)
		pruneCasts(now)
		return cast.spellID, 1, age
	end
	-- channelled spells hit several times while the channel lasts
	if channelCast and channelCast[kind] then
		local school = learnedSchool(channelCast.spellID, kind)
		if school == nil or school == schoolMask then
			channelCast.used = true
			voteSchool(channelCast.spellID, kind, schoolMask)
			return channelCast.spellID, 2, now - channelCast.time
		end
	end
end

-- a miss, dodge etc. still means a cast reached your target
local function consumeMiss(schoolMask)
	if type(schoolMask) ~= "number" or not isAttacking() then return end
	matchHit("dmg", schoolMask, GetTime())
end

function module:PrintLearnedSpells()
	local list = {}
	for spellID, stats in pairs(learned()) do
		list[#list + 1] = spellID
	end
	if #list == 0 then
		addon:Message("No spells learned yet. Turn on per-spell records and cast some spells at a target.")
		return
	end
	sort(list, function(a, b) return (GetSpellName(a) or "") < (GetSpellName(b) or "") end)
	for _, spellID in ipairs(list) do
		local stats = learned()[spellID]
		local dmgSchool, healSchool = learnedSchool(spellID, "dmg"), learnedSchool(spellID, "heal")
		addon:Message(format("%s (%d): %d of %d casts hit, %s%s%s", GetSpellName(spellID) or "?", spellID, stats.hits, stats.casts,
			isConfirmed(spellID) and "|cff00ff00own records|r" or "|cffffff00not confirmed yet|r",
			dmgSchool and ", damage: "..addon:GetSchoolName(dmgSchool) or "",
			healSchool and ", healing: "..addon:GetSchoolName(healSchool) or ""))
	end
end

function module:ForgetLearnedSpells()
	wipe(learned())
	wipe(recentCasts)
	channelCast = nil
	addon:Message("Forgot what per-spell records had learned about your spells. Your records are kept.")
end

-- options page; only used while the combat log is closed
do
	local config = addon.config:AddSubCategory(L["Per-spell records"], true)
	config:SetDescription(L["When the combat log is closed to addons (see /cl status), the game doesn't say which spell hit. These options let Critline guess it from the spell you just cast. Guesses can be wrong. With the combat log, records are per spell anyway."])

	local function perSpellOff()
		return not addon.db.profile.unitCombatPerSpell
	end

	-- Libra doesn't pass useProfile on to sub-pages, so read and write the profile directly
	local function get(self)
		return addon.db.profile[self.key]
	end

	local function set(self, value)
		addon.db.profile[self.key] = value
	end

	config:CreateOptions({
		{
			type = "Section",
			text = L["Per-spell records"],
		},
		{
			type = "CheckButton",
			text = L["Guess per-spell records"],
			tooltip = L["Match each hit to the spell you cast just before it, and keep records for that spell. Physical hits while auto attack is on and no spell matches are recorded as Auto Attack. Hits that can't be matched are recorded per school.\n\nA spell gets its own records after a few casts, once Critline has seen that its casts hit. DoT ticks, procs, your pet's hits and several spells in flight at once can be credited to the wrong spell. Type /cl spells to see what has been learned."],
			key = "unitCombatPerSpell",
			get = get,
			set = set,
		},
		{
			type = "CheckButton",
			text = L["Keep school records too"],
			tooltip = L["Also record hits matched to a spell in their school (Physical, Fire, ...), like when this option is off. Disable to only see per-spell records for matched hits."],
			key = "unitCombatKeepSchool",
			get = get,
			set = set,
			disabled = perSpellOff,
		},
		{
			type = "Slider",
			text = L["Match window (seconds)"],
			tooltip = L["How long after a cast a hit can still be credited to it. Raise it for slow spells with long travel time, lower it if hits are credited to the wrong spell."],
			key = "unitCombatSpellWindow",
			get = get,
			set = set,
			min = 0.5,
			max = MAX_WINDOW,
			step = 0.5,
			padding = 4,
			disabled = perSpellOff,
		},
	})

	-- not every client's Slider has SetEnabled
	local slider = config:GetControlByKey("unitCombatSpellWindow")
	if slider and not slider.SetEnabled then
		function slider:SetEnabled(enabled)
			if enabled then self:Enable() else self:Disable() end
		end
	end
end

function module:Enable()
	addon:DiagStep("UnitCombat enabled")
	self:RegisterUnitEvent("UNIT_COMBAT", "target", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
	self:RegisterEvent("PLAYER_ENTER_COMBAT")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT")
	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
end

function module:PrintStatus()
	addon:Message(format("UNIT_COMBAT registered: %s; auto attack: %s, auto repeat: %s, cast in last %ds: %s",
		tostring(self:IsEventRegistered("UNIT_COMBAT")), tostring(meleeActive), tostring(autoRepeatActive), ACTION_WINDOW, tostring(castRecently())))
	local learnedCount, confirmedCount = 0, 0
	for spellID in pairs(learned()) do
		learnedCount = learnedCount + 1
		if isConfirmed(spellID) then
			confirmedCount = confirmedCount + 1
		end
	end
	addon:Message(format("Per-spell records: %s (window %.1fs, keep school records: %s); %d spells seen, %d with own records (/cl spells)",
		tostring(perSpellEnabled()), addon.db.profile.unitCombatSpellWindow or 0, tostring(addon.db.profile.unitCombatKeepSchool), learnedCount, confirmedCount))
	if lastEvent then
		addon:Message(format("Last hit event %ds ago: %s; %s", floor(GetTime() - lastEventTime), lastEvent, lastResult or "?"))
	else
		addon:Message("No hit events seen since login.")
	end
end

local function onError(err)
	err = tostring(err).."\n"..debugstack(2)
	if CritlineDiag then
		local errors = CritlineDiag.errors
		if #errors < 20 then
			errors[#errors + 1] = err
		end
	end
	return err
end

module:SetScript("OnEvent", function(self, event, ...)
	local ok, err = xpcall(self[event], onError, self, ...)
	if not ok then
		geterrorhandler()(err)
	end
end)

function module:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	lastCastTime = GetTime()
	if perSpellEnabled() and type(spellID) == "number" and not isSecret(spellID) then
		addCast(spellID, lastCastTime)
	end
end

function module:UNIT_SPELLCAST_CHANNEL_START(unit, castGUID, spellID)
	lastCastTime = GetTime()
	if not perSpellEnabled() or type(spellID) ~= "number" or isSecret(spellID) then return end
	-- the channel's own SUCCEEDED event must not count as a separate cast
	for i = #recentCasts, 1, -1 do
		if recentCasts[i].spellID == spellID and not recentCasts[i].used then
			tremove(recentCasts, i)
		end
	end
	if channelCast then
		closeCast(channelCast)
	end
	channelCast = {
		spellID = spellID,
		time = lastCastTime,
		dmg = spellFits(spellID, "dmg"),
		heal = spellFits(spellID, "heal"),
	}
end

function module:UNIT_SPELLCAST_CHANNEL_STOP()
	-- the last tick may land just after the channel ends
	lastCastTime = GetTime()
	if channelCast then
		local cast = channelCast
		C_Timer.After(0.5, function()
			if channelCast == cast then
				closeCast(cast)
				channelCast = nil
			end
		end)
	end
end

function module:PLAYER_ENTER_COMBAT()
	meleeActive = true
end

function module:PLAYER_LEAVE_COMBAT()
	meleeActive = false
end

function module:START_AUTOREPEAT_SPELL()
	autoRepeatActive = true
end

function module:STOP_AUTOREPEAT_SPELL()
	autoRepeatActive = false
end

function module:UNIT_COMBAT(unit, action, flagText, amount, schoolMask)
	if isSecret(action, flagText, amount, schoolMask) then
		lastEvent, lastEventTime = unit.." (secret values)", GetTime()
		skip("Combat values are secret")
		return
	end

	local isHeal = action == "HEAL"

	if unit == "player" then
		if action == "WOUND" then
			lastHitTakenTime = GetTime()
			return
		end
		-- heals on yourself count; damage you take does not
		if not isHeal then
			return
		end
	elseif action ~= "WOUND" and not isHeal then
		if perSpellEnabled() then
			consumeMiss(schoolMask)
		end
		return
	end

	lastEvent = format("%s %s %s %s school %s", unit, tostring(action), tostring(amount), tostring(flagText), tostring(schoolMask))
	lastEventTime = GetTime()
	lastResult = nil

	if type(amount) ~= "number" or amount <= 0 then
		skip("No amount")
		return
	end

	local profile = addon.db.profile
	local critical = flagText == "CRITICAL"
	local tree = isHeal and "heal" or "dmg"

	-- in a group the hit may come from someone else
	if profile.unitCombatSoloOnly and IsInGroup() then
		skip("In a group and 'Only record while solo' is enabled")
		return
	end

	local canAttack = readable(UnitCanAttack("player", unit), false)

	if isHeal then
		if not castRecently() then
			skip("Heal without a recent cast")
			return
		end
		if canAttack then
			skip("Healing a hostile target")
			return
		end
	else
		if not canAttack then
			skip("Target can't be attacked")
			return
		end
		if tappedByOthers() then
			skip("Target is tagged by someone else")
			return
		end
		-- while you attack, your pet's hits can't be told apart from yours and count as yours;
		-- while only your pet attacks your target, the hit is the pet's
		if not isAttacking() then
			if not petAttacking() then
				skip("Neither you nor your pet is attacking")
				return
			end
			tree = "pet"
		end
	end

	-- best guess which spell this was (not for your pet: its casts aren't seen)
	local guessedID, periodic, castAge
	if profile.unitCombatPerSpell and tree ~= "pet" then
		guessedID, periodic, castAge = matchHit(tree, schoolMask, GetTime())
	end

	if not isHeal then
		if not guessedID and profile.unitCombatIgnoreReactive and schoolMask ~= 1 and not critical and GetTime() - lastHitTakenTime <= REACTIVE_WINDOW then
			skip("Reactive damage")
			return
		end
	end

	if not addon.percharDB.profile[tree] then
		skip(format("Not recording %s", tree))
		return
	end

	local destName = readable(UnitName(unit), UNKNOWN) or UNKNOWN
	local destGUID = readable(UnitGUID(unit))
	local targetLevel = readable(UnitLevel(unit), 0) or 0
	local isPvPTarget = readable(UnitIsPlayer(unit), false) and unit ~= "player"

	if not (isPvPTarget or profile.PvE or isHeal) then
		skip(format("%s is an NPC and PvE damage is not registered", destName))
		return
	end

	if isPvPTarget and not (profile.PvP or isHeal) then
		skip(format("%s is a player and PvP damage is not registered", destName))
		return
	end

	local schoolID = -schoolMask

	-- the spell record, if a confirmed spell was matched (or Auto Attack for an unmatched melee swing)
	local spellID, how
	if profile.unitCombatPerSpell and tree == "dmg" and not guessedID and schoolMask == 1 and meleeActive then
		spellID, periodic, how = AUTO_ATTACK_ID, 1, "auto attack is on and no spell matched"
	elseif guessedID then
		if isConfirmed(guessedID) then
			spellID = guessedID
			how = format("cast %.1fs ago%s", castAge, periodic == 2 and ", channel tick" or "")
		else
			addon:Debug(format("Hit matched to %s (cast %.1fs ago), not confirmed yet; recorded per school.", GetSpellName(guessedID) or guessedID, castAge))
		end
	elseif profile.unitCombatPerSpell and tree ~= "pet" then
		addon:Debug(format("Hit %d (%s) matched no spell; recorded per school.", amount, addon:GetSchoolName(schoolMask)))
	end

	local results = {}

	local function store(id, periodic)
		local isFiltered
		if addon.filters then
			local passed
			passed, isFiltered = addon.filters:TargetPassesFilters(tree, id, destGUID, destName, targetLevel)
			if not passed then
				results[#results + 1] = format("skipped by filters (target level %s, level filter %s)", tostring(targetLevel), tostring(addon.filters.profile.levelFilter))
				return
			end
		end
		addon:StoreRecord(tree, id, periodic, amount, critical, destName, targetLevel, isPvPTarget, isFiltered)
		results[#results + 1] = format("recorded in %s as %s%s", tree, addon:GetSpellName(id) or tostring(id), isFiltered and " (filtered spell)" or "")
	end

	if spellID then
		addon:Debug(format("Hit %d credited to %s (%s).", amount, GetSpellName(spellID) or spellID, how))
		store(spellID, periodic)
	end
	if not spellID or profile.unitCombatKeepSchool then
		store(schoolID, 1)
	end

	lastResult = table.concat(results, "; ")
	logResult()
end
-- diagnostics: this file loaded to the end
do
	local ns = select(2, ...)
	ns.loadedFiles = ns.loadedFiles or {}
	ns.loadedFiles[#ns.loadedFiles + 1] = "UnitCombat"
end
