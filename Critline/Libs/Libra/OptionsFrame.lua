local Libra = LibStub("Libra")
local Type, Version = "OptionsFrame", 8
if Libra:GetModuleVersion(Type) >= Version then return end

Libra.modules[Type] = Libra.modules[Type] or {}

local Options = Libra.modules[Type]

Options.Prototype = Options.Prototype or CreateFrame("Frame")
Options.ParentPrototype = Options.ParentPrototype or {}
Options.controls = Options.controls or {}
Options.controlData = Options.controlData or {}

local mt = {__index = Options.Prototype}
local parentMT = {__index = setmetatable(Options.ParentPrototype, {__index = Options.Prototype})}

local Prototype = Options.Prototype
local ParentPrototype = Options.ParentPrototype

-- categories keep the ID the settings API gave them: OpenToCategory needs it on 12.0 (Midnight, WoW: Forever),
-- and writing to a Blizzard category taints the settings panel, so opening it fails in Classic Era

-- height of the page header; controls start below it
local HEADER_HEIGHT = 72

local function createFrame(name, parent)
	local frame = CreateFrame("Frame")

	if parent then
		local subCategory, layout = Settings.RegisterCanvasLayoutSubcategory(parent, frame, name)
		frame.category = subCategory
	else
		local category, layout = Settings.RegisterCanvasLayoutCategory(frame, name)
		Settings.RegisterAddOnCategory(category)
		frame.category = category
	end

	-- header in the style of Best Value: a faint gold band with logo, title and a muted subtitle
	local band = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	band:SetPoint("TOPLEFT", 4, -4)
	band:SetPoint("TOPRIGHT", -4, -4)
	band:SetHeight(HEADER_HEIGHT - 4)
	band:SetColorTexture(1, 0.82, 0, 0.06)
	
	local line = frame:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOPLEFT", band, "BOTTOMLEFT")
	line:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")
	line:SetHeight(1)
	line:SetColorTexture(1, 0.82, 0, 0.45)
	
	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(48, 48)
	logo:SetPoint("TOPLEFT", 16, -14)
	logo:Hide()
	frame.logo = logo
	
	local title = frame:CreateFontString(nil, nil, "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", 16, -18)
	title:SetPoint("RIGHT", -16, 0)
	title:SetJustifyH("LEFT")
	title:SetJustifyV("TOP")
	title:SetText(name)
	frame.title = title
	
	local desc = frame:CreateFontString(nil, nil, "GameFontDisableSmall")
	desc:SetHeight(28)
	desc:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
	desc:SetPoint("RIGHT", -16, 0)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetNonSpaceWrap(true)
	frame.desc = desc
	
	return frame
end

local function setLogo(frame, texture)
	frame.logoTexture = texture
	frame.logo:SetTexture(texture)
	frame.logo:SetShown(texture ~= nil)
	frame.title:ClearAllPoints()
	if texture then
		frame.title:SetPoint("TOPLEFT", frame.logo, "TOPRIGHT", 12, -4)
	else
		frame.title:SetPoint("TOPLEFT", 16, -18)
	end
	frame.title:SetPoint("RIGHT", -16, 0)
end

local function constructor(self, name)
	local frame = setmetatable(createFrame(name), parentMT)
	frame.controls = {}
	frame.allcontrols = {}
	return frame
end


function ParentPrototype:AddSubCategory(name, inherit)
	local frame = setmetatable(createFrame(name, self.category), mt)
	if inherit then
		frame.db = self.db
		frame.useProfile = self.useProfile
		frame.handler = self.handler
		frame.allcontrols = self.allcontrols
	else
		frame.allcontrols = {}
	end
	frame.inherit = inherit
	if self.logoTexture then
		setLogo(frame, self.logoTexture)
	end
	frame.controls = {}
	self.subCategories = self.subCategories or {}
	tinsert(self.subCategories, frame)
	return frame
end

-- show a logo in the header of this page and of sub-pages added after this
function Prototype:SetLogo(texture)
	setLogo(self, texture)
end

function Prototype:SetDescription(text)
	self.desc:SetText(text)
end

function Prototype:SetDatabase(database, useProfile)
	self.db = database
	self.useProfile = useProfile
	if self.subCategories then
		for i, v in ipairs(self.subCategories) do
			if v.inherit then
				v.db = database
			end
		end
	end
end

function Prototype:Open()
	Settings.OpenToCategory(self.category:GetID())
end

