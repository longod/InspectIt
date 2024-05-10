local config = require("InspectItem.config")
local logger = require("InspectItem.logger")
local settings = require("InspectItem.settings")

---@type IController[]
local controllers = {
    require("InspectItem.controller.renderer").new(),
    require("InspectItem.controller.bokeh").new(),
    require("InspectItem.controller.visibility").new(),
    require("InspectItem.controller.guide").new(),
    require("InspectItem.controller.menumode").new(),
    require("InspectItem.controller.inspector").new(),
}

--- listener
---@class Context
local context = {
    enable = false,
    target = nil, ---@type tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
    itemData = nil, ---@type tes3itemData?
}

---@param e itemTileUpdatedEventData
local function OnItemTileUpdated(e)
    -- or just tooltip callback
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


---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@param itemData tes3itemData?
---@return string?
local function FindTooltipsComplete(target, itemData)
    local tooltipData = include("Tooltips Complete.data")
    if not tooltipData then
        return nil
    end
    local config = mwse.loadConfig("tooltipsComplete")
    if not config then
        return nil
    end
    local mcmMapping = {
        { descriptionTable = tooltipData.keyTable,        mcm = "keyTooltips" },
        { descriptionTable = tooltipData.questTable,      mcm = "questTooltips" },
        { descriptionTable = tooltipData.uniqueTable,     mcm = "uniqueTooltips" },
        { descriptionTable = tooltipData.artifactTable,   mcm = "artifactTooltips" },
        { descriptionTable = tooltipData.armorTable,      mcm = "armorTooltips" },
        { descriptionTable = tooltipData.weaponTable,     mcm = "weaponTooltips" },
        { descriptionTable = tooltipData.toolTable,       mcm = "toolTooltips" },
        { descriptionTable = tooltipData.miscTable,       mcm = "miscTooltips" },
        { descriptionTable = tooltipData.bookTable,       mcm = "bookTooltips" },
        { descriptionTable = tooltipData.clothingTable,   mcm = "clothingTooltips" },
        { descriptionTable = tooltipData.soulgemTable,    mcm = "soulgemTooltips" },
        { descriptionTable = tooltipData.lightTable,      mcm = "lightTooltips" },
        { descriptionTable = tooltipData.potionTable,     mcm = "potionTooltips" },
        { descriptionTable = tooltipData.ingredientTable, mcm = "ingredientTooltips" },
        { descriptionTable = tooltipData.scrollTable,     mcm = "scrollTooltips" },
    }
    if config.menuOnly then
        -- return nil
    end

    local file = target.sourceMod
    if file and config.blocked[file:lower()] then
        return
    elseif config.blocked[target.id:lower()] then
        return
    end

    for _, data in ipairs(mcmMapping) do
        local description = data.descriptionTable[target.id:lower()]
        if config[data.mcm] and description then
            --soul gem item data
            if (target.isSoulGem and itemData and itemData.soul) then
                if config.blocked[itemData.soul.id:lower()] then
                    return description
                end
                if (itemData.soul.id == nil) then
                    return description
                end
                description = tooltipData.filledTable[itemData.soul.id:lower()] or ""
            end
            return description
        end
    end
    return nil
end

 ---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
 ---@return AnotherLookType? type
 ---@return BodyPartsData|WeaponSheathingData? data
local function FindAnotherLook(target)
    if target.objectType == tes3.objectType.armor or target.objectType == tes3.objectType.clothing then
        ---@cast target tes3armor|tes3clothing
        if tes3.player and tes3.player.object and target.parts then
            local female = tes3.player.object.female
            local parts = target.parts
            local bodyParts = {} ---@type BodyPartsData[]
            for index, ware in ipairs(parts) do
                -- target.isLeftPart
                -- Mara's shirt is wired
                local part = ware.male
                if female and ware.female then
                    part = ware.female
                end
                if part then
                    logger:debug(ware.type)
                    logger:debug(part.part)
                    logger:debug(part.partType)
                    logger:debug(part.mesh)
                    logger:debug(part.sceneNode)
                    local bp = tes3.player.bodyPartManager:getActiveBodyPartForItem(target)
                    -- logger:debug(part.sceneNode)
                    -- logger:debug(bp.node)
                    --logger:debug(bp.bodyPart.sceneNode)

                    -- animated?
                    local active = tes3.player.bodyPartManager:getActiveBodyPart(part.partType, ware.type)
                    logger:debug(active.node)
                    --logger:debug(active.bodyPart)
                    --logger:debug(active.bodyPart.sceneNode)


                    table.insert(bodyParts, { type = ware.type, part = part })
                end
            end
            if table.size(bodyParts) ~= 0 then
                local data = { parts = bodyParts } ---@type BodyPartsData
                return settings.anotherLookType.BodyParts, data
            end
        end
    end
    if target.objectType == tes3.objectType.weapon then
        local mesh = target.mesh
        if mesh then
            local sheathMesh = mesh:sub(1, -5) .. "_sh.nif"
            if tes3.getFileExists("meshes\\" .. sheathMesh) then
                logger:info("Find WeaponSheathing mesh: %s", sheathMesh)
                local data = { path = sheathMesh } ---@type WeaponSheathingData
                return settings.anotherLookType.WeaponSheathing, data
            end
        end
    end
    if target.objectType == tes3.objectType.book then
        ---@cast target tes3book
        -- Books with scripts are excluded because scripts are not executed when the book is opened.
        if not target.script then
            logger:info("Find book %d: %s", target.type, target.name)
            -- check owner?
            local data = { type = target.type, text = target.text }
            return settings.anotherLookType.Book, data
        end
    end
    return nil, nil
