local base = require("InspectIt.controller.base")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")
local zoomThreshold = 0  -- delta
local zoomDuration = 0.4 -- second
local angleThreshold = 0 -- pixel
local velocityEpsilon = 0.000001
local velocityThreshold = 0 -- pixel
local frictionRotation = 0.1     -- Attenuation with respect to velocity
local resistanceRotation = 3.0   -- Attenuation with respect to time
local frictionTranslation = 0.00001     -- Attenuation with respect to velocity
local resistanceTranslation = 9.0   -- Attenuation with respect to time
local fittingRatio = 0.5 -- Ratio to fit the screen

-- fixed orientation
local orientations = {
    -- [tes3.objectType.activator] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.alchemy] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.ammunition] = tes3vector3.new(-90, 0, -90),
    [tes3.objectType.apparatus] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.armor] = tes3vector3.new(0, 0, 0), -- It's not aligned. It's a mess.
    [tes3.objectType.bodyPart] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.book] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.cell] = tes3vector3.new(0, 0, 0),
    --[tes3.objectType.clothing] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.container] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.creature] = tes3vector3.new(0, 0, -180),
    -- [tes3.objectType.door] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.enchantment] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.ingredient] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.land] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.landTexture] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.leveledCreature] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.leveledItem] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.light] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.lockpick] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.magicEffect] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.miscItem] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileActor] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileCreature] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileNPC] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobilePlayer] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileProjectile] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.mobileSpellProjectile] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.npc] = tes3vector3.new(0, 0, -180),
    [tes3.objectType.probe] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.reference] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.region] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.repairItem] = tes3vector3.new(-90, 0, -90),
    -- [tes3.objectType.spell] = tes3vector3.new(0, 0, 0),
    -- [tes3.objectType.static] = tes3vector3.new(0, 0, 0),
    [tes3.objectType.weapon] = tes3vector3.new(-90, 0, -90),
}

---@class Inspector : IController
---@field root niNode?
---@field pivot niNode?
---@field enterFrameCallback fun(e : enterFrameEventData)?
---@field activateCallback fun(e : activateEventData)?
---@field switchAnotherLookCallback fun()?
---@field switchLightingCallback fun()?
---@field resetPosecCallback fun()?
---@field angularVelocity tes3vector3 -- vec2 doesnt have dot
---@field velocity tes3vector3 -- vec2 doesnt have dot
---@field baseRotation tes3matrix33
---@field baseScale number
---@field zoomStart number
---@field zoomEnd number
---@field zoomTime number
---@field zoomMax number
---@field original niNode?
---@field originalBounds tes3boundingBox?
---@field another niNode?
---@field anotherBounds tes3boundingBox?
---@field anotherData? AnotherLookData
---@field anotherLook boolean
---@field lighting LightingType
---@field distance tes3vector3 half width, distance, half height
---@field objectId string? object id
---@field objectType tes3.objectType?
local this = {}
setmetatable(this, { __index = base })

