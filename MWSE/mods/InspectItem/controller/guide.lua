local base = require("InspectItem.controller.base")
local config = require("InspectItem.config")

---@class Guide : IController
---@field menu tes3uiElement?
---@field nameLabel tes3uiElement?
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
    return table.concat(prefixes, " - ")
end

---@param self Guide
---@param params Activate.Params
function this.Activate(self, params)
    if self.menu then
        self.menu.visible = true
        self.nameLabel.text = params.target.name
        return
    end

    -- This modal menu is a must. If there is not a single modal menu visible on the screen, right-clicking will cause all menus to close and return.
    -- This causes unexpected screen transitions and glitches. Especially in Barter.
    local menu = tes3ui.createMenu({ id = "MenuInspection", dragFrame = false, fixedFrame = true, modal = true })
    self.menu = menu
    menu:destroyChildren()
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.98
    menu.autoWidth = true
    menu.autoHeight = true
    --menu.alpha = 0
    local border = menu:createThinBorder()
    border.flowDirection = tes3.flowDirection.topToBottom
    border.autoWidth = true
    border.autoHeight = true
    border.paddingAllSides = 4
    border.childAlignX = 0.5
    self.nameLabel = border:createLabel({ text = params.target.name })
    self.nameLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

    -- if guided
    local block = border:createBlock()
    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoWidth = true
    block.autoHeight = true
    block.childAlignX = 0.5
    block:createDivider().widthProportional = 1.0
    block:createLabel({ text = "Rotate: Mouse drag" })
    block:createLabel({ text = "Zoom: Mouse wheel" })
    -- reset
    local row = block:createBlock()
    row.flowDirection = tes3.flowDirection.leftToRight
    row.autoWidth = true
    row.autoHeight = true
    row.childAlignY = 0.5
    row.paddingTop = 2
    local button = row:createButton({ id = "Return", text = "Return" })
    button:register(tes3.uiEvent.mouseClick, function(e)
        event.trigger("MenuInspectionClose")
    end)
    row:createLabel({ text = ": " .. GetComboString(config.input.keybind) })

    menu:updateLayout()
end

---@param self Guide
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.menu then
        self.menu.visible = false
    end
end

return this
