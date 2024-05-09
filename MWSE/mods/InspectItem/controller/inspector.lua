local base = require("InspectItem.controller.base")
local config = require("InspectItem.config").input
local settings = require("InspectItem.settings")
local zoomThreshold = 0  -- delta
local zoomDuration = 0.4 -- second
local angleThreshold = 0 -- pixel
local velocityEpsilon = 0.000001
local friction = 0.1     -- Attenuation with respect to velocity
local resistance = 3.0   -- Attenuation with respect to time

---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@return tes3vector3?
local function GetOrientation(object)
    local orientations = {
        -- [tes3.objectType.activator] = tes3vector3.new(0, 0, 0),
        [tes3.objectType.alchemy] = tes3vector3.new(0, 0, 0),   -- fixed
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
        [tes3.objectType.creature] = tes3vector3.new(0, 0, 0),   -- fixed
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

    -- TODO weapon, throwing

    if object.objectType == tes3.objectType.armor then
        ---@cast object tes3armor
        -- object.slot
        -- isLeftPart
    elseif object.objectType == tes3.objectType.clothing then
        ---@cast object tes3clothing
        -- object.slot
        -- isLeftPart
    elseif object.objectType == tes3.objectType.bodyPart then
        ---@cast object tes3bodyPart
        -- object.part
        -- object.partType
    end
    return orientations[object.objectType]
end

---@class Inspector : IController
---@field root niNode?
---@field pivot niNode?
---@field enterFrameCallback fun(e : enterFrameEventData)?
---@field activateCallback fun(e : activateEventData)?
---@field switchAnotherLookCallback fun()?
---@field resetPosecCallback fun()?
---@field angularVelocity tes3vector3 -- vec2 doesnt have dot
---@field baseRotation tes3matrix33
---@field baseScale number
---@field zoomStart number
---@field zoomEnd number
---@field zoomTime number
---@field original niNode?
---@field another niNode?
---@field anotherData? AnotherLookData
---@field anotherLook boolean
local this = {}
setmetatable(this, { __index = base })

---@type Inspector
local defaults = {
    root = nil,
    pivot = nil,
    enterFrame = nil,
    angularVelocity = tes3vector3.new(0, 0, 0),
    baseRotation = tes3matrix33.new(),
    baseScale = 1,
    zoomStart = 1,
    zoomEnd = 1,
    zoomTime = 0,
    original = nil,
    another = nil,
    anotherData = nil,
    anotherLook = false,
}

---@return Inspector
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Inspector

    return instance
end

---@param node niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
---@param func fun(node : niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape)
local function foreach(node, func)
    func(node)
    if node.children then
        for _, child in ipairs(node.children) do
            if child then
                foreach(child, func)
            end
        end
    end
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

---@param self Inspector
---@param scale number
function this.SetScale(self, scale)
    local prev = self.root.scale
    local newScale = math.max(self.baseScale * scale, math.fepsilon)
    self.root.scale = newScale
    self.logger:trace("zoom %f from %f", scale, prev)

    -- rescale particle
    -- It seems that the scale is roughly doubly applied to the size of particles. Positions are correct. Is this a specification?
    -- Apply the scale of counterparts
    -- Works well in most cases, but does not seem to work well for non-following types of particles, etc.
    -- Mace of Aevar Stone-Singer
    -- This requires setting the trailer to 0 in niParticleSystemController , which cannot be changed from MWSE.
    foreach(self.pivot, function(node)
        if node:isInstanceOfType(ni.type.NiParticles) then
            ---@cast node niParticles
            for index, value in ipairs(node.data.sizes) do
                node.data.sizes[index] = value * (prev / newScale)
            end
            node.data:markAsChanged()
            node.data:updateModelBound() -- need?
        end
    end)
end

---@param self Inspector
---@param e enterFrameEventData
function this.OnEnterFrame(self, e)
    if tes3.onMainMenu() then
        return
    end

    if self.root then
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
            -- TODO consider distance to near place on actiavtion
        end

        if self.zoomTime < zoomDuration then
            self.zoomTime = math.min(self.zoomTime + e.delta, zoomDuration)
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)

            self:SetScale(scale)
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
            q:fromRotation(self.root.rotation:copy())

            local dest = zRot * xRot * q
            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            self.root.rotation = m:copy()

            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * friction,
                math.clamp(e.delta * resistance, 0, 1))
        end
        -- local euler = self.root.rotation:toEulerXYZ():copy()
        -- tes3.messageBox(string.format("%f, %f, %f", math.deg(euler.x), math.deg(euler.y), math.deg(euler.z)))

        -- updateTime = updateTime  + e.delta
        self.root:update({ controllers = true })
        self.root:updateEffects()
    end
end

---@param self Inspector
--- @param e activateEventData
function this.OnActivate(self, e)
    -- block picking up items
    self.logger:debug("Block activation")
    e.block = true
end

