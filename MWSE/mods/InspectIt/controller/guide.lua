local base = require("InspectIt.controller.base")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")

local guideMenu = tes3ui.registerID(settings.guideMenu)
local helpLayerMenu = tes3ui.registerID("InspectIt:MenuInspectionDescription")



---@class Guide : IController
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

---@param e enterFrameEventData
local function OnEnterFrame(e)
    local help = tes3ui.findHelpLayerMenu(helpLayerMenu)
    if help then
        if settings.OnOtherMenu() then
            help.visible = false
            return
        end
        if config.display.tooltipsComplete then
            help.visible = true
        end
    end
end

local function Destroy()
    local menu = tes3ui.findMenu(guideMenu)
    if menu then
        menu:destroy()
    end
    local help = tes3ui.findHelpLayerMenu(helpLayerMenu)
    if help then
        help:destroy()
    end
    if event.isRegistered(tes3.event.enterFrame, OnEnterFrame) then
        event.unregister(tes3.event.enterFrame, OnEnterFrame)
    end
end

---@param self Guide
---@param params Activate.Params
function this.Activate(self, params)
    Destroy()

    local width, height = tes3ui.getViewportSize()
    local aspectRatio = width/height
    local offset = 0.02

    -- This modal menu is a must. If there is not a single modal menu visible on the screen, right-clicking will cause all menus to close and return.
    -- This causes unexpected screen transitions and glitches. Especially in Barter.
    local menu = tes3ui.createMenu({ id = guideMenu, dragFrame = false, fixedFrame = true, modal = true })
    menu:destroyChildren()
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.absolutePosAlignX = 1.0 - offset
    menu.absolutePosAlignY = offset * aspectRatio
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
    local nameLabel = border:createLabel({ text = params.target.name })
    nameLabel.borderAllSides = 4
    nameLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

    -- if guided
    do
        local block = border:createBlock()
        if not config.display.instruction then
            block.visible = false
        end
        block.flowDirection = tes3.flowDirection.topToBottom
        block.widthProportional = 1.0
        block.autoWidth = true
        block.autoHeight = true
        block.childAlignX = 0.5
        block:createDivider().widthProportional = 1.0
        block:createLabel({ text = settings.i18n("guide.rotate.text") }).borderAllSides = 2
        block:createLabel({ text = settings.i18n("guide.zoom.text") }).borderAllSides = 2

        -- another/activate
        if params.another.type ~= nil then
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
            row:createLabel({ text = ": " .. GetComboString(config.input.another) })
            row.visible = params.another.type ~= nil
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
            row:createLabel({ text = ": " .. GetComboString(config.input.reset) })
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
            row:createLabel({ text = ": " .. GetComboString(config.input.inspect) })
        end
    end

    menu:updateLayout()

    -- on mouse fade? help layer does not trigger over, leave event
    if config.display.tooltipsComplete and params.description then
        local help = tes3ui.createHelpLayerMenu({ id = helpLayerMenu })
        help:destroyChildren()
        help.flowDirection = tes3.flowDirection.topToBottom
        help.absolutePosAlignX = offset
        help.absolutePosAlignY = 0.5
        help.autoWidth = true
        help.autoHeight = true
        help.minWidth = 0
        help.minHeight = 0
        help.alpha = 0.2
        local block = help:createBlock()
        block.flowDirection = tes3.flowDirection.topToBottom
        block.widthProportional = 1.0
        block.minWidth = 0
        block.maxWidth = 300
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 8
        --block.childAlignX = 0.5
        block:createLabel({ text = params.description }).alpha = 0.9 -- .borderAllSides = 2
        help:updateLayout()

        event.register(tes3.event.enterFrame, OnEnterFrame)
    end
end

---@param self Guide
---@param params Deactivate.Params
function this.Deactivate(self, params)
    Destroy()
end

---@param self Guide
function this.Reset(self)
    Destroy()
end

return this
