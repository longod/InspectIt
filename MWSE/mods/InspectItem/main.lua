local config = require("InspectItem.config")
local logger = require("InspectItem.logger")
local unit2m = 1.0 / 70.0 -- 1units/70meters


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

local context = {
    node = nil, ---@type niNode?
    item = nil, ---@type tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon?
    pauseRenderingInMenus = mge.render.pauseRenderingInMenus,
    shader = nil,
}

local item = nil ---@type tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon?
local inspectingNode = nil ---@type niNode?

---@param e itemTileUpdatedEventData
local function OnItemTileUpdated(e)
    e.element:registerAfter(tes3.uiEvent.mouseOver,
        ---@param ev tes3uiEventData
        function(ev)
            item = e.item
            logger:trace("enter: %s", item.name)
        end)
    e.element:registerAfter(tes3.uiEvent.mouseLeave,
        ---@param ev tes3uiEventData
        function(ev)
            if item then
                logger:trace("leave: %s", item.name)
                item = nil
            end
        end)
end

--- @param e enterFrameEventData
local function OnEnterFrame(e)
    mge.render.pauseRenderingInMenus = context.pauseRenderingInMenus
    if inspectingNode then

        mge.render.pauseRenderingInMenus = false


        local wc = tes3.worldController
        local ic = wc.inputController

        local q = niQuaternion.new()
        q:fromRotation(inspectingNode.rotation:copy())


        -- local r = niQuaternion.new()
        -- r:fromAngleAxis(0.01, tes3vector3.new(0,0,1) )
        -- q = q * r
        -- local m = tes3matrix33.new()
        -- m:fromQuaternion(q)
        -- inspectingNode.rotation = m:copy()

        -- avoid reference?

        local zAngle = ic.mouseState.x * wc.mouseSensitivityX
        local xAngle = ic.mouseState.y * wc.mouseSensitivityY
        local zoom = ic.mouseState.z * 0.001

        if zoom ~= 0 then
            -- use rate or translation
            inspectingNode.scale = math.clamp(inspectingNode.scale + zoom, 0.01, 10000)
        end

        if ic:isMouseButtonDown(0) then

            local zAxis = tes3vector3.new(0, 0, 1) -- Y
            local xAxis = tes3vector3.new(1, 0, 0)

            local zRot = niQuaternion.new()
            local xRot = niQuaternion.new()

            zRot:fromAngleAxis(zAngle, zAxis)
            xRot:fromAngleAxis(xAngle, xAxis)

            --local dest = zRot * q * xRot
            local dest = zRot * xRot * q
            dest:slerpKeyframe(dest, e.delta)

            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            inspectingNode.rotation = m:copy()
            -- need moment accumulate input direction
        end

        --inspectingNode:update()
        -- inspectingShadowNode.rotation = inspectingNode.rotation
        --inspectingShadowNode:update()
        --inspectingNode.parent:update()
    end
end

local function LeaveInspection()
    if inspectingNode then
        if tes3.worldController and tes3.worldController.armCamera then
            local camera = tes3.worldController.armCamera
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(inspectingNode)
        end
        inspectingNode = nil

        if context.shader then
            context.shader.enabled = false
        end

        mge.render.pauseRenderingInMenus = context.pauseRenderingInMenus
        event.unregister(tes3.event.enterFrame, OnEnterFrame)
    end
end