---@type Inspector
local defaults = {
    root = nil,
    pivot = nil,
    enterFrame = nil,
    angularVelocity = tes3vector3.new(0, 0, 0),
    velocity = tes3vector3.new(0, 0, 0),
    baseRotation = tes3matrix33.new(),
    baseScale = 1,
    zoomStart = 1,
    zoomEnd = 1,
    zoomTime = 0,
    zoomMax = 2,
    original = nil,
    originalBounds = nil,
    another = nil,
    anotherBounds = nil,
    anotherData = nil,
    anotherLook = false,
    lighting = settings.lightingType.Default,
    distance = tes3vector3.new(20, 20, 20),
    objectId = nil,
    objectType = nil,
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

-- advanced traverser, allow nil, more info
---@param node niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape?
---@param func fun(node : niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape?, depth : number)
---@param depth integer?
local function traverse(node, func, depth)
    depth = depth or 0
    func(node, depth)
    if node and node.children then
        local count = #node.children
        if count == 1 and not node.children[1] then -- always allocated dummy [1]
        else
            local d = depth + 1
            for _, child in ipairs(node.children) do
                traverse(child, func, d)
            end
        end
    end
end

---@param root niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
local function DumpSceneGraph(root)
    -- TODO json format
    local str = {}
    traverse(root,
        function(node, depth)
            local indent = string.rep("    ", depth)
            if node then
                local out = string.format("%s:%s", node.RTTI.name, tostring(node.name))
                if node.translation and node.rotation and node.scale then
                    out = out .. "\n" .. indent .. string.format("  local trans %s, rot %s, scale %f", node.translation, node.rotation, node.scale)
                end
                if node.worldTransform then
                    out = out .. "\n" .. indent .. string.format("  world trans %s, rot %s, scale %f", node.worldTransform.translation, node.worldTransform.rotation, node.worldTransform.scale)
                end
                table.insert(str, indent .. "- " .. out)
            else
                table.insert(str, indent .. "- " .. "nil")
            end
        end)
    require("InspectIt.logger"):debug("\n" .. table.concat(str, "\n"))
    -- return str
end

---@param lighting LightingType
---@return tes3worldControllerRenderCamera|tes3worldControllerRenderTarget? camera
---@return number fovX
local function GetCamera(lighting)
    local fovX = mge.camera.fov
    if tes3.worldController then
        if lighting == settings.lightingType.Constant then
            local camera = tes3.worldController.menuCamera
            if camera and camera.cameraData then
                fovX = camera.cameraData.fov
            end
            return tes3.worldController.menuCamera, fovX
        end
        return tes3.worldController.armCamera, fovX -- default
    end
    return nil, fovX
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
---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@param bounds tes3boundingBox
---@return tes3vector3? degree
function this.GetOrientation(self, object, bounds)
    -- from table
    local orientation = orientations[object.objectType]
    if orientation then
        return orientation
    end

    -- unique type
    if object.objectType == tes3.objectType.armor then
        ---@cast object tes3armor
        local slot = {
            [tes3.armorSlot.boots] = tes3vector3.new(0, 0, 0),
            [tes3.armorSlot.cuirass] = tes3vector3.new(-90, 0, 0),
            [tes3.armorSlot.greaves] = tes3vector3.new(-90, 0, 0),
            [tes3.armorSlot.helmet] = tes3vector3.new(0, 0, 0),
            [tes3.armorSlot.leftBracer] = tes3vector3.new(0, 0, 180),
            [tes3.armorSlot.leftGauntlet] = tes3vector3.new(0, 0, 180),
            [tes3.armorSlot.leftPauldron] = tes3vector3.new(0, 0, 180),
            [tes3.armorSlot.rightBracer] = tes3vector3.new(0, 0, 0),
            [tes3.armorSlot.rightGauntlet] = tes3vector3.new(0, 0, 0),
            [tes3.armorSlot.rightPauldron] = tes3vector3.new(0, 0, 0),
            [tes3.armorSlot.shield] = tes3vector3.new(-90, 0, 0),
        }
        local o = slot[object.slot]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.clothing then
        ---@cast object tes3clothing
        local slot = {
            [tes3.clothingSlot.amulet] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.belt] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.leftGlove] = tes3vector3.new(-90, 0, 180),
            [tes3.clothingSlot.pants] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.rightGlove] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.ring] = tes3vector3.new(0, 0, 0),
            [tes3.clothingSlot.robe] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.shirt] = tes3vector3.new(-90, 0, 0),
            [tes3.clothingSlot.shoes] = tes3vector3.new(0, 0, 0),
            [tes3.clothingSlot.skirt] = tes3vector3.new(-90, 0, 0),
        }
        local o = slot[object.slot]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.bodyPart then
        ---@cast object tes3bodyPart
    elseif object.objectType == tes3.objectType.weapon then
        ---@cast object tes3weapon
        local weaponType = {
            [tes3.weaponType.marksmanCrossbow] = tes3vector3.new(0, 0, -90),
        }
        local o = weaponType[object.type]
        if o then
            return o
        end
    elseif object.objectType == tes3.objectType.book then
        local size = bounds.max - bounds.min
        local ratio = size.y / math.max(size.x, math.fepsilon)
        self.logger:debug("book ratio %f / %f = %f", size.y, size.x, ratio)
        ---@cast object tes3book
        if object.type == tes3.bookType.book then
            -- FIXME The Third Door (BookSkill_Axe1) bounds.x wrong
            -- opened or closed
            if ratio > 1.75 then -- opened and rotation
                return tes3vector3.new(-90, 0, 90)
            end
            return tes3vector3.new(-90, 0, 0) -- closed
        else
            if ratio < 0.35 then -- rolled scroll?
                return tes3vector3.new(0, 0, 0)
            end
            -- FIXME papers are wired. mirrored as in left part.
            if size.z < 3 then
                return tes3vector3.new(-90, 180, 0)
            end
            return tes3vector3.new(-90, 0, 0)
        end
    elseif object.objectType == tes3.objectType.door then
        -- expect axis aligned, almost centered
        local size = bounds.max - bounds.min
        if size.x > size.y then
            -- whitch bold thickness? face has handles?
            self.logger:debug("y-face %f, %f", bounds.max.y, bounds.min.y)
            if math.abs(bounds.max.y) - math.abs(bounds.min.y) >= 0 then
                return tes3vector3.new(0, 0, 0)
            else
                return tes3vector3.new(0, 0, 0) -- same face is front?
            end
        else
            self.logger:debug("x-face %f, %f", bounds.max.x, bounds.min.x)
            if math.abs(bounds.max.x) - math.abs(bounds.min.x) >= 0 then
                return tes3vector3.new(0, 0, -90)
            else
                return tes3vector3.new(0, 0, 90)
            end
        end
        -- TODO trap door
    end

    -- auto rotation
    -- dominant axis based
    -- TODO more better algorithm
    local size = bounds.max - bounds.min
    self.logger:debug("bounds size: %s", size)
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
    self.logger:debug("axis: max %d, min %d", imax, imin)
    if imax == 1 or imin == 2 then     -- depth is maximum or height is minimum, y-up
        -- if imax == 1 then -- just depth is maximum
        -- it seems that area ratio would be a better result.
        return tes3vector3.new(-60, 0, 0)
    end

    return nil -- tes3vector3.new(0, 0, 0) -- default
