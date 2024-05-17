local config = require("InspectIt.config")
local logger = require("InspectIt.logger")
local settings = require("InspectIt.settings")

---@type IController[]
local controllers = {
    require("InspectIt.controller.renderer").new(),
    require("InspectIt.controller.bokeh").new(),
    require("InspectIt.controller.visibility").new(),
    require("InspectIt.controller.guide").new(),
    require("InspectIt.controller.menumode").new(),
    require("InspectIt.controller.inspector").new(),
}

--- listener
---@class Context
local context = {
    enable = false,
    target = nil, ---@type tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
    itemData = nil, ---@type tes3itemData?
}

 ---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
 ---@param itemData tes3itemData?
 ---@return string?
 local function FindSoulName(object, itemData)
    if object.objectType == tes3.objectType.miscItem then
        ---@cast object tes3misc
        if object.isSoulGem and itemData and itemData.soul and itemData.soul.id then
            logger:debug("Find soul in item: %s", itemData.soul.name)
            return itemData.soul.name
        end
    end
    return nil
end

 ---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
 ---@return AnotherLookType? type
 ---@return BodyPartsData|WeaponSheathingData? data
local function FindAnotherLook(target)
    if target.objectType == tes3.objectType.armor or target.objectType == tes3.objectType.clothing then
        -- Body Parts
        ---@cast target tes3armor|tes3clothing
        --[[ -- TODO under researching
        if tes3.player and tes3.player.object and target.parts then
            local female = tes3.player.object.female -- depends on player
            local parts = target.parts
            local bodyParts = {} ---@type BodyPartsData[]
            for _, ware in ipairs(parts) do
                local part = ware.male
                if female and ware.female then
                    part = ware.female
                end
                if part then
                    table.insert(bodyParts, { type = ware.type, part = part })
                end
            end
            if table.size(bodyParts) ~= 0 then
                local data = { parts = bodyParts } ---@type BodyPartsData
                return settings.anotherLookType.BodyParts, data
            end
        end
        --]]
    elseif target.objectType == tes3.objectType.weapon then
        -- Weapon Sheathing
        local mesh = target.mesh
        if mesh then
            local sheathMesh = mesh:sub(1, -5) .. "_sh.nif"
            if tes3.getFileExists("meshes\\" .. sheathMesh) then
                logger:info("Find Weapon Sheathing mesh: %s", sheathMesh)
                local data = { path = sheathMesh } ---@type WeaponSheathingData
                return settings.anotherLookType.WeaponSheathing, data
            end
        end
    elseif target.objectType == tes3.objectType.book then
        -- Book or Scroll
        ---@cast target tes3book
        -- Books with scripts are excluded because scripts are not executed when the book is opened.
        if not target.script then
            if target.text then
                -- exclude in barter? check owner?
                logger:debug("Find book or scroll contents")
                local data = { type = target.type, text = target.text }
                return settings.anotherLookType.Book, data
            end
        else
            logger:debug("%s, book or scroll has a sciprt: %s", target.name, tostring(target.script.id))
        end
    end
    return nil, nil
end


 ---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
 ---@return boolean
local function CanInspection(target)
    if not target then
        return false
    end
    local enabled = {
        [tes3.objectType.activator] = true,
        [tes3.objectType.alchemy] = true,
        [tes3.objectType.ammunition] = true,
        [tes3.objectType.apparatus] = true,
        [tes3.objectType.armor] = true,
        -- [tes3.objectType.bodyPart] = true,
        [tes3.objectType.book] = true,
        -- [tes3.objectType.cell] = true,
        [tes3.objectType.clothing] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.creature] = true,
        [tes3.objectType.door] = true,
        -- [tes3.objectType.enchantment] = true,
        [tes3.objectType.ingredient] = true,
        -- [tes3.objectType.land] = true,
        -- [tes3.objectType.landTexture] = true,
        -- [tes3.objectType.leveledCreature] = true,
        -- [tes3.objectType.leveledItem] = true,
        [tes3.objectType.light] = true,
        [tes3.objectType.lockpick] = true,
        -- [tes3.objectType.magicEffect] = true,
        [tes3.objectType.miscItem] = true,
        -- [tes3.objectType.mobileActor] = true,
        -- [tes3.objectType.mobileCreature] = true,
        -- [tes3.objectType.mobileNPC] = true,
        -- [tes3.objectType.mobilePlayer] = true,
        -- [tes3.objectType.mobileProjectile] = true,
        -- [tes3.objectType.mobileSpellProjectile] = true,
        [tes3.objectType.npc] = false, -- TODO NPC needs to resolve body parts
        [tes3.objectType.probe] = true,
        -- [tes3.objectType.reference] = true,
        -- [tes3.objectType.region] = true,
        [tes3.objectType.repairItem] = true,
        -- [tes3.objectType.spell] = true,
        -- [tes3.objectType.static] = true,
        [tes3.objectType.weapon] = true,
    }

    return enabled[target.objectType] == true
end

---@param menuExit boolean
---@return boolean
local function LeaveInspection(menuExit)
    if context.enable then
        context.enable = false
        logger:info("Leave Inspection")
        for _, controller in ipairs(controllers) do
            controller:Deactivate({ menuExit = menuExit })
        end
        return true
    end
    return false
end

