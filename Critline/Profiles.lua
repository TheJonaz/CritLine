local CRITLINE, Critline = ...

local profiles = Critline.config:AddSubCategory("Profiles")
profiles:SetDescription("This profile controls all settings that are not related to individual trees or their records.")

local spellProfiles = Critline.config:AddSubCategory("Spell profiles")
spellProfiles:SetDescription("This profile stores individual tree settings, including which trees will be registered, and spell records.")

local profileUI = Critline:NewModule("Profiles")

function profileUI:OnInitialize()
	-- WoW: Forever port: skip the profile controls if Libra's AceDBControls failed to load
	if not Critline.CreateAceDBControls then
		Critline:DiagStep("AceDBControls missing")
		return
	end
	Critline:CreateAceDBControls(Critline.db, profiles):SetPoint("CENTER")
	Critline:CreateAceDBControls(Critline.percharDB, spellProfiles):SetPoint("CENTER")
end
-- diagnostics: this file loaded to the end
do
	local ns = select(2, ...)
	ns.loadedFiles = ns.loadedFiles or {}
	ns.loadedFiles[#ns.loadedFiles + 1] = "Profiles"
end