end

---@param self Inspector
---@param scale number
function this.SetScale(self, scale)
    local prev = self.root.scale
    local newScale = math.max(self.baseScale * scale, math.fepsilon)
    self.root.scale = newScale
    self.logger:trace("Zoom %f -> %f", prev, scale)

    -- rescale particle
    -- It seems that the scale is roughly doubly applied to the size of particles. Positions are correct. Is this a specification?
    -- Apply the scale of counterparts
    -- Works well in most cases, but does not seem to work well for non-following types of particles, etc.
    -- Torch, Mace of Aevar Stone-Singer
    -- This requires setting the 'trailer' to 0 in niParticleSystemController , which cannot be changed from MWSE.
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
---@param pickup boolean
function this.PlaySound(self, pickup)
    if config.inspection.playSound then
        -- TODO creature -> sound gen
        -- door, others
        tes3.playItemPickupSound({ item = self.objectId, pickup = pickup })
    end
end

---@param self Inspector
---@param e enterFrameEventData
function this.OnEnterFrame(self, e)
    if settings.OnOtherMenu() then
        -- pause
        return
    end

    if self.root then
        -- tes3ui.captureMouseDrag may be better?

        local wc = tes3.worldController
        local ic = wc.inputController

        -- scale
        local zoom = ic.mouseState.z
        if math.abs(zoom) > zoomThreshold then
            zoom = zoom * 0.001 * config.input.sensitivityZ * (config.input.inversionZ and -1 or 1)
            self.logger:trace("Wheel: %f, wheel velocity %f", ic.mouseState.z, zoom)
            -- update current zooming
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self.zoomStart = scale
            local limit = math.max(self.zoomMax / self.baseScale, 1)
            self.zoomEnd = math.clamp(self.zoomEnd + zoom, 0.5, limit)
            self.zoomTime = 0
        end

        if self.zoomTime < zoomDuration then
            self.zoomTime = math.min(self.zoomTime + e.delta, zoomDuration)
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)

            self:SetScale(scale)
        end

        if ic:isMouseButtonDown(0) then -- left click
            -- rotate
            local zAngle = ic.mouseState.x
            local xAngle = ic.mouseState.y

            if math.abs(zAngle) <= angleThreshold then
                zAngle = 0
            end
            if math.abs(xAngle) <= angleThreshold then
                xAngle = 0
            end
            zAngle = zAngle * wc.mouseSensitivityX * config.input.sensitivityX * (config.input.inversionX and -1 or 1)
            xAngle = xAngle * wc.mouseSensitivityY * config.input.sensitivityY * (config.input.inversionY and -1 or 1)
            self.logger:trace("Mouse %f, %f, Angular velocity %f, %f", ic.mouseState.x, ic.mouseState.y, zAngle, xAngle)

            self.angularVelocity.z = zAngle
            self.angularVelocity.x = xAngle
        elseif ic:isMouseButtonDown(2) then -- middle click
            -- translate
            local modifier = self.distance.y * 0.5
            local horizontal = ic.mouseState.x * modifier
            local vertical = ic.mouseState.y * -modifier
            if math.abs(horizontal) <= velocityThreshold then
                horizontal = 0
            end
            if math.abs(vertical) <= velocityThreshold then
                vertical = 0
            end
            -- need inversion? another sensitivity and inversion config?
            horizontal = horizontal * wc.mouseSensitivityX * config.input.sensitivityX * (config.input.inversionX and -1 or 1)
            vertical = vertical * wc.mouseSensitivityY * config.input.sensitivityY * (config.input.inversionY and -1 or 1)
            self.velocity.x = horizontal
            self.velocity.z = vertical
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

            -- No basis in physics.
            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * frictionRotation,
                math.clamp(e.delta * resistanceRotation, 0, 1))
        end
        if self.velocity:dot(self.velocity) > velocityEpsilon then
            -- center vs corners
            local dest = self.root.translation:copy() + self.velocity:copy()
            dest.x = math.clamp(dest.x, -self.distance.x, self.distance.x)
            dest.z = math.clamp(dest.z, -self.distance.z, self.distance.z)
            self.root.translation = dest
            self.velocity = self.velocity:lerp(self.velocity * frictionTranslation,
                math.clamp(e.delta * resistanceTranslation, 0, 1))
        end
        -- local euler = self.root.rotation:toEulerXYZ():copy()
        -- tes3.messageBox(string.format("%f, %f, %f", math.deg(euler.x), math.deg(euler.y), math.deg(euler.z)))

        -- TODO play controllers, but those does not work.
        -- updateTime = updateTime  + e.delta
        --self.root:update({ controllers = true })
        self.root:update()
        self.root:updateEffects()
    end
