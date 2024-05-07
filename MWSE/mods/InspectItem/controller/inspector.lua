local base = require("InspectItem.controller.base")
local config = require("InspectItem.config").input
local zoomThreshold = 0  -- delta
local zoomDuration = 0.4 -- second
local angleThreshold = 2 -- pixel
local velocityEpsilon = 0.000001
local friction = 0.1     -- Attenuation with respect to velocity
local resistance = 3.0   -- Attenuation with respect to time

---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@return tes3vector3?
local function GetOrientation(object)
    local orientations = {
        -- [tes3.objectType.activator] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.alchemy] = tes3vector3.new(0, 0, 0), -- fixed
        [tes3.objectType.ammunition] = tes3vector3.new(0, 0, -90),
        [tes3.objectType.apparatus] = tes3vector3.new(0, 0, 0), -- fixed
        -- [tes3.objectType.armor] = tes3vector3.new(-90, 0, 0), -- It's not aligned. It's a mess.
        -- [tes3.objectType.birthsign] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.bodyPart] = tes3vector3.new(0, 0, 0), -- fixed?
        [tes3.objectType.book] = tes3vector3.new(-90, 0, 0),
        -- [tes3.objectType.cell] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.class] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.clothing] = tes3vector3.new(-90, 0, 0), -- need angled
        -- [tes3.objectType.container] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.creature] = tes3vector3.new(0, 0, 0), -- fixed
        -- [tes3.objectType.dialogue] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.dialogueInfo] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.door] = tes3vector3.new(0, 0, -90),
        -- [tes3.objectType.enchantment] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.faction] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.gmst] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.ingredient] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.land] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.landTexture] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.leveledCreature] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.leveledItem] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.light] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.lockpick] = tes3vector3.new(-90, 0, 0),
        -- [tes3.objectType.magicEffect] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.miscItem] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobileActor] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobileCreature] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobileNPC] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobilePlayer] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobileProjectile] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.mobileSpellProjectile] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.npc] = tes3vector3.new(0, 0, 0), -- fixed
        -- [tes3.objectType.pathGrid] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.probe] = tes3vector3.new(-90, 0, 0),
        -- [tes3.objectType.quest] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.race] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.reference] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.region] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.repairItem] = tes3vector3.new(-90, 0, 0),
        -- [tes3.objectType.script] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.skill] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.sound] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.soundGenerator] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.spell] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.startScript] = tes3vector3.new(0, 0, 0),
        -- [tes3.objectType.static] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.weapon] = tes3vector3.new(-90, 0, 0),
    }

    if object.objectType == tes3.objectType.armor then
        ---@cast object tes3armor
        -- object.slot
    elseif object.objectType == tes3.objectType.clothing then
        ---@cast object tes3clothing
        -- object.slot
    elseif object.objectType == tes3.objectType.bodyPart then
        ---@cast object tes3bodyPart
        -- object.part
        -- object.partType
    end
    return orientations[object.objectType]
end

---@class Inspector : IController
---@field node niNode?
---@field offset niNode? pivot
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
    offset = nil,
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

---@param ratio number
---@param estart number
---@param eend number
---@return number
local function Ease(ratio, estart, eend)
    local t = EaseOutCubic(ratio)
    local v = math.lerp(estart, eend, t)
    return v
end