function Prototype:SetHandler(tbl)
	self.handler = tbl
	if self.subCategories then
		for i, v in ipairs(self.subCategories) do
			if v.inherit then
				v.handler = tbl
			end
		end
	end
end


local function getTable(control)
	local tbl = control.parent.db
	if control.parent.useProfile then
		tbl = tbl.profile
	end
	if control.keyTable then
		tbl = tbl[control.keyTable]
	end
	return tbl
end

local function getFunc(control, method, key, value)
	local func = control[method]
	if func then
		local object = control
		if type(func) == "string" then
			object = control.parent.handler
			func = object[func]
		end
		if key then
			return true, func(object, key, value)
		else
			return true, func(object, value)
		end
		return true
	end
end

local function set(self, value, key)
	if not getFunc(self, "set", key, value) then
		local tbl = getTable(self)
		if tbl then
			tbl[key or self.key] = value
		end
	end
	getFunc(self, "func", key, value)
	for key, control in pairs(self.parent.allcontrols) do
		if control.disabled then
			control:SetEnabled(not control.disabled())
		end
	end
end

local function get(self, key)
	local hasFunc, value = getFunc(self, "get", key)
	if hasFunc then
		return value
	else
		local tbl = getTable(self)
		if tbl then
			return tbl[key or self.key]
		end
	end
end

local controls = Options.controls
local controlData = Options.controlData

-- text width of a control's description in a two column page, and in a single column page
local COLUMN_WIDTH = 270
local FULL_WIDTH = 520

