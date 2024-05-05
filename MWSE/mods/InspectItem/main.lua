local config = require("InspectItem.config")
local logger = require("InspectItem.logger")

local controllers = {
    require("InspectItem.controller.renderer").new(),
    require("InspectItem.controller.bokeh").new(),
    require("InspectItem.controller.visibility").new(),
    require("InspectItem.controller.guide").new(),
    require("InspectItem.controller.inspector").new(),
}

--- listener
---@class Context
local context = {
    enable = false,
    target = nil, ---@type tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon?
}

---@param e itemTileUpdatedEventData
local function OnItemTileUpdated(e)
    e.element:registerAfter(tes3.uiEvent.mouseOver,
        ---@param ev tes3uiEventData
        function(ev)
            context.target = e.item
        end)
    e.element:registerAfter(tes3.uiEvent.mouseLeave,
        ---@param ev tes3uiEventData
        function(ev)
            if context.target then
                context.target = nil
            end
        end)
end

---@param menuEixt boolean
local function LeaveInspection(menuEixt)
    if context.enable then
        logger:info("Leave Inspection")
        for _, controller in ipairs(controllers) do
            controller:Deactivate({ menuExit = menuEixt })
        end
        context.enable = false
    end
end


local function EnterInspection()
    -- and more condition
    if context.enable or not context.target then
        return
    end
    logger:info("Enter Inspection: %s", context.target.name)

    for _, controller in ipairs(controllers) do
        controller:Activate({ target = context.target, offset = 10 })
    end
    context.target = nil
    context.enable = true
end

---@param e keyDownEventData
---@param key mwseKeyCombo
---@return boolean
local function TestInput(e, key)
    if key.keyCode ~= e.keyCode then
        return false
    end
    if key.isAltDown and not e.isAltDown then
        return false
    end
    if key.isControlDown and not e.isControlDown then
        return false
    end
    if key.isShiftDown and not e.isShiftDown then
        return false
    end
    return true
end

---@param e keyDownEventData
local function OnKeyDown(e)
    if tes3.onMainMenu() then
        return
    end
    if TestInput(e, config.input.keybind) then
        -- test tagreting
        -- first time, visible menu mult, why?
        if not tes3.menuMode() and not context.enable and not context.target then
            local ref = tes3.getPlayerTarget()
            if ref and ref.object then -- and more conditions
                -- context.target = ref.object
                -- tes3ui.enterMenuMode("MenuInspection")
            end
        end

        LeaveInspection(false)
        EnterInspection()
        if context.enable then
            --e.claim = true
        end
    end
end


---@param e menuExitEventData
local function OnMenuExit(e)
    -- fail-safe
    --LeaveInspection(true)
    if context.enable then
        logger:error("Not terminated")
    end
end

---@param e loadEventData
local function OnLoad(e)
    LeaveInspection(true)
    -- or deallocate
    for _, controller in ipairs(controllers) do
        controller:Reset()
    end
    context.target = nil
end

local function OnInitialized()
    event.register(tes3.event.itemTileUpdated, OnItemTileUpdated)
    event.register(tes3.event.keyDown, OnKeyDown, { priority = 0 })
    event.register(tes3.event.menuExit, OnMenuExit)
    event.register(tes3.event.load, OnLoad)

    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        local settings = require("InspectItem.settings")
        RightClickMenuExit.registerMenu({
            menuId = settings.menuName,
            buttonId = settings.returnButtonName,
        })
    end
    event.register("MenuInspectionClose", function(e)
        LeaveInspection(false)
    end)
end

event.register(tes3.event.initialized, OnInitialized)

require("InspectItem.mcm")

--- @class tes3scriptVariables
