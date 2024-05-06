local base = require("InspectItem.controller.base")
local zoomDuration = 0.4

---@class Inspector : IController
---@field node niNode?
---@field enterFrame fun(e : enterFrameEventData)?
---@field angularVelocity tes3vector3 -- vec2 doesnt have dot
---@field baseScale number
---@field zoomStart number
---@field zoomEnd number
---@field zoomTime number
local this = {}
setmetatable(this, { __index = base })

---@type Inspector
local defaults = {
    node = nil,
    enterFrame = nil,
    angularVelocity = tes3vector3.new(0, 0, 0),
    baseScale = 1,
    zoomStart = 1,
    zoomEnd = 1,
    zoomTime = 0,
}

---@return Inspector
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Inspector

    return instance
end

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

---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuad(t)
    local ix = 1.0 - t
    return 1.0 - ix * ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutCubic(t)
    local ix = 1.0 - t
    ix = ix * ix * ix
    return 1.0 - ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuart(t)
    local ix = 1.0 - t
    ix = ix * ix
    ix = ix * ix
    return 1.0 - ix
end

---@param self Inspector
---@param e enterFrameEventData
function this.OnEnterFrame(self, e)

    if tes3.onMainMenu() then
        return
    end

    if self.node then
        -- tes3ui.captureMouseDrag may be better?

        local wc = tes3.worldController
        local ic = wc.inputController

        local zoom = ic.mouseState.z * 0.001

        if zoom ~= 0 then
            local ratio = self.zoomTime / zoomDuration
            local t = EaseOutCubic(ratio)
            local scale = math.lerp(self.zoomStart ,self.zoomEnd, t)
            self.zoomStart = scale

            self.zoomEnd = math.clamp(self.zoomEnd + zoom, 0.5, 2)

            self.zoomTime = 0
        end

        if self.zoomTime < zoomDuration then
            self.zoomTime = math.min(self.zoomTime  + e.delta, zoomDuration)
            local ratio = self.zoomTime / zoomDuration
            local t = EaseOutCubic(ratio)
            local scale = math.lerp(self.zoomStart ,self.zoomEnd, t)
            self.node.scale = self.baseScale * scale
        end

        if ic:isMouseButtonDown(0) then
            self.logger:trace("mouse %f, %f, %f", ic.mouseState.x, ic.mouseState.y, ic.mouseState.z)
            local zAngle = ic.mouseState.x
            local xAngle = ic.mouseState.y
            local threshold = 2
            if math.abs(zAngle) <= threshold then
                zAngle = 0
            end
            if math.abs(xAngle) <= threshold then
                xAngle = 0
            end
            zAngle = zAngle * wc.mouseSensitivityX
            xAngle = xAngle * wc.mouseSensitivityY
            self.logger:trace("velocity %f, %f", zAngle, xAngle)

            self.angularVelocity.z = zAngle
            self.angularVelocity.x = xAngle
        end

        local epsilon = 0.000001
        if self.angularVelocity:dot(self.angularVelocity) > epsilon then
            local zAxis = tes3vector3.new(0, 0, 1) -- Y
            local xAxis = tes3vector3.new(1, 0, 0)

            local zRot = niQuaternion.new()
            local xRot = niQuaternion.new()

            zRot:fromAngleAxis(self.angularVelocity.z, zAxis)
            xRot:fromAngleAxis(self.angularVelocity.x, xAxis)

            local q = niQuaternion.new()
            q:fromRotation(self.node.rotation:copy())

            local dest = zRot * xRot * q
            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            self.node.rotation = m:copy()

            local friction = 0.0001
            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * friction, e.delta)
        end

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
        self.angularVelocity = tes3vector3.new(0,0,0)

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
        local offset = tes3vector3.new(0, params.offset, 0)
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
        self.baseScale = scale
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration

        cameraRoot:attachChild(node)
        cameraRoot:update()
        cameraRoot:updateEffects()

        self.node = node

        self.enterFrame = function (e)
            self:OnEnterFrame(e)
        end
        event.register(tes3.event.enterFrame, self.enterFrame)
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

---@param self Inspector
function this.Reset(self)
    self.node = nil
end

return this