do	-- CheckButton
	controlData.CheckButton = {
		x = -2,
		y = -16,
		bottomOffset = 8,
	}
	
	local function onClick(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		set(self, checked)
	end
	
	controls.CheckButton = function(parent)
		local checkButton = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
		checkButton:SetSize(26, 26)
		checkButton:SetNormalFontObject("GameFontHighlight")
		checkButton:SetDisabledFontObject("GameFontDisable")
		checkButton:SetPushedTextOffset(0, 0)
		checkButton:SetScript("OnClick", onClick)
		checkButton.SetValue = checkButton.SetChecked
		
		checkButton.label = checkButton:CreateFontString()
		checkButton.label:SetPoint("TOPLEFT", checkButton, "TOPRIGHT", 2, -6)
		checkButton:SetFontString(checkButton.label)
		
		-- muted description under the label (filled from the option's tooltip)
		local desc = checkButton:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		desc:SetPoint("TOPLEFT", checkButton.label, "BOTTOMLEFT", 0, -3)
		desc:SetJustifyH("LEFT")
		desc:SetJustifyV("TOP")
		checkButton.desc = desc
		
		local highlight = checkButton:CreateTexture(nil, "BACKGROUND")
		highlight:SetPoint("TOPLEFT", -4, 2)
		highlight:SetPoint("BOTTOMRIGHT", desc, "BOTTOMRIGHT", 4, -4)
		highlight:SetColorTexture(1, 1, 1, 0.05)
		highlight:Hide()
		checkButton:HookScript("OnEnter", function() highlight:Show() end)
		checkButton:HookScript("OnLeave", function() highlight:Hide() end)
		
		local setEnabled = checkButton.SetEnabled
		function checkButton:SetEnabled(enabled)
			setEnabled(self, enabled)
			self.desc:SetAlpha(enabled and 1 or 0.5)
		end
		
		return checkButton
	end
end

do	-- Section: an uppercase gold heading with a thin line, as in Best Value
	controlData.Section = {
		x = 0,
		y = -22,
		bottomOffset = 10,
	}
	
	controls.Section = function(parent)
		local section = CreateFrame("Frame", nil, parent)
		section:SetSize(COLUMN_WIDTH, 14)
		section.label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		section.label:SetPoint("LEFT")
		local line = section:CreateTexture(nil, "ARTWORK")
		line:SetPoint("LEFT", section.label, "RIGHT", 8, 0)
		line:SetPoint("RIGHT")
		line:SetHeight(1)
		line:SetColorTexture(1, 0.82, 0, 0.2)
		section.SetValue = function() end
		section.SetEnabled = function() end
		return section
	end
end

do	-- ColorButton
	controlData.ColorButton = {
		x = 3,
		y = -21,
		bottomOffset = 3,
	}
	
	local ColorPickerFrame = ColorPickerFrame
	
	local function setColor(self, color)
		self.swatch:SetVertexColor(color.r, color.g, color.b)
	end
	
	local function saveColor(self, r, g, b)
		self.swatch:SetVertexColor(r, g, b)
		local color = get(self)
		color.r = r
		color.g = g
		color.b = b
		set(self, color)
	end
	
	local function swatchFunc()
		saveColor(ColorPickerFrame.extraInfo, ColorPickerFrame:GetColorRGB())
	end
	
	local function cancelFunc(prev)
		saveColor(ColorPickerFrame.extraInfo, ColorPicker_GetPreviousValues())
	end
	
	local scripts = {
		OnClick = function(self)
			local info = UIDropDownMenu_CreateInfo()
			local color = get(self)
			info.r, info.g, info.b = color.r, color.g, color.b
			info.swatchFunc = swatchFunc
			info.cancelFunc = cancelFunc
			info.extraInfo = self
			OpenColorPicker(info)
		end,
		
		OnEnter = function(self)
			self.bg:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			if self.tooltipText then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
			end
		end,
		
		OnLeave = function(self)
			self.bg:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			GameTooltip:Hide()
		end,
		
		OnEnable = function(self)
			if self:IsMouseOver() then
				self:OnEnter()
			else
				self.bg:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			end
		end,
		
		OnDisable = function(self)
			self.bg:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		end,
	}
	
	controls.ColorButton = function(parent, data)
		local colorButton = CreateFrame("Button", nil, parent)
		colorButton:SetSize(16, 16)
		colorButton:SetNormalFontObject("GameFontHighlight")
		colorButton:SetDisabledFontObject("GameFontDisable")
		colorButton:SetPushedTextOffset(0, 0)
		for script, handler in pairs(scripts) do
			colorButton:SetScript(script, handler)
			colorButton[script] = handler
		end
		colorButton.SetValue = setColor
		
		colorButton:SetNormalTexture([[Interface\ChatFrame\ChatFrameColorSwatch]])
		colorButton.swatch = colorButton:GetNormalTexture()
		
		colorButton.bg = colorButton:CreateTexture(nil, "BACKGROUND")
		colorButton.bg:SetSize(14, 14)
		colorButton.bg:SetPoint("CENTER")
		colorButton.bg:SetColorTexture(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		
		colorButton.label = colorButton:CreateFontString()
		colorButton.label:SetPoint("LEFT", colorButton, "RIGHT", 5, 1)
		colorButton:SetFontString(colorButton.label)
		
		return colorButton
	end
end

do	-- Slider
	controlData.Slider = {
		x = 7,
		y = -27,
		bottomOffset = -5,
	}
	
	local function onValueChanged(self, value, isUserInput)
		if isUserInput then
			set(self, value)
		end
		if self.isPercent then
			self.currentValue:SetFormattedText("%.0f%%", value * 100)
		else
			self.currentValue:SetText(value)
		end
	end
	
	local function onMinMaxChanged(self, min, max)
		if self.minText or not self.isPercent then
			self.min:SetText(self.minText or min)
		else
			self.min:SetFormattedText("%.0f%%", min * 100)
		end
		if self.maxText or not self.isPercent then
			self.max:SetText(self.maxText or max)
		else
			self.max:SetFormattedText("%.0f%%", max * 100)
		end
	end
	
	controls.Slider = function(parent, data)
		local slider = Libra:CreateSlider(parent)
		slider:SetScript("OnValueChanged", onValueChanged)
		slider:SetScript("OnMinMaxChanged", onMinMaxChanged)
		slider.isPercent = data.isPercent
		slider.minText = data.minText
		slider.maxText = data.maxText
		slider:SetMinMaxValues(data.min, data.max)
		slider:SetValueStep(data.step)
		return slider
	end
end

do	-- Dropdown
	controlData.Dropdown = {
		x = -15,
		y = -32,
		bottomOffset = 8,
	}
	
	local function getValue(dropdown, property, value)
		local properties = dropdown.properties
		local property = properties and properties[property]
		if not properties or not property then
			return value
		else
			if type(property) == "function" then
				return property(value)
			elseif type(property) == "table" then
				return property[value]
			else
				return property
			end
		end
	end
	
	local function setText(self, value)
		self:SetText(getValue(self, "text", value))
	end
	
	local defaultProperties = {
		"text",
		"value",
		"arg1",
	}
	
	local function onClick(self, arg1, arg2, checked)
		if self.owner.multiSelect then
			set(self.owner, checked, arg1)
		else
			self.owner:SetText(self:GetText())
			set(self.owner, arg1)
		end
	end
	
	local function checked(self)
		if self.owner.multiSelect then
			return get(self.owner, self.arg1)
		else
			return self.arg1 == get(self.owner)
		end
	end
	
	local function initialize(self, level, menuList)
		menuList = menuList or self.menulist
		if type(menuList) == "function" then
			menuList = menuList()
		end
		for i, v in ipairs(menuList) do
			local info = UIDropDownMenu_CreateInfo()
			info.func = onClick
			info.checked = checked
			info.isNotRadio = self.multiSelect
			for i, propertyName in ipairs(defaultProperties) do
				info[propertyName] = getValue(self, propertyName, v)
			end
			if self.properties then
				for propertyName in pairs(self.properties) do
					info[propertyName] = getValue(self, propertyName, v)
				end
			end
			self:AddButton(info)
		end
	end
	
	controls.Dropdown = function(parent, data)
		local dropdown = Libra:CreateDropdown("Frame", parent)
		dropdown:JustifyText("LEFT")
		dropdown.SetValue = setText
		dropdown.initialize = data.initialize or initialize
		dropdown.menulist = data.menuList
		dropdown.multiSelect = data.multiSelect
		if data.properties then
			dropdown.properties = {}
			for k, v in pairs(data.properties) do
				dropdown.properties[k] = v
			end
		end
		return dropdown
	end
end

function Libra:AddControlType(type, constructor, controlData)
	if Options.controls[type] then
		error(format("Control type '%s' already exists.", type), 2)
	end
	Options.controls[type] = constructor
	controlData = controlData or {}
	controlData.x = controlData.x or 0
	controlData.y = controlData.y or 0
	controlData.bottomOffset = controlData.bottomOffset or 0
	Options.controlData[type] = controlData
end

function Prototype:CreateOptions(options)
	-- a page can set .columnWidth when something else shares its space
	local width = self.columnWidth or FULL_WIDTH
	for i, option in ipairs(options) do
		if option.newColumn then
			width = COLUMN_WIDTH
		end
	end
	local firstIndex = #self.controls + 1
	for i, option in ipairs(options) do
		local control = controls[option.type](self, option)
		local data = controlData[option.type]
		if i == 1 then
			control:SetPoint("TOPLEFT", self, "TOPLEFT", 16 + data.x, -HEADER_HEIGHT + data.y + 8)
		elseif option.newColumn then
			control:SetPoint("TOPLEFT", self, "TOP", data.x - 2, -HEADER_HEIGHT + data.y + 8)
		else
			local previousOption = options[i - 1]
			local previousData = controlData[previousOption.type]
			local previous = self.controls[firstIndex + i - 2]
			control:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", data.x - previousData.x, data.y + previousData.bottomOffset - (previous.extraHeight or 0) - (option.padding or 0))
		end
		if option.width then
			control:SetWidth(option.width)
		end
		control.parent = self
		if option.type == "Section" then
			control:SetWidth(width + 30)
			control.label:SetText(option.text:upper())
		else
			control.label:SetText(option.text)
		end
		control.tooltipText = option.tooltip
		-- check buttons show their tooltip as a description under the label instead
		if control.desc and option.tooltip then
			control.desc:SetWidth(width)
			control.desc:SetText(option.tooltip)
			local height = control.desc:GetStringHeight()
			if not height or height == 0 then
				height = ceil(#option.tooltip * 5.5 / width) * 11
			end
			control.extraHeight = max(0, height - 2)
			control:SetHitRectInsets(0, -(width + 30), 0, -control.extraHeight)
			control.tooltipText = nil
		end
		control.key = option.key
		control.keyTable = option.keyTable
		control.set = option.set
		control.get = option.get
		control.func = option.func
		control.disabled = option.disabled
		tinsert(self.controls, control)
		tinsert(self.allcontrols, control)
	end
end

function Prototype:SetupControls()
	for i, control in ipairs(self.allcontrols) do
		local value = get(control)
		control:SetValue(value)
		getFunc(control, "func", key, value)
		if control.disabled then
			control:SetEnabled(not control.disabled())
		end
	end
end

function Prototype:GetControlByKey(key, keyTable)
	for i, control in ipairs(self.allcontrols) do
		if control.key == key and control.keyTable == keyTable then
			return control
		end
	end
end

Libra:RegisterModule(Type, Version, constructor)
