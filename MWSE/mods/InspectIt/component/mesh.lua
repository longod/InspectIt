---@class NodeProcessor
local this = {}
local logger = require("InspectIt.logger")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")

local sameArmor = nil ---@type string[]
local sameClothing = nil ---@type string[]

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

---@param objectType tes3.objectType
---@return string[] ids
local function CollectSameMeshAsRightPart(objectType)
    local result = {} ---@type {[string]: boolean}
    local memo = {} ---@type {[string]: string|boolean}
    for o in tes3.iterateObjects(objectType) do
        ---@cast o tes3armor|tes3clothing
        if o.mesh then
            local mesh = o.mesh:lower()
            if not o.isLeftPart then
                if memo[mesh] and memo[mesh] ~= true then
                    result[memo[mesh]] = true
                    logger:trace("same mesh id: %s, plugin: %s, mesh: %s", memo[mesh], o.sourceMod, mesh)
                end
                memo[mesh] = true
            elseif o.isLeftPart then
                local id = o.id:lower()
                if memo[mesh] == true then
                    result[id] = true
                    logger:trace("same mesh id: %s, plugin: %s, mesh: %s", id, o.sourceMod, mesh)
                else
                    memo[mesh] = id
                end
            end
        end
    end
    return table.keys(result, true)
end

---@return string[]
function this.GetArmorSameMeshAsRightPart()
    if not sameArmor then
        sameArmor = CollectSameMeshAsRightPart(tes3.objectType.armor)
        logger:debug("same mesh armor: %d", table.size(sameArmor))
    end
    return sameArmor
end

function this.GetClothingSameMeshAsRightPart()
    if not sameClothing then
        sameClothing = CollectSameMeshAsRightPart(tes3.objectType.clothing)
        logger:debug("same mesh clothing: %d", table.size(sameClothing))
    end
    return sameClothing
end

---@param id string
---@return boolean
function this.CanMirrorById(id)
    if config.leftPartFilter[id:lower()] == true then
        logger:debug("Exclude mirror the left part by id: %s", id)
        return false
    end
    return true
end

---@param sourceMod string
---@return boolean
function this.CanMirrorBySourceMod(sourceMod)
    if sourceMod and config.leftPartFilter[sourceMod:lower()] == true then
        logger:debug("Exclude mirror the left part by plugin: %s", sourceMod)
        return false
    end
    return true
end

---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@return boolean
function this.CanMirror(object)
    if object.isLeftPart and config.display.leftPart then
        if this.CanMirrorBySourceMod(object.sourceMod) == false then
            return false
        end
        if this.CanMirrorById(object.id) == false then
            return false
        end
        return true
    end
    return false
end

---@param key string
---@return boolean
function this.ToggleMirror(key)
    key = key:lower()
    if config.leftPartFilter[key] == true then
        config.leftPartFilter[key] = false
    else
        config.leftPartFilter[key] = true
    end
    mwse.saveConfig(settings.configPath, config)
    return config.leftPartFilter[key]
end

function this.CalculateBounds(model)
    local bounds = model:createBoundingBox():copy()
    if config.display.recalculateBounds then
        -- vertex only bounds
        -- more tight bounds, but possible too heavy.
        logger:debug("prev bounds max: %s", bounds.max)
        logger:debug("prev bounds min: %s", bounds.min)
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
                -- FIXME Or calculations required to transform are still missing.
                -- In especially 'Tri chest' of 'The Imperfect'.
                -- worldBounds always seems correctly, but it's a sphere, lazy bounds. These need to be combined well.
                local center = node.worldBoundOrigin
                local radius = node.worldBoundRadius
                local threshold = radius * 2 -- FIXME In theory, it should fit within the radius, but often it does not. Allow for more margin.
                -- TODO distance squared
                -- boundingbox is some distance away from bounding sphere.
                if center:distance(max) > threshold or center:distance(min) > threshold then
                    logger:debug("use bounding sphere: %s", tostring(node.name))
                    logger:debug("origin %s, radius %f", node.worldBoundOrigin, node.worldBoundRadius)
                    logger:debug("world max %s, min %s, size %s, center %s, length %f", max, min, (max - min), ((max + min) * 0.5), (max - min):length())
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
    return bounds
end

return this