---@return boolean
local function EnterInspection()
    if context.enable or not context.target then
        context.target = nil
        context.itemData = nil
        return false
    end
    if not CanInspection(context.target) then
        logger:info("Unsupported Inspection: %s", context.target.name)
        tes3.messageBox(settings.i18n("messageBox.unsupport.text", { modName = settings.modName }))
        context.target = nil
        context.itemData = nil
        return false
    end
    -- when picking a item
    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        local tile = cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile then
            context.target = nil
            context.itemData = nil
            return false
        end
    end

    local name = context.target.name
    local soul = FindSoulName(context.target, context.itemData)
    if soul then
        name = string.format("%s (%s)", name, soul)
    end

    local another, data = FindAnotherLook(context.target)
    local status, description = pcall(function() return require("InspectIt.mod").FindTooltipsComplete(context.target, context.itemData) end)
    if not status then
        logger:error("Failed to call Tooltips Complete: %s", tostring(description))
        description = nil
    elseif description then
        if type(description) == "string" then
            logger:debug("Find description from Tooltips Complete")
        else
            logger:warn("Invalid data from Tooltips Complete")
            description = nil
        end
    end

    logger:info("Enter Inspection: %s", context.target.name)

    ---@type Activate.Params
    local params = { target = context.target, offset = 20, another = { type = another, data = data }, description = description, name = name }
    for _, controller in ipairs(controllers) do
        controller:Activate(params)
    end
    context.target = nil
    context.itemData = nil
    context.enable = true
    return true
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

    if context.enable then
        if settings.OnOtherMenu() then
            -- pause
        else
            if TestInput(e, config.input.inspect) then
                if LeaveInspection(false) then
                    tes3.worldController.menuClickSound:play()
                end
            end
            if TestInput(e, config.input.another) then
                -- Sound is played even when another does not exist.
                -- if not config.inspection.playItemSound then
                --     tes3.worldController.menuClickSound:play()
                -- end
                event.trigger(settings.switchAnotherLookEventName)
            end
            if TestInput(e, config.input.reset) then
                tes3.worldController.menuClickSound:play()
                event.trigger(settings.resetPoseEventName)
            end
        end
    else
        if TestInput(e, config.input.inspect) then
            if not context.target then
                if tes3.menuMode() then
                    -- get cursor obj
                    --[[
                    local cameraData = tes3.worldController.worldCamera.cameraData
                    local fovX = mge.camera.fov or cameraData.fov
                    local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth
                    local tan = math.tan(math.rad(fovX) * 0.5)
                    local cursor = tes3.getCursorPosition():copy()
                    local ndcPos = tes3vector2.new(cursor.x / cameraData.viewportWidth * 2, cursor.y / cameraData.viewportHeight * 2)
                    --logger:debug("ndcPos: %s", ndcPos)
                    -- TODO we need the inversed projection!
                    --logger:debug("world dir: %s", worldDir)
                    -- local eyeDir = tes3.getPlayerEyeVector()
                    -- eyeDir:normalize()
                    -- logger:debug("eye dir: %s", eyeDir)
                    -- logger:debug("eye pos: %s", eyePos)
                    local eyePos = tes3.getPlayerEyePosition()
                    local distance = tes3.getPlayerActivationDistance()
                    -- local hit = tes3.rayTest({ position = eyePos, direction = worldDir, maxDistance = distance })
                    -- if hit and hit.reference then
                    --     tes3.messageBox(hit.reference.object.name)
                    -- end
                    --]]
                else
                    if config.inspection.activatable then
                        local ref = tes3.getPlayerTarget()
                        if ref and ref.object then
                            context.target = ref.object
                            context.itemData = tes3.getAttachment(ref, "itemData") --[[@as tes3itemData?]]
                        end
                    end
                end
            end
            if EnterInspection() then
                tes3.worldController.menuClickSound:play()
            end
        end
        if context.enable then
            --e.claim = true
        end
    end
end

---@param e itemTileUpdatedEventData
local function OnItemTileUpdated(e)
    if not e.menu then
        return
    end
    local allowed = {
        ["MenuInventory"] = config.inspection.inventory,
        ["MenuBarter"] = config.inspection.barter,
        ["MenuContents"] = config.inspection.contents,
    }
    if not allowed[e.menu.name] then
        -- Selector does not seem to trigger, but even if it does not exist, it is ignored.
        return
    end

    e.element:registerAfter(tes3.uiEvent.mouseOver,
        ---@param ev tes3uiEventData
        function(ev)
            context.target = e.item
            context.itemData = e.itemData
        end)
    e.element:registerAfter(tes3.uiEvent.mouseLeave,
        ---@param ev tes3uiEventData
        function(ev)
            if context.target then
                context.target = nil
                context.itemData = nil
            end
        end)
end

---@param e menuExitEventData
local function OnMenuExit(e)
    -- fail-safe
    if context.enable then
        logger:error("Inspection was not terminated")
        LeaveInspection(true)
    end
    context.target = nil
    context.itemData = nil
end

---@param e loadEventData
local function OnLoad(e)
    LeaveInspection(true)
    -- or deallocate
    for _, controller in ipairs(controllers) do
        controller:Reset()
    end
    context.target = nil
    context.itemData = nil
end

local function OnInitialized()
    event.register(tes3.event.itemTileUpdated, OnItemTileUpdated)
    event.register(tes3.event.keyDown, OnKeyDown, { priority = 0 })
    event.register(tes3.event.menuExit, OnMenuExit)
    event.register(tes3.event.load, OnLoad)

    -- menu event
    event.register(settings.returnEventName,
    function(_)
        LeaveInspection(false)
    end)

    require("InspectIt.mod").RegisterRightClickMenuExit()
end

if mge.enabled() then
    event.register(tes3.event.initialized, OnInitialized)
else
    logger:error("This mod requires MGE XE to be enabled.")
end

require("InspectIt.mcm")

--- @class tes3scriptVariables