end

---@param self Inspector
--- @param e activateEventData
function this.OnActivate(self, e)
    -- block picking up items
    self.logger:debug("Block to Activate")
    e.block = true
end

---@param self Inspector
function this.SwitchAnotherLook(self)
    self.logger:debug("Switch another look")
    if self.anotherData and self.anotherData.data and self.anotherData.type ~= nil then

        if self.anotherData.type == settings.anotherLookType.BodyParts then
            if not self.another then
                ---@class Socket
                ---@field name string?
                ---@field isLeft boolean?

                ---@type {[tes3.activeBodyPart] : Socket }
                local sockets = {
                    [tes3.activeBodyPart.head]          = { name = "Head", },
                    [tes3.activeBodyPart.hair]          = { name = "Head", },
                    [tes3.activeBodyPart.neck]          = { name = "Neck", },
                    [tes3.activeBodyPart.chest]         = { name = "Chest", },
                    [tes3.activeBodyPart.groin]         = { name = "Groin", },
                    [tes3.activeBodyPart.skirt]         = { name = "Groin", },
                    [tes3.activeBodyPart.rightHand]     = { name = "Right Hand", },
                    [tes3.activeBodyPart.leftHand]      = { name = "Left Hand", isLeft = true },
                    [tes3.activeBodyPart.rightWrist]    = { name = "Right Wrist", },
                    [tes3.activeBodyPart.leftWrist]     = { name = "Left Wrist", isLeft = true },
                    [tes3.activeBodyPart.shield]        = { name = "Shield Bone", },
                    [tes3.activeBodyPart.rightForearm]  = { name = "Right Forearm", },
                    [tes3.activeBodyPart.leftForearm]   = { name = "Left Forearm", isLeft = true },
                    [tes3.activeBodyPart.rightUpperArm] = { name = "Right Upper Arm", },
                    [tes3.activeBodyPart.leftUpperArm]  = { name = "Left Upper Arm", isLeft = true },
                    [tes3.activeBodyPart.rightFoot]     = { name = "Right Foot", },
                    [tes3.activeBodyPart.leftFoot]      = { name = "Left Foot", isLeft = true },
                    [tes3.activeBodyPart.rightAnkle]    = { name = "Right Ankle", },
                    [tes3.activeBodyPart.leftAnkle]     = { name = "Left Ankle", isLeft = true },
                    [tes3.activeBodyPart.rightKnee]     = { name = "Right Knee", },
                    [tes3.activeBodyPart.leftKnee]      = { name = "Left Knee", isLeft = true },
                    [tes3.activeBodyPart.rightUpperLeg] = { name = "Right Upper Leg", },
                    [tes3.activeBodyPart.leftUpperLeg]  = { name = "Left Upper Leg", isLeft = true },
                    [tes3.activeBodyPart.rightPauldron] = { name = "Right Clavicle" },
                    [tes3.activeBodyPart.leftPauldron]  = { name = "Left Clavicle", isLeft = true },
                    [tes3.activeBodyPart.weapon]        = { name = "Weapon Bone", }, -- the real node name depends on the current weapon type.
                    [tes3.activeBodyPart.tail]          = { name = "Tail" },
                }

                self.another = niNode.new()
                local data = self.anotherData.data ---@cast data BodyPartsData

                -- ground
                local root = tes3.player.object.sceneNode:clone() --[[@as niNode]]
                DumpSceneGraph(root)
                self.logger:debug("Load base mesh : %s", tes3.player.object.mesh)
                root = tes3.loadMesh(tes3.player.object.mesh, true):clone()--[[@as niNode]]
                if not root then
                    self.logger:error("Failed to load: %s", tes3.player.object.mesh)
                    return
                end
                -- remove unnecessary nodes
                foreach(root, function (node)
                    if node:isInstanceOfType(ni.type.NiTriShape) then
                        -- reconnect child?
                        if node.parent then
                            node.parent:detachChild(node)
                        end
                    end
                end)
                DumpSceneGraph(root)
                -- skeletal root
                local skeletal = root:getObjectByName("Bip01") --[[@as niNode?]]
                if skeletal then
                    self.logger:trace("skeletal")
                    self.logger:trace("%s", skeletal.translation)
                    self.logger:trace("%s", skeletal.rotation)
                    self.logger:trace("%s", skeletal.scale)
                    root = skeletal
                    -- local r = tes3matrix33.new()
                    -- r:toIdentity()
                    -- root.rotation = r
                end
                -- -- reset
                root.translation = tes3vector3.new(0,0,0)
                root.scale = 1
                root:update() -- transform
                self.another = root
                local toRelative = root.worldTransform:copy():invert() -- or transpose

                for _, part in ipairs(data.parts) do
                    local bodypart = part.part

                    -- no hieralchy
                    self.logger:debug("Load bodypart mesh : %s", bodypart.mesh)
                    local model = tes3.loadMesh(bodypart.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

                    local socketInfo = sockets[part.type]
                    if socketInfo and socketInfo.name then
                        local socket = root:getObjectByName(socketInfo.name) --[[@as niNode?]]
                        if socket and socket.attachChild then
                            -- self.logger:debug("socket: %s from %d", s, part.type)
                            self.logger:trace("transform: %s", socket.worldTransform.translation)
                            self.logger:trace("rotation: %s", socket.worldTransform.rotation:toEulerXYZ())
                            self.logger:trace("scale: %s", socket.worldTransform.scale)

                            -- retarget
                            foreach(model, function (node)
                                if node:isInstanceOfType(ni.type.NiTriShape) then
                                    if node.skinInstance then
                                        for index, bone in ipairs(node.skinInstance.bones) do
                                            node.skinInstance.bones[index] = root:getObjectByName(bone.name)
                                        end
                                        -- node.skinInstance.root = skeletal -- TODO need?
                                        self.logger:debug("skin: %s", node.name)
                                    end
                                end
                            end)

                            -- below maybe no need with skinning

                            -- resolve offset
                            local offsetNode = model:getObjectByName("BoneOffset")
                            if offsetNode then
                                tes3.messageBox(string.format("BoneOffset: %s", offsetNode.translation))
                                self.logger:debug("BoneOffset: %s", offsetNode.translation)
                                model.translation = offsetNode.translation:copy()
                            end

                            -- resolve left
                            -- TODO get rid right or left mesh
                            if socketInfo.isLeft then
                                -- non uniform scale
                                local mirror = tes3matrix33.new(
                                    -1, 0, 0,
                                    0, 1, 0,
                                    0, 0, 1
                                )
                                local rotation = model.rotation:copy()
                                --model.rotation = rotation:copy() * mirror:copy()
                                model.rotation = mirror:copy() * rotation:copy()
                                local t = model.translation:copy()
                                model.translation = mirror:copy() * t:copy()
                            end

                            -- extract root
                            socket:attachChild(model)
                        else
                            self.logger:warn("not find socket %s, %s", socketInfo.name, model.name )
                            root:attachChild(model)
                        end
                    else
                        self.logger:warn("invalid socket name %s", model.name )
                        root:attachChild(model)
                end


                end
                -- TODO apply race width, height scaling
                -- TODO bounds and re-centering
                self.another:updateEffects()
                self.another:update()
            end

            if self.anotherLook then
                self.logger:debug("Body parts")
                self.pivot:detachChild(self.another)
                self.pivot:attachChild(self.original)
            else
                self.logger:debug("Physical Item")
                self.pivot:detachChild(self.original)
                self.pivot:attachChild(self.another)
            end
            self.anotherLook = not self.anotherLook
            self:PlaySound(not self.anotherLook)
        end

        if self.anotherData.type == settings.anotherLookType.WeaponSheathing then

            if not self.another then
                local data = self.anotherData.data ---@cast data WeaponSheathingData
                self.logger:debug("Load weapon sheathing mesh : %s", data.path)
                self.another = tes3.loadMesh(data.path, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
                if not self.another  then
                    self.logger:error("Failed to load %s", data.path)
                    return
                end
            end

            if self.anotherLook then
                self.logger:debug("Sheathed Weapon")
                self.pivot:detachChild(self.another)
                self.pivot:attachChild(self.original)
            else
                self.logger:debug("Drawn Weapon")
                self.pivot:detachChild(self.original)
                self.pivot:attachChild(self.another)
            end


            self.anotherLook = not self.anotherLook

            -- apply same scale for particle
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)
            -- just swap, no adjust centering
            self.pivot:update()
            self.pivot:updateEffects()
            self:PlaySound(self.anotherLook)
        end

        if self.anotherData.type == settings.anotherLookType.Book and self.anotherData.data.text then
            if self.anotherData.data.type == tes3.bookType.book then
                self.logger:debug("Show book menu")
                tes3ui.showBookMenu(self.anotherData.data.text)
            elseif self.anotherData.data.type == tes3.bookType.scroll then
                self.logger:debug("Show scroll menu")
                tes3ui.showScrollMenu(self.anotherData.data.text)
            end
        end
    end

end

---@param self Inspector
function this.SwitchLighting(self)
    -- next type
    local lighting = self.lighting + 1
    if lighting > table.size(settings.lightingType) then -- mod, avoid floor
       lighting = 1
    end
    local prev = GetCamera(self.lighting)
    local next, fovX = GetCamera(lighting)
    if prev and next then
        self.logger:debug("Switch lighting: %d -> %d", self.lighting, lighting)
        -- Currently the only difference in lighting is the camera

        -- recalculate base scale, fov changed
        -- but different perspective due to changes in angle of view will occur.
        local cameraData = next.cameraData
        local bounds = self.anotherLook and self.anotherBounds or self.originalBounds
        if bounds then
            local baseScale, distanceWidth, distanceHeight = self:ComputeFittingScale(bounds, cameraData, self.distance.y, fovX, fittingRatio)
            self.baseScale = baseScale

            -- rescale limit
            -- Or always use the camera with the widest field of view of those you plan to use.
            local limit = math.max(self.zoomMax / self.baseScale, 1)
            self.zoomEnd = math.clamp(self.zoomEnd, 0.5, limit)

            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)

            -- clamp translation
            local dest = self.root.translation:copy()
            dest.x = dest.x / self.distance.x  -- to ratio
            dest.z = dest.z / self.distance.z  -- to ratio
            self.distance = tes3vector3.new(distanceWidth * 0.5, self.distance.y, distanceHeight * 0.5)
            dest.x = math.clamp(dest.x * self.distance.x, -self.distance.x, self.distance.x)
            dest.z = math.clamp(dest.z * self.distance.z, -self.distance.z, self.distance.z)
            self.root.translation = dest
        end

        prev.cameraRoot:detachChild(self.root)
        next.cameraRoot:attachChild(self.root) -- lighting == settings.lightingType.Constant
        prev.cameraRoot:update()
        next.cameraRoot:update()
        self.lighting = lighting
    else
        self.logger:error("Failed to find camera for switching lighting.")
    end