-- local updateTime = 0

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

        local zoom = ic.mouseState.z
        if math.abs(zoom) > zoomThreshold then
            zoom = zoom * 0.001 * config.sensitivityZ * (config.inversionZ and -1 or 1)
            self.logger:trace("wheel %f", ic.mouseState.z)
            self.logger:trace("wheel velocity %f", zoom)
            -- update current zooming
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self.zoomStart = scale
            self.zoomEnd = math.clamp(self.zoomEnd + zoom, 0.5, 2)
            self.zoomTime = 0
        end

        if self.zoomTime < zoomDuration then
            self.zoomTime = math.min(self.zoomTime + e.delta, zoomDuration)
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self.node.scale = self.baseScale * scale
            self.logger:trace("zoom %f", scale)
        end

        if ic:isMouseButtonDown(0) then
            self.logger:trace("mouse %f, %f, %f", ic.mouseState.x, ic.mouseState.y, ic.mouseState.z)
            local zAngle = ic.mouseState.x
            local xAngle = ic.mouseState.y

            if math.abs(zAngle) <= angleThreshold then
                zAngle = 0
            end
            if math.abs(xAngle) <= angleThreshold then
                xAngle = 0
            end
            zAngle = zAngle * wc.mouseSensitivityX * config.sensitivityX * (config.inversionX and -1 or 1)
            xAngle = xAngle * wc.mouseSensitivityY * config.sensitivityY * (config.inversionY and -1 or 1)
            self.logger:trace("drag velocity %f, %f", zAngle, xAngle)

            self.angularVelocity.z = zAngle
            self.angularVelocity.x = xAngle
        end

        if self.angularVelocity:dot(self.angularVelocity) > velocityEpsilon then
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

            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * friction,
                math.clamp(e.delta * resistance, 0, 1))
        end
        local euler = self.node.rotation:toEulerXYZ():copy()
        tes3.messageBox(string.format("%f, %f, %f", math.deg(euler.x), math.deg(euler.y), math.deg(euler.z)))

        -- updateTime = updateTime  + e.delta
        -- self.node:update({ controllers = true, time = updateTime })
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
    if not target then
        return
    end

    if target then
        self.angularVelocity = tes3vector3.new(0, 0, 0)



        local node = target.sceneNode

        local mesh = target.mesh
        node = tes3.loadMesh(mesh, false) --:clone() -- false if modified?

        if tes3.player then
            -- hmm...?
            -- local part = tes3.player.bodyPartManager:getActiveBodyPartForItem(target)
            -- if part and part.node then
            --     node = part.node
            --     --node = tes3.loadMesh(part.bodyPart.mesh, false)
            -- end
        end

        if not node then
            self.logger:debug("no node")
            return
        end
        self.logger:debug("node.name: %s", node.name)
        self.logger:debug("node.scale: %f", node.scale)

        local asset = node

        local parent = niNode.new()
        self.offset = niNode.new()
        self.offset:attachChild(node)
        parent:attachChild(self.offset)
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
        local fovX = cameraData.fov                  -- horizontal degree
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

        -- same? i think. unscaled size
        -- not load yet
        local offset = (bounds.max + bounds.min) * -0.5
        self.logger:debug(tostring(bounds.max))
        self.logger:debug(tostring(bounds.min))
        self.logger:debug(tostring(offset))
        self.offset.translation = offset

        local size = bounds.max - bounds.min
        self.logger:debug("bounds size: %f, %f, %f", size.x, size.y, size.z)
        local boundsSize = math.max(size.x, size.y, size.z) -- avoid zero

        -- diagonal
        -- boundsSize = size:length() -- 3d or dominant 2d
        -- screenSize = math.sqrt(width * width + height * height)

        -- dominant face and axis
        local my = 0
        if size.x < size.y and size.z < size.y then
            my = 1
        end
        local mz = 0
        if size.x < size.z and size.y < size.z then
            mz = 2
        end
        local imax = my + mz;
        self.logger:debug("axis %d", imax)

        -- TODO target.objectType
        -- tes3vector3() radian

        -- almost item y-up


        local findKey = function(o)
            for key, value in pairs(tes3.objectType) do
                if o == value then
                    return key
                end
            end
            return ""
        end
        self.logger:info("objectType: %s", findKey(target.objectType))
        local orientation = GetOrientation(target)
        if orientation then
            local rot = tes3matrix33.new()
            rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
            node.rotation = node.rotation * rot:copy()
        else
            -- auto fitting
        end

        -- consider distance to near place

        local scale = screenSize / boundsSize
        self.logger:info("fitting scale: %f", scale)
        node.scale = scale


        for n in traverseRoots(node.children) do
            --Kill particles
            --n:isInstanceOfType(ni.type.NiParticles)
            if n:isInstanceOfType(ni.type.NiParticles) then
                --self.logger:debug("particle")
                --n.parent:detachChild(n)
                --n.scale = n.scale / scale
                ---@cast n niParticles
                --self.logger:debug(tostring(n.controller.active))
                -- n.controller.animTimingType=1
                -- n.controller:start(1)
            end
        end

        node:updateEffects()
        node:update()

        self.baseScale = scale
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration

        cameraRoot:attachChild(node)
        cameraRoot:update()
        cameraRoot:updateEffects()

        self.node = node

        self.enterFrame = function(e)
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

        self.offset = nil
        self.node = nil
    end
end

---@param self Inspector
function this.Reset(self)
    self.offset = nil
    self.node = nil
end

return this