function this.SwitchAnotherLook(self)
    self.logger:info("Switch AnotherLook")
    if self.anotherData and self.anotherData.data and self.anotherData.type ~= nil then

        if self.anotherData.type == settings.anotherLookType.BodyParts then

        end

        if self.anotherData.type == settings.anotherLookType.WeaponSheathing then

            if not self.another then
                local data = self.anotherData.data ---@cast data WeaponSheathingData
                self.another = tes3.loadMesh(data.path, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
                if not self.another  then
                    self.logger:error("failed to load %s", data.path)
                    return
                end
            end

            if self.anotherLook then
                self.pivot:detachChild(self.another)
                self.pivot:attachChild(self.original)
            else
                self.pivot:detachChild(self.original)
                self.pivot:attachChild(self.another)
            end
            self.anotherLook = not self.anotherLook

            -- TODO self.SetScale() for particle
            -- just swap, no adjust centering
            self.pivot:update()
            self.pivot:updateEffects()

            -- TODO weapon sound
        end


        if self.anotherData.type == settings.anotherLookType.Book then
            if self.anotherData.data.type == tes3.bookType.book then
                tes3ui.showBookMenu(self.anotherData.data.text)
            elseif self.anotherData.data.type == tes3.bookType.scroll then
                tes3ui.showScrollMenu(self.anotherData.data.text)
            end
            -- TODO hide mesh or freeze control
            -- TODO needs opend flag for some quest
        end
    end

end

function this.ResetPose(self)
    self.logger:info("Reset Pose")
    if self.root then
        self.angularVelocity = tes3vector3.new(0, 0, 0)
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration

        self.root.rotation = self.baseRotation:copy()

        local scale = 1
        self:SetScale(1)
    end
end

---@param offset number
---@return niNode
---@return niNode
local function SetupNode(offset)
    local pivot = niNode.new() -- pivot node
    pivot.name = "InspectItem:Pivot"
    -- If transparency is included, it may not work unless it is specified on a per material.
    local zBufferProperty = niZBufferProperty.new()
    zBufferProperty.name = "InspectItem:DepthTestWrite"
    zBufferProperty:setFlag(true, 0) -- test
    zBufferProperty:setFlag(true, 1) -- write
    pivot:attachProperty(zBufferProperty)
    -- No culling on the back face because the geometry of the part to be placed on the ground does not exist.
    local stencilProperty = niStencilProperty.new()
    zBufferProperty.name = "InspectItem:NoCull"
    stencilProperty.drawMode = 3 -- DRAW_BOTH
    pivot:attachProperty(stencilProperty)
    pivot.appCulled = false

    local root = niNode.new()
    root.name = "InspectItem:Root"
    root:attachChild(pivot)
    root.translation = tes3vector3.new(0, offset, 0)
    root.appCulled = false
    return root, pivot
end

---@param self Inspector
---@param bounds tes3boundingBox
---@param cameraData tes3worldControllerRenderCameraData
---@param distance number
---@return number
function this.ComputeFittingScale(self, bounds, cameraData, distance)
    local fovX = cameraData.fov
    local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth
    local tan = math.tan(math.rad(fovX) * 0.5)
    local width = tan * distance
    local height = width * aspectRatio
    -- conservative
    local screenSize = math.min(width, height)
    local size = bounds.max - bounds.min
    local boundsSize = math.max(size.x, size.y, size.z, math.fepsilon)
    local scale = screenSize / boundsSize

    -- diagonal
    -- boundsSize = size:length() -- 3d or dominant 2d
    -- screenSize = math.sqrt(width * width + height * height)

    self.logger:trace("near: %f, far: %f, fov: %f", cameraData.nearPlaneDistance, cameraData.farPlaneDistance,
        cameraData.fov)                                                                                                        -- or world fov?
    self.logger:trace("viewport width: %d, height: %d", cameraData.viewportWidth, cameraData.viewportHeight)
    self.logger:trace("distant width: %f, height: %f", width, height)
    self.logger:debug("fitting scale: %f", scale)
    return scale
end

---@param self Inspector
---@param params Activate.Params
function this.Activate(self, params)
    local target = params.target
    if not target then
        return
    end
    local mesh = target.mesh
    if not tes3.getFileExists(string.format("Meshes\\%s", mesh)) then
        self.logger:error("Not exist mesh: %s", mesh)
        return
    end

    local model = tes3.loadMesh(mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

    --local parts = params.another.data.parts
    -- for index, bodyPart in ipairs(params.another.data.parts) do
    --     local active = tes3.player.bodyPartManager:getActiveBodyPart(bodyPart.part.partType, bodyPart.type)
    --     local partModel = tes3.loadMesh(bodyPart.part.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
    --     if active.node then
    --         partModel.worldTransform = active.node.worldTransform:copy()
    --     else
    --         -- root?
    --     end
    --     model:attachChild(partModel)
    -- end

    local bounds = model:createBoundingBox()

    -- not recompute
    --[[
    local boundsmodel = model:clone()
    foreach(boundsmodel, function(node)
        if node:isInstanceOfType(ni.type.NiParticles) then
            node.parent:detachChild(node)
        end
        if node:isInstanceOfType(ni.type.NiLight) then
            node.parent:detachChild(node)
        end
    end)
    boundsmodel:updateEffects()
    boundsmodel:update()
    bounds = boundsmodel:createBoundingBox()
    --]]

    -- create only mesh bounds
    -- TODO propagete scaling
    -- zero..
    -- trishape?
    --[[
    bounds.max = tes3vector3.new(-math.fhuge, -math.fhuge, -math.fhuge)
    bounds.min = tes3vector3.new(math.fhuge,math.fhuge,math.fhuge)
    foreach(model, function(node)
        if node:isInstanceOfType(ni.type.NiParticles) then
            return
        end
        if node:isInstanceOfType(ni.type.NiTriBasedGeom) then
            ---@cast node niTriBasedGeometry
            local origin = node.worldBoundOrigin
            local radius = node.worldBoundRadius
            bounds.max.x = math.max(bounds.max.x, origin.x + radius);
            bounds.max.y = math.max(bounds.max.y, origin.y + radius);
            bounds.max.z = math.max(bounds.max.z, origin.z + radius);
            bounds.min.x = math.min(bounds.min.x, origin.x - radius);
            bounds.min.y = math.min(bounds.min.y, origin.y - radius);
            bounds.min.z = math.min(bounds.min.z, origin.z - radius);
            self.logger:debug(tostring(origin) .. " " .. tostring(radius));
        end
    end)
    --]]


    self.anotherData = params.another

    local distance = params.offset

    -- centering
    local offset = (bounds.max + bounds.min) * -0.5
    self.logger:debug(tostring(bounds.max))
    self.logger:debug(tostring(bounds.min))
    self.logger:debug(tostring(offset))
    local root, pivot = SetupNode(distance)
    pivot.translation = offset
    pivot:attachChild(model)

    -- initial rotation
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
        root.rotation = root.rotation * rot:copy()
    else
        -- auto rotation
        -- dominant axis based
        local size = bounds.max - bounds.min
        self.logger:debug("bounds size: %f, %f, %f", size.x, size.y, size.z)
        local my = 0
        if size.x < size.y and size.z < size.y then
            my = 1
        end
        local mz = 0
        if size.x < size.z and size.y < size.z then
            mz = 2
        end
        local imax = my + mz;
        my = 0
        if size.x > size.y and size.z > size.y then
            my = 1
        end
        mz = 0
        if size.x > size.z and size.y > size.z then
            mz = 2
        end
        local imin = my + mz;
        self.logger:debug("axis %d, %d", imax, imin)

        -- depth is maximum or height is minimum, y-up
        -- it seems that area ratio would be a better result.
        if imax == 1 or imin == 2 then
            local orientation = tes3vector3.new(-90, 0, 0)
            local rot = tes3matrix33.new()
            rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
            root.rotation = root.rotation * rot:copy()
        end
    end

    self.root = root
    self.pivot = pivot
    self.original = model
    self.another = nil
    self.anotherLook = false

    -- initial scaling
    local camera = tes3.worldController.armCamera
    local cameraRoot = camera.cameraRoot
    local cameraData = camera.cameraData
    local scale = self:ComputeFittingScale(bounds, cameraData, distance)

    self.baseScale = root.scale
    self:SetScale(scale)

    self.angularVelocity = tes3vector3.new(0, 0, 0)
    self.baseRotation = root.rotation:copy()
    self.baseScale = scale
    self.zoomStart = 1
    self.zoomEnd = 1
    self.zoomTime = zoomDuration


    cameraRoot:attachChild(root)
    cameraRoot:update()
    cameraRoot:updateEffects()

    --- subscribe events
    self.enterFrameCallback = function(e)
        self:OnEnterFrame(e)
    end
    self.activateCallback = function(e)
        self:OnActivate(e)
    end
    self.switchAnotherLookCallback = function()
        self:SwitchAnotherLook()
    end
    self.resetPosecCallback = function()
        self:ResetPose()
    end
    event.register(tes3.event.enterFrame, self.enterFrameCallback)
    event.register(tes3.event.activate, self.activateCallback)
    event.register(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
    event.register(settings.resetPoseEventName, self.resetPosecCallback)

end

---@param self Inspector
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.root then
        if tes3.worldController and tes3.worldController.armCamera then
            local camera = tes3.worldController.armCamera
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(self.root)
        end

        event.unregister(tes3.event.enterFrame, self.enterFrameCallback)
        event.unregister(tes3.event.activate, self.activateCallback)
        event.unregister(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
        event.unregister(settings.resetPoseEventName, self.resetPosecCallback)
        self.enterFrameCallback = nil
        self.activateCallback = nil
        self.switchAnotherLookCallback = nil
        self.resetPosecCallback = nil

        self.pivot = nil
        self.root = nil
        self.original = nil
        self.another = nil
        self.anotherData = nil
    end
end

---@param self Inspector
function this.Reset(self)
    self.pivot = nil
    self.root = nil
    self.original = nil
    self.another = nil
    self.anotherData = nil
end

return this