end

function this.ResetPose(self)
    self.logger:debug("Reset pose")
    if self.root then
        self.angularVelocity = tes3vector3.new(0, 0, 0)
        self.velocity = tes3vector3.new(0, 0, 0)
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration
        self.root.rotation = self.baseRotation:copy()
        self:SetScale(1)
        self.root.translation = tes3vector3.new(0, self.distance.y, 0)
        self.root:update()
    end
end

---@param offset number
---@return niNode
---@return niNode
local function SetupNode(offset)

    -- doesnt work...
    -- FIXME Menu camera does not draw first with attachment at the top and sorting off.
    ---@diagnostic disable-next-line: undefined-global
    -- local pivot = niSortAdjustNode.new()
    -- pivot.sortingMode = 1 -- ni.sortAdjustMode.off

    local pivot = niNode.new() -- pivot node
    pivot.name = "InspectIt:Pivot"
    -- If transparency is included, it may not work unless it is specified on a per material.
    local zBufferProperty = niZBufferProperty.new()
    zBufferProperty.name = "InspectIt:DepthTestWrite"
    zBufferProperty:setFlag(true, 0) -- test
    zBufferProperty:setFlag(true, 1) -- write
    pivot:attachProperty(zBufferProperty)
    -- No culling on the back face because the geometry of the part to be placed on the ground does not exist.
    local stencilProperty = niStencilProperty.new()
    stencilProperty.name = "InspectIt:NoCull"
    stencilProperty.drawMode = 3 -- DRAW_BOTH
    pivot:attachProperty(stencilProperty)
    local vertexColorProperty = niVertexColorProperty.new()
    vertexColorProperty.name = "InspectIt:emiAmbDif"
    vertexColorProperty.lighting = 1 -- ni.lightingMode.emiAmbDif
    vertexColorProperty.source = 2 -- ni.sourceVertexMode.ambDiff
    pivot:attachProperty(vertexColorProperty)
    pivot.appCulled = false

    local root = niNode.new()
    root.name = "InspectIt:Root"
    root:attachChild(pivot)
    root.translation = tes3vector3.new(0, offset, 0)
    root.appCulled = false
    return root, pivot
