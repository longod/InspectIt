local base = require("InspectItem.controller.base")

---@class Guide : IController
---@field menu tes3uiElement?
local this = {}
setmetatable(this, { __index = base })

---@type Guide
local defaults = {
    menu = nil,
}

---@return Guide
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Guide

    return instance
end

---@param self Guide
---@param params Activate.Params
function this.Activate(self, params)
    if self.menu then
        self.menu.visible = true
        return
    end
    local menu = tes3ui.createMenu({ id = "MenuInspection", dragFrame = false, fixedFrame = true, modal = true })
    self.menu = menu
    menu:destroyChildren()
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 1
    menu.autoWidth = true
    menu.autoHeight = true
    menu.alpha = 0
    local border = menu:createBlock()
    border.flowDirection = tes3.flowDirection.topToBottom
    --border.widthProportional = 1.0
    border.autoWidth = true
    border.autoHeight = true
    border.childAlignX = 0.5
    border:createLabel({ text = "item name" })
    -- if guided
    border:createLabel({ text = "Mouse Drag: Rotate" })
    border:createLabel({ text = "Mouse Wheel: Zoom" })
    border:createLabel({ text = "C: return to" })
    local button = border:createButton({ id = "Close", text = "Close" })
    button:register(tes3.uiEvent.mouseClick, function (e)
        event.trigger("MenuInspectionClose")
    end)

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
