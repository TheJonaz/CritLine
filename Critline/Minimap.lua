local CRITLINE, Critline = ...
local L = Critline.L

local function onUpdate(self)
	local xpos, ypos = GetCursorPosition()
	local xmin, ymin = Minimap:GetCenter()
	
	xpos = xpos / Minimap:GetEffectiveScale() - xmin
	ypos = ypos / Minimap:GetEffectiveScale() - ymin
	
	local pos = atan2(ypos, xpos)
	self.db.profile.pos = pos
	self:Move(pos)
end

local minimap = Critline:NewModule("Minimap", CreateFrame("Button", "CritlineMinimapButton", Minimap))
minimap:SetToplevel(true)
minimap:SetMovable(true)
minimap:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimap:RegisterForDrag("LeftButton")
minimap:SetSize(32, 32)
minimap:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
minimap:SetFrameLevel(8)
minimap:Hide()
minimap:SetScript("OnClick", function(self, button)
	local display = Critline:GetModule("Display")
	if button == "LeftButton" and display then
		display:Toggle()
	elseif button == "RightButton" then
		Critline:OpenConfig()
	end
end)
minimap:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("Critline")
	if Critline:GetModule("Display") then
		GameTooltip:AddLine(L["Left-click to toggle summary frame"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	end
	GameTooltip:AddLine(L["Right-click to open options"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	if not self.db.profile.locked then
		GameTooltip:AddLine(L["Drag to move"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	end
	GameTooltip:Show()
end)
minimap:SetScript("OnLeave", GameTooltip_Hide)
minimap:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onUpdate) end)
minimap:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
minimap:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)

local icon = minimap:CreateTexture()
icon:SetSize(20, 20)
icon:SetPoint("TOPLEFT", 6, -6)
icon:SetTexture(Critline.trees.dmg.icon)

local border = minimap:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")
border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])

local config = Critline.config:AddSubCategory(L["Minimap"])

config:CreateOptions({
	{
		type = "CheckButton",
		text = L["Show"],
		tooltip = L["Show minimap button."],
		key = "show",
		func = "SetShown",
	},
	{
		type = "CheckButton",
		text = L["Locked"],
		tooltip = L["Lock minimap button."],
		key = "locked",
		func = function(self, checked)
			if checked then
				minimap:RegisterForDrag()
			else
				minimap:RegisterForDrag("LeftButton")
			end
		end,
	},
})


local defaults = {
	profile = {
		show = true,
		locked = false,
		pos = 225,
	}
}

function minimap:OnInitialize()
	self.db = Critline.db:RegisterNamespace("minimap", defaults)
	Critline.RegisterCallback(self, "SettingsLoaded", "LoadSettings")
	
	config:SetDatabase(self.db, true)
	config:SetHandler(self)
	
	self:LoadSettings()
end

function minimap:LoadSettings()
	config:SetupControls()
	self:Move(self.db.profile.pos)
end

-- the minimap may not have its final size or shape when settings load (other addons and the client
-- resize it after login), so place the button again once the world is loaded and whenever it changes
-- RegisterEvent here is Libra's (the module embeds it), which calls the handler with the module as self
minimap:RegisterEvent("PLAYER_ENTERING_WORLD", function(self)
	if self.db then
		self:Move(self.db.profile.pos)
	end
end)
Minimap:HookScript("OnSizeChanged", function()
	if minimap.db then
		minimap:Move(minimap.db.profile.pos)
	end
end)

-- per minimap shape, which quadrants are rounded (same table as LibDBIcon)
local minimapShapes = {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

-- angle is in degrees; keep the button on the minimap's edge whatever its size and shape
function minimap:Move(angle)
	local x, y = cos(angle), sin(angle)
	local q = 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local quadTable = minimapShapes[shape] or minimapShapes.ROUND
	local w = (Minimap:GetWidth() / 2) + 5
	local h = (Minimap:GetHeight() / 2) + 5
	if quadTable[q] then
		x, y = x * w, y * h
	else
		local diagW = sqrt(2 * w ^ 2) - 10
		local diagH = sqrt(2 * h ^ 2) - 10
		x = max(-w, min(x * diagW, w))
		y = max(-h, min(y * diagH, h))
	end
	self:ClearAllPoints()
	self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
-- diagnostics: this file loaded to the end
do
	local ns = select(2, ...)
	ns.loadedFiles = ns.loadedFiles or {}
	ns.loadedFiles[#ns.loadedFiles + 1] = "Minimap"
end
