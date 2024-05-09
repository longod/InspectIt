local base = require("InspectItem.controller.base")
local config = require("InspectItem.config")

---@class Guide : IController
---@field menu tes3uiElement?
---@field instruction tes3uiElement?
---@field nameLabel tes3uiElement?
---@field returnKeybindLabel tes3uiElement?
---@field anotherLook tes3uiElement?
---@field anotherLookKeybindLabel tes3uiElement?
---@field resetPoseKeybindLabel tes3uiElement?
local this = {}
setmetatable(this, { __index = base })

---@type Guide
local defaults = {
}

---@return Guide
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Guide

    return instance
end

--- @param keyCode integer|nil
--- @return string|nil letter
local function GetLetter(keyCode)
    local letter = table.find(tes3.scanCode, keyCode)
    local returnString = tes3.scanCodeToNumber[keyCode] or letter
    if returnString then
        return string.upper(returnString)
    end
end

--- @param keyCombo mwseKeyCombo
--- @return string result
local function GetComboString(keyCombo)
    local keyCode = keyCombo.keyCode
    local comboText = GetLetter(keyCode)
    if not comboText then
        comboText = string.format("{%s}", mwse.mcm.i18n("unknown key"))
    end
    local hasAlt = (keyCombo.isAltDown and keyCode ~= tes3.scanCode.lAlt
        and keyCode ~= tes3.scanCode.rAlt)
    local hasShift = (keyCombo.isShiftDown and keyCode ~= tes3.scanCode.lShift
        and keyCode ~= tes3.scanCode.rShift)
    local hasCtrl = (keyCombo.isControlDown and keyCode ~= tes3.scanCode.lCtrl
        and keyCode ~= tes3.scanCode.rCtrl)
    local prefixes = {}
    if hasShift then table.insert(prefixes, "Shift") end
    if hasAlt then table.insert(prefixes, "Alt") end
    if hasCtrl then table.insert(prefixes, "Ctrl") end
    table.insert(prefixes, comboText)
    return table.concat(prefixes, " + ")
end

---@param self Guide
---@param params Activate.Params
function this.Activate(self, params)
    if self.menu then
        self.menu.visible = true
        self.instruction.visible = config.display.instruction
        self.nameLabel.text = params.target.name
        self.returnKeybindLabel.text = ": " .. GetComboString(config.input.inspect)
        self.anotherLook.visible = params.another.type ~= nil
        self.anotherLookKeybindLabel.text = ": " .. GetComboString(config.input.another)
        self.resetPoseKeybindLabel.text = ": " .. GetComboString(config.input.reset)
        self.menu:updateLayout()
        return
    end
    local settings = require("InspectItem.settings")

    -- This modal menu is a must. If there is not a single modal menu visible on the screen, right-clicking will cause all menus to close and return.
    -- This causes unexpected screen transitions and glitches. Especially in Barter.
    local menu = tes3ui.createMenu({ id = settings.menuName, dragFrame = false, fixedFrame = true, modal = true })
    self.menu = menu
    menu:destroyChildren()
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.absolutePosAlignX = 0.98
    menu.absolutePosAlignY = 0.02
    menu.autoWidth = true
    menu.autoHeight = true
    menu.minWidth = 0 -- or tooltip size?
    menu.minHeight = 0
    --menu.alpha = 0
    local border = menu:createThinBorder()
    border.flowDirection = tes3.flowDirection.topToBottom
    border.autoWidth = true
    border.autoHeight = true
    border.paddingAllSides = 8
    border.childAlignX = 0.5
    self.nameLabel = border:createLabel({ text = params.target.name })
    self.nameLabel.borderAllSides = 4
    self.nameLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

    -- if guided
    local block = border:createBlock()
    self.instruction = block
    block.flowDirection = tes3.flowDirection.topToBottom
    block.widthProportional = 1.0
    block.autoWidth = true
    block.autoHeight = true
    block.childAlignX = 0.5
    block:createDivider().widthProportional = 1.0
    block:createLabel({ text = settings.i18n("guide.rotate.text") }).borderAllSides = 2
    block:createLabel({ text = settings.i18n("guide.zoom.text") }).borderAllSides = 2

    -- another/activate
    do
        local row = block:createBlock()
        row.flowDirection = tes3.flowDirection.leftToRight
        row.autoWidth = true
        row.autoHeight = true
        row.childAlignY = 0.5
        row.paddingAllSides = 2
        local button = row:createButton({ text = settings.i18n("guide.another.text") })
        button:register(tes3.uiEvent.mouseClick, function(e)
            event.trigger(settings.switchAnotherLookEventName)

        end)
        self.anotherLookKeybindLabel = row:createLabel({ text = ": " .. GetComboString(config.input.another) })
        self.anotherLook = row
        self.anotherLook.visible = params.another.type ~= nil
    end

    -- reset
    do
        local row = block:createBlock()
        row.flowDirection = tes3.flowDirection.leftToRight
        row.autoWidth = true
        row.autoHeight = true
        row.childAlignY = 0.5
        row.paddingAllSides = 2
        local button = row:createButton({ text = settings.i18n("guide.reset.text") })
        button:register(tes3.uiEvent.mouseClick, function(e)
            event.trigger(settings.resetPoseEventName)
        end)
        self.resetPoseKeybindLabel = row:createLabel({ text = ": " .. GetComboString(config.input.reset) })
    end

    -- return
    do
        local row = block:createBlock()
        row.flowDirection = tes3.flowDirection.leftToRight
        row.autoWidth = true
        row.autoHeight = true
        row.childAlignY = 0.5
        row.paddingAllSides = 2
        local button = row:createButton({ id = settings.returnButtonName, text = settings.i18n("guide.return.text") })
        button:register(tes3.uiEvent.mouseClick, function(e)
            event.trigger(settings.returnEventName)
        end)
        self.returnKeybindLabel = row:createLabel({ text = ": " .. GetComboString(config.input.inspect) })
    end
    if not config.display.instruction then
        self.instruction.visible = false
    end

    menu:updateLayout()
end

---@param self Guide
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.menu then
        self.menu.visible = false
    end
end

---@param self Guide
function this.Reset(self)
    if self.menu then
        self.menu:destroy()
        self.menu = nil
    end
    self.instruction = nil
    self.nameLabel = nil
    self.returnKeybindLabel = nil
    self.anotherLook = nil
    self.anotherLookKeybindLabel = nil
    self.resetPoseKeybindLabel = nil
end

return this
