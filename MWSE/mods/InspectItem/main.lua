local config = require("InspectItem.config")
local logger = require("InspectItem.logger")
local unit2m = 1.0 / 70.0 -- 1units/70meters

local controllers = {
    require("InspectItem.controller.renderer").new(),
    require("InspectItem.controller.bokeh").new(),
    require("InspectItem.controller.visibility").new(),
    require("InspectItem.controller.guide").new(),
    require("InspectItem.controller.inspector").new(),
}

---@param scanCode tes3.scanCode
---@return string
local function getKeybindName(scanCode)
    return tostring(tes3.findGMST(tes3.gmst.sKeyName_00 + scanCode).value)
end

-- local prefixes = {}
-- if hasShift then table.insert(prefixes, "Shift") end
-- if hasAlt then table.insert(prefixes, "Alt") end
-- if hasCtrl then table.insert(prefixes, "Ctrl") end
-- table.insert(prefixes, comboText)
-- return table.concat(prefixes, " + ")


local function traverseRoots(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

local function removeCollision(sceneNode)
    for node in traverseRoots { sceneNode } do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end

local function removeLight(root)
    for node in traverseRoots { root } do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        --Kill Melchior's Lantern glow effect
        if node.name == "LightEffectSwitch" or node.name == "Glow" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        if node.name == "AttachLight" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end

        -- Kill materialProperty
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)

                -- Kill controllers
                materialProperty:removeAllControllers()

                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0, 0, 0
                materialProperty.emissive = emissive

                node:updateProperties()
            end
        end
        -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
            texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
    end
end

---@class Context
local context = {
    enable = false,
    target = nil, ---@type tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon?
}

-- listener

---@param e itemTileUpdatedEventData
local function OnItemTileUpdated(e)
    e.element:registerAfter(tes3.uiEvent.mouseOver,
        ---@param ev tes3uiEventData
        function(ev)
            context.target = e.item
            logger:trace("enter: %s", context.target.name)
        end)
    e.element:registerAfter(tes3.uiEvent.mouseLeave,
        ---@param ev tes3uiEventData
        function(ev)
            if context.target then
                logger:trace("leave: %s", context.target.name)
                context.target = nil
            end
        end)
end

---@param menuEixt boolean
local function LeaveInspection(menuEixt)
    if context.enable then
        for _, controller in ipairs(controllers) do
            controller:Deactivate({ menuExit = menuEixt })
        end
        context.enable = false
    end
end


local function EnterInspection()
    -- and more condition
    if context.enable then
        return
    end


    if context.target then

        for _, controller in ipairs(controllers) do
            controller:Activate({ target = context.target })
        end
        context.target = nil

        context.enable = true
    end
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
        LeaveInspection(false)
        EnterInspection()
    end
end

---@param e keyUpEventData
local function OnKeyUp(e)
end

---@param e menuExitEventData
local function OnMenuExit(e)
    LeaveInspection(true)
end

---@param e loadEventData
local function OnLoad(e)
    -- if it needs finalization
    --LeaveInspection(true)
end

local function OnInitialized()
    event.register(tes3.event.itemTileUpdated, OnItemTileUpdated)
    event.register(tes3.event.keyDown, OnKeyDown)
    event.register(tes3.event.keyUp, OnKeyUp)
    event.register(tes3.event.menuExit, OnMenuExit)
    event.register(tes3.event.load, OnLoad)

    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu({
            menuId = "MenuInspection",
            buttonId = "Return",
        })
    end
    event.register("MenuInspectionClose", function(e)
        LeaveInspection(false)
    end)

end

event.register(tes3.event.initialized, OnInitialized)

require("InspectItem.mcm")

--- @class tes3scriptVariables