end

---@param self Inspector
---@param bounds tes3boundingBox
---@param cameraData tes3worldControllerRenderCameraData
---@param distance number
---@param fovX number
---@param ratio number
---@return number scale
---@return number width
---@return number height
function this.ComputeFittingScale(self, bounds, cameraData, distance, fovX, ratio)
    local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth
    local tan = math.tan(math.rad(fovX) * 0.5)
    local width = tan * math.max(distance, cameraData.nearPlaneDistance + 1) * 2.0
    local height = width * aspectRatio
    -- The cubes like the wooden box should be a perfect fit, but for some reason they don't match.
    -- conservative
    local screenSize = math.min(width, height) * ratio
    local size = bounds.max - bounds.min
    local boundsSize = math.max(size.x, size.y, size.z, math.fepsilon)

    -- diagonal
    -- boundsSize = size:length() -- 3d or dominant 2d
    -- screenSize = math.sqrt(width * width + height * height)

    -- moderation
    -- boundsSize = size:length() -- 3d diagonal
    -- screenSize = math.max(width, height)

    local scale = screenSize / boundsSize

    self.logger:debug("use fovX: %f, MGE near: %f", fovX, mge.camera.nearRenderDistance)
    self.logger:debug("Camera near: %f, far: %f, fov: %f", cameraData.nearPlaneDistance, cameraData.farPlaneDistance,
        cameraData.fov)
    self.logger:debug("Camera viewport width: %d, height: %d", cameraData.viewportWidth, cameraData.viewportHeight)
    self.logger:debug("Distant width: %f, height: %f, fovX: %f", width, height, fovX)
    self.logger:debug("Fitting scale: %f", scale)
    return scale, width , height
