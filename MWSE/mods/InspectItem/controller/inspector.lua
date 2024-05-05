local base = require("InspectItem.controller.base")

---@class Inspector : IController
---@field node niNode?
---@field enterFrame fun(e : enterFrameEventData)?
local this = {}
setmetatable(this, { __index = base })

---@type Inspector
local defaults = {
    node = nil,
    enterFrame = nil,
}

---@return Inspector
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Inspector

    return instance
end

---@param self Inspector
---@param e enterFrameEventData
function this.OnEnterFrame(self, e)

    if tes3.onMainMenu() then
        return
    end

    if self.node then


        -- tes3ui.captureMouseDrag may be better




        local wc = tes3.worldController
        local ic = wc.inputController

        local q = niQuaternion.new()
        q:fromRotation(self.node.rotation:copy())


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
            self.node.scale = math.clamp(self.node.scale + zoom, 0.01, 10000)
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
            dest:slerpKeyframe(dest, e.delta) -- FIX no delta or original q to dest

            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            self.node.rotation = m:copy()
            -- need moment accumulate input direction
        end

        --inspectingNode:update()
        -- inspectingShadowNode.rotation = inspectingNode.rotation
        --inspectingShadowNode:update()
        --inspectingNode.parent:update()
    end
end

--- @param e activateEventData
local function OnActivate(e)
    -- block picking up items
    e.block = true
end

---@param self Inspector
---@param params Activate.Params
function this.Activate(self, params)
    local target = params.target
    if target then


        local node = target.sceneNode

        local mesh = target.mesh
        node = tes3.loadMesh(mesh, false) -- false if modified?

        if not node then
            self.logger:debug("no node")
            return
        end
        self.logger:debug("node.name: %s", node.name)
        self.logger:debug("node.scale: %f", node.scale)

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


        -- FPV
        local camera = tes3.worldController.armCamera
        --camera = tes3.worldController.worldCamera
        local cameraRoot = camera.cameraRoot
        local cameraData = camera.cameraData
        local fovX = cameraData.fov -- horizontal degree
        self.logger:debug("fov: %f", cameraData.fov) -- or world fov?
        self.logger:debug("near: %f", cameraData.nearPlaneDistance)
        self.logger:debug("far: %f", cameraData.farPlaneDistance)
        self.logger:debug("viewportWidth: %f", cameraData.viewportWidth)
        self.logger:debug("viewportHeight: %f", cameraData.viewportHeight)
        local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth

        local tan = math.tan(math.rad(fovX) * 0.5)
        self.logger:debug("tan: %f", tan)
        local width = tan * offset.y
        local height = width * aspectRatio
        self.logger:debug("width : %f", width)
        self.logger:debug("height : %f", height)
        local screenSize = math.min(width, height)

        local bounds = node:createBoundingBox()
        local size = bounds.max - bounds.min
        self.logger:debug("bounds size: %f, %f, %f", size.x, size.y, size.z)
        local boundsSize = math.max(size.x, size.y, size.z) -- avoid zero

        -- consider distance to near place

        local scale = screenSize / boundsSize
        self.logger:debug("fitting scale: %f", scale)
        node.scale = scale
        node:update()

        cameraRoot:attachChild(node)
        cameraRoot:update()
        cameraRoot:updateEffects()

        self.node = node

        self.enterFrame = function (e)
            self:OnEnterFrame(e)
        end

        event.register(tes3.event.enterFrame, self.enterFrame)
        --tes3ui.suppressTooltip(true)
        event.register(tes3.event.activate, OnActivate)
    end
end

---@param self Inspector
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.node then
        if tes3.worldController and tes3.worldController.armCamera then
            local camera = tes3.worldController.armCamera
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(self.node)
        end

        event.unregister(tes3.event.enterFrame, self.enterFrame)
        event.unregister(tes3.event.activate, OnActivate)
        self.enterFrame = nil

        self.node = nil
    end
end

return this
