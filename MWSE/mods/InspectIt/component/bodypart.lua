---@class BodyPartResolver
local this = {}
local mesh = require("InspectIt.component.mesh")
local logger = require("InspectIt.logger")

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
    [tes3.activeBodyPart.rightHand]     = { name = "Right Hand", isLeft = false },
    [tes3.activeBodyPart.leftHand]      = { name = "Left Hand", isLeft = true },
    [tes3.activeBodyPart.rightWrist]    = { name = "Right Wrist", isLeft = false },
    [tes3.activeBodyPart.leftWrist]     = { name = "Left Wrist", isLeft = true },
    [tes3.activeBodyPart.shield]        = { name = "Shield Bone", },
    [tes3.activeBodyPart.rightForearm]  = { name = "Right Forearm", isLeft = false },
    [tes3.activeBodyPart.leftForearm]   = { name = "Left Forearm", isLeft = true },
    [tes3.activeBodyPart.rightUpperArm] = { name = "Right Upper Arm", isLeft = false },
    [tes3.activeBodyPart.leftUpperArm]  = { name = "Left Upper Arm", isLeft = true },
    [tes3.activeBodyPart.rightFoot]     = { name = "Right Foot", isLeft = false },
    [tes3.activeBodyPart.leftFoot]      = { name = "Left Foot", isLeft = true },
    [tes3.activeBodyPart.rightAnkle]    = { name = "Right Ankle", isLeft = false },
    [tes3.activeBodyPart.leftAnkle]     = { name = "Left Ankle", isLeft = true },
    [tes3.activeBodyPart.rightKnee]     = { name = "Right Knee", isLeft = false },
    [tes3.activeBodyPart.leftKnee]      = { name = "Left Knee", isLeft = true },
    [tes3.activeBodyPart.rightUpperLeg] = { name = "Right Upper Leg", isLeft = false },
    [tes3.activeBodyPart.leftUpperLeg]  = { name = "Left Upper Leg", isLeft = true },
    [tes3.activeBodyPart.rightPauldron] = { name = "Right Clavicle", isLeft = false },
    [tes3.activeBodyPart.leftPauldron]  = { name = "Left Clavicle", isLeft = true },
    [tes3.activeBodyPart.weapon]        = { name = "Weapon Bone", }, -- the real node name depends on the current weapon type.
    [tes3.activeBodyPart.tail]          = { name = "Tail" },
}