end

---@param self Inspector
---@param params Activate.Params
function this.Activate(self, params)
    local target = params.target
    if not target then
        self.logger:error("No Object")
        return
    end
    local mesh = target.mesh
    if not tes3.getFileExists(string.format("Meshes\\%s", mesh)) then
        self.logger:error("Not exist mesh: %s", mesh)
        return
    end

    self.logger:debug("Load mesh : %s", mesh)
    local model = tes3.loadMesh(mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
    foreach(model, function(node)
        if not node.parent then
            return
        end
        if node:isInstanceOfType(ni.type.RootCollisionNode) then
            -- remove collision mesh
            node.parent:detachChild(node)
        elseif node:isOfType(ni.type.NiTriShape) then
            -- remove shadow mesh
            -- https://morrowind-nif.github.io/Notes_EN/module_2_3_1_3_2_10.htm
            if node.name and node.name:lower():startswith("tri shadow") then
                node.parent:detachChild(node)
            end
        end
    end)
    -- DumpSceneGraph(model)

    model.translation = tes3vector3.new(0,0,0)
    model.scale = 1

    model:update() -- trailer partiles gone. but currently thoses are glitched, so its ok.
    -- DumpSceneGraph(model)

    local bounds = model:createBoundingBox():copy()
    if config.display.recalculateBounds then
        -- vertex only bounds
        -- more tight bounds, but possible too heavy.
        self.logger:debug("prev bounds max: %s", bounds.max)
        self.logger:debug("prev bounds min: %s", bounds.min)
        bounds.max = tes3vector3.new(-math.fhuge, -math.fhuge, -math.fhuge)
        bounds.min = tes3vector3.new(math.fhuge, math.fhuge, math.fhuge)
        foreach(model, function(node)
            if node:isOfType(ni.type.NiTriShape) then
                ---@cast node niTriShape
                local data = node.data
                local transform = node.worldTransform:copy()
                if node.skinInstance and node.skinInstance.root then
                    -- skinning seems still skeleton relative or the original world coords from the root to this node
                    -- correct mul order? or just copy.
                    transform = node.skinInstance.root.worldTransform:copy() * transform:copy()
                end

                -- object world bounds
                local max = tes3vector3.new(-math.fhuge, -math.fhuge, -math.fhuge)
                local min = tes3vector3.new(math.fhuge, math.fhuge, math.fhuge)
                for _, vert in ipairs(data.vertices) do
                    local v = transform * vert:copy()
                    max.x = math.max(max.x, v.x);
                    max.y = math.max(max.y, v.y);
                    max.z = math.max(max.z, v.z);
                    min.x = math.min(min.x, v.x);
                    min.y = math.min(min.y, v.y);
                    min.z = math.min(min.z, v.z);
                end

                -- Some meshes seem to contain incorrect vertices.
                -- Or calculations required to transform are still missing.
                -- In especially 'Tri chest' of 'The Imperfect'.
                -- worldBounds always seems correctly, but it's a sphere, lazy bounds. These need to be combined well.
                local center = node.worldBoundOrigin
                local radius = node.worldBoundRadius
                local threshold = radius * 2 -- FIXME In theory, it should fit within the radius, but often it does not. Allow for more margin.
                -- TODO distance squared
                -- boundingbox is some distance away from bounding sphere.
                if center:distance(max) > threshold or center:distance(min) > threshold then
                    self.logger:debug("use bounding sphere: %s", tostring(node.name))
                    self.logger:debug("origin %s, radius %f", node.worldBoundOrigin, node.worldBoundRadius)
                    self.logger:debug("world max %s, min %s, size %s, center %s, length %f", max, min, (max - min), ((max + min) * 0.5), (max - min):length())
                    local smax = center:copy() + radius
                    local smin = center:copy() - radius
                    max = smax
                    min = smin
                end

                -- merge all
                bounds.max.x = math.max(bounds.max.x, max.x);
                bounds.max.y = math.max(bounds.max.y, max.y);
                bounds.max.z = math.max(bounds.max.z, max.z);
                bounds.min.x = math.min(bounds.min.x, min.x);
                bounds.min.y = math.min(bounds.min.y, min.y);
                bounds.min.z = math.min(bounds.min.z, min.z);

            end
        end)
    end

    self.anotherData = params.another

    local distance = params.offset

    -- centering
    -- FIXME Some creatures appear to be offset off. Should skinning be considered?
    local offset = (bounds.max + bounds.min) * -0.5
    self.logger:debug("bounds max: %s", bounds.max)
    self.logger:debug("bounds min: %s", bounds.min)
    self.logger:debug("bounds offset: %s", offset)
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
    self.logger:debug("objectType: %s", findKey(target.objectType))
    local orientation = self:GetOrientation(target, bounds)
    if orientation then
        local rot = tes3matrix33.new()
        rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
        root.rotation = root.rotation * rot:copy()
    end

    self.root = root
    self.pivot = pivot
    self.original = model
    self.originalBounds = bounds
    self.anotherBounds = bounds -- FIXME currently same
    self.another = nil
    self.anotherLook = false
    -- self.lighting = settings.lightingType.Default -- Probably more convenient to carry over previous values

    -- initial scaling
    -- FIXME It does not work correctly while rotating the camera while holding down the tab key during TPV.
    local camera, fovX = GetCamera(self.lighting)
    if not camera then
        self.logger:error("Camera not found")
        return
    end
    local cameraRoot = camera.cameraRoot
    local cameraData = camera.cameraData
    local scale, distanceWidth, distanceHeight = self:ComputeFittingScale(bounds, cameraData, distance, fovX, fittingRatio)
    self.distance = tes3vector3.new(distanceWidth * 0.5, distance, distanceHeight * 0.5)

    self.baseScale = root.scale
    self:SetScale(scale)

    self.angularVelocity = tes3vector3.new(0, 0, 0)
    self.velocity = tes3vector3.new(0, 0, 0)
    self.baseRotation = root.rotation:copy()
    self.baseScale = scale
    self.zoomStart = 1
    self.zoomEnd = 1
    self.zoomTime = zoomDuration

    -- zoom limitation
    local extents = (bounds.max - bounds.min) * 0.5 -- * self.baseScale
    self.logger:debug("bounds extents %s", extents)
    local halfLength = extents:length()
    -- halfLength = math.max(extents.x, extents.y, extents.z, 0)
    -- Offset because it is clipped before the near clip for some reason.
    local clipOffset = 3
    -- I would expect the near to be the same even if the camera is different, and it is.
    local limitScale = math.max(distance - (cameraData.nearPlaneDistance + clipOffset), cameraData.nearPlaneDistance) / math.max(halfLength, math.fepsilon)
    self.logger:debug("halfLength %f, limitScale %f (%f)", halfLength, limitScale, limitScale / self.baseScale)
    self.zoomMax = limitScale -- relative scale, apply base scale after
    --self.zoomMax = math.max(limitScale / self.baseScale, 1)
    -- self.zoomMax = 2

    -- local ref = tes3.createReference({ object = target, position = tes3vector3.new(0,0,0), orientation = tes3vector3.new(0,0,0) })
    -- local light = niPointLight.new()
    -- light:setAttenuationForRadius(256)
    -- light.diffuse = niColor.new(1,1,1)
    -- light.ambient = niColor.new(0,0,0)
    -- light.dimmer = 1
    -- local l = tes3.player:getOrCreateAttachedDynamicLight(light)
    -- self.root:attachChild(l.light)

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
    -- TODO if it have
    self.switchAnotherLookCallback = function()
        self:SwitchAnotherLook()
    end
    self.switchLightingCallback = function()
        self:SwitchLighting()
    end
    self.resetPosecCallback = function()
        self:ResetPose()
    end
    event.register(tes3.event.enterFrame, self.enterFrameCallback)
    event.register(tes3.event.activate, self.activateCallback)
    event.register(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
    event.register(settings.switchLightingEventName, self.switchLightingCallback)
    event.register(settings.resetPoseEventName, self.resetPosecCallback)

    -- It is better to play the sound in another controller, but it is easy to depend on the inspector's state, so run it in that.
    -- it seems it doesn't matter if the ID is not from tes3item.
    self.objectId = target.id
    self.objectType = target.objectType
    self:PlaySound(true)

end

---@param self Inspector
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.root then
        local camera = GetCamera(self.lighting)
        if camera then
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(self.root)
        end

        event.unregister(tes3.event.enterFrame, self.enterFrameCallback)
        event.unregister(tes3.event.activate, self.activateCallback)
        event.unregister(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
        event.unregister(settings.switchLightingEventName, self.switchLightingCallback)
        event.unregister(settings.resetPoseEventName, self.resetPosecCallback)
        self.enterFrameCallback = nil
        self.activateCallback = nil
        self.switchAnotherLookCallback = nil
        self.switchLightingCallback = nil
        self.resetPosecCallback = nil

        if not params.menuExit then
            self:PlaySound(false)
        end
    end
    self.pivot = nil
    self.root = nil
    self.original = nil
    self.originalBounds = nil
    self.another = nil
    self.anotherBounds = nil
    self.anotherData = nil
    self.objectId = nil
    self.objectType = nil
end

---@param self Inspector
function this.Reset(self)
    self.pivot = nil
    self.root = nil
    self.original = nil
    self.another = nil
    self.anotherData = nil
    self.objectId = nil
    self.objectType = nil
    self.lighting = settings.lightingType.Default
end

return this