end

local function RegisterRightClickMenuExit()
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu({
            menuId = settings.menuName,
            buttonId = settings.returnButtonName,
        })
    end
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
        -- [tes3.objectType.birthsign] = true,
        [tes3.objectType.bodyPart] = true,
        [tes3.objectType.book] = true,
        -- [tes3.objectType.cell] = true,
        -- [tes3.objectType.class] = true,
        [tes3.objectType.clothing] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.creature] = true,
        -- [tes3.objectType.dialogue] = true,
        -- [tes3.objectType.dialogueInfo] = true,
        [tes3.objectType.door] = true,
        -- [tes3.objectType.enchantment] = true,
        -- [tes3.objectType.faction] = true,
        -- [tes3.objectType.gmst] = true,
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
        -- [tes3.objectType.pathGrid] = true,
        [tes3.objectType.probe] = true,
        -- [tes3.objectType.quest] = true,
        -- [tes3.objectType.race] = true,
        -- [tes3.objectType.reference] = true,
        -- [tes3.objectType.region] = true,
        [tes3.objectType.repairItem] = true,
        -- [tes3.objectType.script] = true,
        -- [tes3.objectType.skill] = true,
        -- [tes3.objectType.sound] = true,
        -- [tes3.objectType.soundGenerator] = true,
        -- [tes3.objectType.spell] = true,
        -- [tes3.objectType.startScript] = true,
        -- [tes3.objectType.static] = true,
        [tes3.objectType.weapon] = true,
    }

    return enabled[target.objectType] == true
end

---@param menuExit boolean
---@return boolean
local function LeaveInspection(menuExit)
    if context.enable then
        logger:info("Leave Inspection")
        for _, controller in ipairs(controllers) do
            controller:Deactivate({ menuExit = menuExit })
        end
        context.enable = false
        return true
    end
    return false
end


---@return boolean
local function EnterInspection()
    -- and more condition
    if context.enable or not CanInspection(context.target) then
        return false
    end
    logger:info("Enter Inspection: %s", context.target.name)

    local another, data = FindAnotherLook(context.target)
    local status, description = pcall(function() return FindTooltipsComplete(context.target, context.itemData) end)
    if not status then
        logger:error("Failed to call Tooltips Complete", tostring(description))
        description = nil
    end

    ---@type Activate.Params
    local params = { target = context.target, offset = 20, another = { type = another, data = data }, description = description }
    for _, controller in ipairs(controllers) do
        controller:Activate(params)
    end
    context.target = nil
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
    if TestInput(e, config.input.inspect) then
        if context.enable then
            if LeaveInspection(false) then
                tes3.worldController.menuClickSound:play() -- TODO controller
            end
        else
            if not context.target then
                if tes3.menuMode() then
                    -- TODO get cursor obj
                else
                    local ref = tes3.getPlayerTarget()
                    if ref and ref.object then -- and more conditions
                        context.target = ref.object
                    end
                end
            end

            if EnterInspection() then
                tes3.worldController.menuClickSound:play() -- TODO controller
            end
        end
        if context.enable then
            --e.claim = true
        end
    end
    if context.enable then
        if TestInput(e, config.input.another) then
            tes3.worldController.menuClickSound:play()
            event.trigger(settings.switchAnotherLookEventName)
        end
        if TestInput(e, config.input.reset) then
            tes3.worldController.menuClickSound:play()
            event.trigger(settings.resetPoseEventName)
        end
    end
end


---@param e menuExitEventData
local function OnMenuExit(e)
    -- fail-safe
    --LeaveInspection(true)
    if context.enable then
        logger:error("Not terminated")
    end
    context.target = nil
end

---@param e loadEventData
local function OnLoad(e)
    LeaveInspection(true)
    -- or deallocate
    for _, controller in ipairs(controllers) do
        controller:Reset()
    end
    context.target = nil
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

    RegisterRightClickMenuExit()

end

event.register(tes3.event.initialized, OnInitialized)

require("InspectItem.mcm")

--- @class tes3scriptVariables