local function EnterInspection()
    if inspectingNode then
        return
    end
    if not context.shader then
        context.shader = mge.shaders.load({ name = "InspectItem/Depth of Field" })
        if context.shader then
            context.shader.enabled = false
        end
    end


    if item then
        if context.shader then
            context.shader.enabled = true
        end

        logger:info("inspect: %s", item.name)
        logger:debug("mesh: %s", item.mesh)

        local node = item.sceneNode

        local mesh = item.mesh
        node = tes3.loadMesh(mesh, false) -- false if modified?

        if not node then
            logger:debug("no node")
            return
        end
        logger:debug("node.name: %s", node.name)
        logger:debug("node.scale: %f", node.scale)

        local parent = niNode.new()
        parent:attachChild(node)
        node = parent

        do --add properties
            ---@diagnostic disable-next-line: undefined-field
            local vertexColorProperty = niVertexColorProperty.new()
            vertexColorProperty.name = "vcol yo"
            vertexColorProperty.source = 2
            --node:attachProperty(vertexColorProperty)

            ---@diagnostic disable-next-line: undefined-global
            local zBufferProperty = niZBufferProperty.new()
            zBufferProperty.name = "zbuf yo"
            -- depth test, depth write?
            zBufferProperty:setFlag(true, 0)
            zBufferProperty:setFlag(true, 1)
            node:attachProperty(zBufferProperty)
        end

        -- it seems to useful dummy camera space node
        -- not cloned data
        local pos = node.translation
        local offset = tes3vector3.new(0, 10, 0)
        node.translation = pos + offset

        node.appCulled = false
        node:update()
        node:updateEffects()

        -- store original value
        context.pauseRenderingInMenus = mge.render.pauseRenderingInMenus

        -- FPV
        local camera = tes3.worldController.armCamera
        --camera = tes3.worldController.worldCamera
        local cameraRoot = camera.cameraRoot
        local cameraData = camera.cameraData
        local fovX = cameraData.fov -- horizontal degree
        logger:debug("fov: %f", cameraData.fov) -- or world fov?
        logger:debug("near: %f", cameraData.nearPlaneDistance)
        logger:debug("far: %f", cameraData.farPlaneDistance)
        logger:debug("viewportWidth: %f", cameraData.viewportWidth)
        logger:debug("viewportHeight: %f", cameraData.viewportHeight)
        local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth

        local tan = math.tan(math.rad(fovX) * 0.5)
        logger:debug("tan: %f", tan)
        local width = tan * offset.y
        local height = width * aspectRatio
        logger:debug("width : %f", width)
        logger:debug("height : %f", height)
        local screenSize = math.min(width, height)

        local bounds = node:createBoundingBox()
        local size = bounds.max - bounds.min
        logger:debug("bounds size: %f, %f, %f", size.x, size.y, size.z)
        local boundsSize = math.max(size.x, size.y, size.z) -- avoid zero

        -- consider distance to near place

        local scale = screenSize / boundsSize
        logger:debug("fitting scale: %f", scale)
        node.scale = scale
        node:update()

        cameraRoot:attachChild(node)
        cameraRoot:update()
        cameraRoot:updateEffects()

        inspectingNode = node

        -- camera = tes3.worldController.shadowCamera
        -- cameraRoot = camera.cameraRoot
        -- node = niNode.new()
        -- inspectingShadowNode = node

        -- cameraRoot:attachChild(node)
        -- cameraRoot:update()
        -- cameraRoot:updateEffects()

        event.register(tes3.event.enterFrame, OnEnterFrame)

    end
end

---@param e keyDownEventData
---@param key KeybindingData
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

local shown = false

---@param e keyDownEventData
local function OnKeyDown(e)
    if e.keyCode == tes3.scanCode.x then
        shown = not shown
       -- local menuMode = tes3.menuMode()
        if shown then
            tes3ui.leaveMenuMode()
            timer.delayOneFrame(function(_)
                tes3ui.enterMenuMode("InspectItem")
            end)
        else
            tes3ui.leaveMenuMode()
        end
    end
    if TestInput(e, config.input.keybind) then
        LeaveInspection()
        EnterInspection()
    end
end

---@param e keyUpEventData
local function OnKeyUp(e)
end

--- @param e menuExitEventData
local function OnMenuExit(e)
    LeaveInspection()
    item = nil
end

---@param e loadEventData
local function OnLoad(e)
    -- reset state
    LeaveInspection()
    item = nil
end

local function OnInitialized()
    event.register(tes3.event.itemTileUpdated, OnItemTileUpdated)
    event.register(tes3.event.keyDown, OnKeyDown) -- can filter
    event.register(tes3.event.keyUp, OnKeyUp)
    event.register(tes3.event.menuExit, OnMenuExit)
    event.register(tes3.event.load, OnLoad)
end

event.register(tes3.event.initialized, OnInitialized)

require("InspectItem.mcm")

--- @class tes3scriptVariables
