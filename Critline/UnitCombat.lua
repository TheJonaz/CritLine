local addonName, addon = ...

-- WoW: Forever port: the combat log is closed to addons, so hits are read from UNIT_COMBAT instead.
-- That event names neither the spell nor the attacker, so records are kept per damage school, and a hit
-- only counts while you are attacking (auto attack, auto repeat or a cast in the last few seconds).

local module = CreateFrame("Frame")
addon.unitCombat = module

local issecretvalue = issecretvalue
local GetTime = GetTime

-- seconds a hit may trail your cast (travel time)
local ACTION_WINDOW = 3
-- Thorns and damage shields strike back the moment you are hit
local REACTIVE_WINDOW = 0.2

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

-- remember why a hit was not recorded
local function skip(reason)
	lastResult = "skipped: "..reason
	addon:Debug("Skipped hit. "..reason..".")
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

function module:Enable()
	self:RegisterUnitEvent("UNIT_COMBAT", "target", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	self:RegisterEvent("PLAYER_ENTER_COMBAT")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT")
	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
end

function module:PrintStatus()
	addon:Message(format("UNIT_COMBAT registered: %s; auto attack: %s, auto repeat: %s, cast in last %ds: %s",
		tostring(self:IsEventRegistered("UNIT_COMBAT")), tostring(meleeActive), tostring(autoRepeatActive), ACTION_WINDOW, tostring(castRecently())))
	if lastEvent then
		addon:Message(format("Last hit event %ds ago: %s; %s", floor(GetTime() - lastEventTime), lastEvent, lastResult or "?"))
	else
		addon:Message("No hit events seen since login.")
	end
end

module:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function module:UNIT_SPELLCAST_SUCCEEDED()
	lastCastTime = GetTime()
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
		if profile.unitCombatIgnoreReactive and schoolMask ~= 1 and not critical and GetTime() - lastHitTakenTime <= REACTIVE_WINDOW then
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

	local spellID = -schoolMask

	local isFiltered
	if addon.filters then
		local passed
		passed, isFiltered = addon.filters:TargetPassesFilters(tree, spellID, destGUID, destName, targetLevel)
		if not passed then
			lastResult = "skipped by filters (see /cl debug)"
			return
		end
	end

	addon:StoreRecord(tree, spellID, 1, amount, critical, destName, targetLevel, isPvPTarget, isFiltered)
	lastResult = format("recorded in %s%s", tree, isFiltered and " (filtered spell)" or "")
end