---@deprecated
---@param bodypart BodyPart
---@param root niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
function  this.SetBodyPart(bodypart, root)
    local part = bodypart.part
    local socket = sockets[bodypart.type]
    if not socket then
        logger:error("Not find activeBodyPart %d, %s", bodypart.type, bodypart.part.id)
        return
    end
    logger:debug("Load bodypart mesh : %s", part.mesh)
    if not tes3.getFileExists(string.format("Meshes\\%s", part.mesh)) then
        logger:error("Not exist mesh: %s", part.mesh)
        return
    end
    local model = tes3.loadMesh(part.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

    local to = root:getObjectByName(socket.name) --[[@as niNode]]
    if not to then
        logger:error("Not find to attach to %s", socket.name)
        return
    end

    local opposite = nil ---@type string?
    if socket.isLeft ~=nil then
        opposite = "tri " .. ((socket.isLeft == true) and "right" or "left")
    end

    -- skin parent node
    local skinNode = nil ---@type niNode?

    -- FIXME It's not exact emulation.
    mesh.foreach(model, function(node, _)
        if node:isInstanceOfType(ni.type.NiTriShape) then
            if opposite and node.name and node.name:lower():startswith(opposite) then
                -- ignore opposite part
                logger:trace("%s ignore by %s", node.name, tostring(opposite))
                return
            end
            if node.skinInstance then
                if not skinNode then
                    skinNode = niNode.new()
                    skinNode.name = socket.name
                end
                skinNode:attachChild(node)
                for index, bone in ipairs(node.skinInstance.bones) do
                    node.skinInstance.bones[index] = root:getObjectByName(bone.name)
                end
                node.skinInstance.root = skinNode
            else
                --  transofrm is keep?

                -- In the case of vanilla, this seems to be fine without it because it is used as light sources...
                local offsetNode = model:getObjectByName("BoneOffset")
                if offsetNode then
                    logger:trace("BoneOffset: %s", offsetNode.translation)
                    node.translation = offsetNode.translation:copy() -- copy to trishape? parent node?
                end

                -- resolve left
                if socket.isLeft == true then
                    -- non uniform scale
                    local mirror = tes3matrix33.new(
                        -1, 0, 0,
                        0, 1, 0,
                        0, 0, 1
                    )
                    -- need keep original rotation?
                    local rotation = node.rotation:copy()
                    --model.rotation = rotation:copy() * mirror:copy()
                    node.rotation = mirror:copy() * rotation:copy()
                    -- need transofrm translation?
                    local t = node.translation:copy()
                    node.translation = mirror:copy() * t:copy()
                end

                to:attachChild(node)
            end
        end
    end)

    -- Skins should be grouped under the root.
    if skinNode then
        root:attachChild(skinNode)
    end

end

---@param bodypart BodyPart
---@param root niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
function this.BuildBodyPart(bodypart, root)
    local part = bodypart.part
    local socket = sockets[bodypart.type]
    if not socket then
        logger:error("Not find activeBodyPart %d, %s", bodypart.type, bodypart.part.id)
        return
    end
    logger:debug("Load bodypart mesh: %s", part.mesh)
    if not tes3.getFileExists(string.format("Meshes\\%s", part.mesh)) then
        logger:error("Not exist mesh: %s", part.mesh)
        return
    end
    local model = tes3.loadMesh(part.mesh, false):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

    local to = root:getObjectByName(socket.name) --[[@as niNode]]
    if not to then
        logger:error("Not find to attach to %s", socket.name)
        return
    end

    local from = model:getObjectByName(socket.name) --[[@as niNode]]
    if not from then
        -- In the case of nonskin, the ninode may not have the same name or only trishape is in the root
        if model:isOfType(ni.type.NiNode) then
            from = model
            from.name = socket.name -- FIXME rename attach name, skirt is not groin, its skirt.
        else
            from = niNode.new()
            from.name = socket.name -- rename
            from:attachChild(model)
        end
    end

    local skin = false
    mesh.foreach(from, function(node, _)
        if node:isInstanceOfType(ni.type.NiTriShape) then
            if node.skinInstance then
                -- sometime crash..
                skin = true
                if node.skinInstance.root ~= nil then
                    --node.skinInstance.root = node.parent
                    node.skinInstance.root = root
                end
                if node.skinInstance.bones ~= nil then
                    for index, bone in ipairs(node.skinInstance.bones) do
                        if bone ~= nil and bone.name ~= nil then
                            node.skinInstance.bones[index] = root:getObjectByName(bone.name)
                        end
                    end
                end
            end
        end
    end)
    if skin then
        from:clearTransforms()
        root:attachChild(from)
    else
        if socket.isLeft == true then
            from.rotation = tes3matrix33.new(
                -1, 0, 0,
                0, 1, 0,
                0, 0, 1
            )
            local parent = niNode.new() -- BSMirroredNode
            parent.name = from.name
            from.name = "Mirrored"
            -- non uniform scale
            parent:attachChild(from)
            from = parent
        end
        from:copyTransforms(to)
        -- untested
        -- In the case of vanilla, this seems to be fine without it because it is used as light sources...
        local offset = model:getObjectByName("BoneOffset")
        if offset then
            logger:trace("BoneOffset: %s", offset.translation)
            from.translation = from.translation:copy() + offset.translation:copy()
        end
        to.parent:attachChild(from)
    end
    -- remove original bone
    to.parent:detachChild(to)

end

return this
