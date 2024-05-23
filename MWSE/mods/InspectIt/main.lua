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

 ---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
 ---@return AnotherLookType? type
 ---@return BodyPartsData|WeaponSheathingData? data
local function FindAnotherLook(object)
    if object.objectType == tes3.objectType.armor or object.objectType == tes3.objectType.clothing then
        -- Body Parts
        ---@cast object tes3armor|tes3clothing
        --[[ -- TODO under researching
        if tes3.player and tes3.player.object and object.parts then
            local female = tes3.player.object.female -- depends on player
            local parts = object.parts
            local bodyParts = {} ---@type BodyParts[]
            for _, ware in ipairs(parts) do
                local part = ware.male
                if female and ware.female then
                    part = ware.female
                end
                if part then
                    local data = { type = ware.type, part = part }
                    table.insert(bodyParts, data)
                end
            end
            local count = table.size(bodyParts)
            if count > 0 then
                -- same mesh (shield)
                -- or just shield, helms
                if count == 1 and bodyParts[1].part.mesh == object.mesh then
                    logger:debug("A bodypart is same mesh as object: %s", object.mesh)
                    return nil, nil
                end
                logger:debug("Find bodyparts %d", count)
                local data = { parts = bodyParts } ---@type BodyPartsData
                return settings.anotherLookType.BodyParts, data
            end
        end
        --]]
    elseif object.objectType == tes3.objectType.weapon then
        -- Weapon Sheathing
        local sheathMesh = require("InspectIt.mod").FindWeaponSheathingMesh(object.mesh)
        if sheathMesh then
            logger:info("Find Weapon Sheathing mesh: %s", sheathMesh)
            local data = { path = sheathMesh } ---@type WeaponSheathingData
            return settings.anotherLookType.WeaponSheathing, data
        end
    elseif object.objectType == tes3.objectType.book then
        -- Book or Scroll
        ---@cast object tes3book
        -- Books with scripts are excluded because scripts are not executed when the book is opened.
        if not object.script then
            if object.text then
                -- exclude in barter? check owner?
                logger:debug("Find book or scroll contents")
                local data = { type = object.type, text = object.text }
                return settings.anotherLookType.Book, data
            end
        else
            -- TODO message box if need
            logger:debug("%s, book or scroll has a sciprt: %s", object.name, tostring(object.script.id))
        end
    end
    return nil, nil
end


---@param params EnterParams
---@return niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode?
local function FindReferenceNode(params)
    -- only npc
    if params.reference and params.object.objectType == tes3.objectType.npc then
        return params.reference.sceneNode
    end
    return nil
end

 ---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
 ---@return boolean? can nil is implicitly NO.
local function CanInspection(object)
    if not object then
        return nil
    end
    if config.development.experimental then
        return true
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
        [tes3.objectType.npc] = true,
        [tes3.objectType.probe] = true,
        -- [tes3.objectType.reference] = true,
        -- [tes3.objectType.region] = true,
        [tes3.objectType.repairItem] = true,
        -- [tes3.objectType.spell] = true,
        -- [tes3.objectType.static] = true,
        [tes3.objectType.weapon] = true,
    }

    return enabled[object.objectType]
end

---@param menuExit boolean
local function LeaveInspection(menuExit)
    logger:info("Leave Inspection")
    for _, controller in ipairs(controllers) do
        controller:Deactivate({ menuExit = menuExit })
    end
end

---@class EnterParams
---@field object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
---@field itemData tes3itemData?
---@field reference tes3reference?

---@param params EnterParams
---@return boolean
local function EnterInspection(params)
    if not params.object then
        return false
    end
    local can = CanInspection(params.object)
    if not can then
        logger:info("Unsupported Inspection: %s", params.object.name)
        if can == false then
            tes3.messageBox(settings.i18n("messageBox.unsupport.text", { modName = settings.modName }))
        end
        return false
    end
    -- when picking a item
    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        local tile = cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile then
            return false
        end
    end

    local name = params.object.name
    -- resolve soul suffix or can get anywhere?
    local soul = FindSoulName(params.object, params.itemData)
    if soul then
        name = string.format("%s (%s)", name, soul)
    end

    local another, data = FindAnotherLook(params.object)
    local status, description = pcall(function() return require("InspectIt.mod").FindTooltipsComplete(params.object, params.itemData) end)
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

    local referenceNode = FindReferenceNode(params)


    logger:info("Enter Inspection: %s (%s)", params.object.name, params.object.id)

    ---@type Activate.Params
    local args = { object = params.object, offset = 20, another = { type = another, data = data }, description = description, name = name, referenceNode = referenceNode }
    for _, controller in ipairs(controllers) do
        controller:Activate(args)
    end
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

-- TODO I'm sure there's a smarter way, but I can't find a way.
---@return boolean
local function CanSelectByCursor()
    -- Only when it is possible to activate outside objects with the cursor on the inventory screen.
    -- Right-click menu, containers
    local allowed = {
        ["MenuContents"] = true, -- Container/NPC inventory
        ["MenuInventory"] = true, -- Player inventory
        ["MenuMulti"] = true, -- Status bars, current weapon/magic, active effects and minimap
        ["MenuMagic"] = true, -- Spell/enchanted item selector
        ["MenuMap"] = true, --
        ["MenuStat"] = true, -- Player attributes, skills, factions etc.
    }
    -- focus may come to the inventory, but it is impossible.
    local denied = {
        "MenuBarter",
    }
    -- TODO registered id
    local top = tes3ui.getMenuOnTop()
    if top and top.visible and allowed[top.name] == true then
        for _, name in ipairs(denied) do
            if tes3ui.findMenu(name) ~= nil then
                return false
            end
        end
        return true
    end
    return false
end

--- listener
---@class Context
local context = {
    enable = false,
    object = nil, ---@type tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
    itemData = nil, ---@type tes3itemData?
}

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
                context.enable = false
                LeaveInspection(false)
                tes3.worldController.menuClickSound:play()
            elseif TestInput(e, config.input.another) then
                -- Sound is played even when another does not exist.
                event.trigger(settings.switchAnotherLookEventName)
            elseif TestInput(e, config.input.lighting) then
                event.trigger(settings.switchLightingEventName)
                tes3.worldController.menuClickSound:play()
            elseif TestInput(e, config.input.reset) then
                event.trigger(settings.resetPoseEventName)
                tes3.worldController.menuClickSound:play()
            end
        end
    else
        if TestInput(e, config.input.inspect) then
            local reference = nil ---@type tes3reference?
            if not context.object then
                if tes3.menuMode() then
                    -- menu cursor
                    if config.inspection.cursorOver and CanSelectByCursor() then
                        local cursor = tes3.getCursorPosition()
                        local camera = tes3.worldController.worldCamera.cameraData.camera
                        local position, direction = camera:windowPointToRay({ cursor.x, cursor.y })
                        -- world root? ignore ui?
                        local hit = tes3.rayTest({
                            position = position,
                            direction = direction,
                            --ignore = { tes3.player },
                            maxDistance = tes3.getPlayerActivationDistance(),
                            -- accurateSkinned = true
                        })
                        -- hit non activatable objects...
                        if hit and hit.reference then
                            logger:debug("Hit: %s", hit.reference.id)
                            reference = hit.reference
                            context.object = reference.object
                            context.itemData = tes3.getAttachment(reference, "itemData") --[[@as tes3itemData?]]
                        end
                    end
                else
                    -- in game
                    if config.inspection.activatable then
                        local ref = tes3.getPlayerTarget()
                        if ref and ref.object then
                            reference = ref
                            context.object = reference.object
                            context.itemData = tes3.getAttachment(reference, "itemData") --[[@as tes3itemData?]]
                        elseif config.development.experimental then
                            local hit = tes3.rayTest({
                                position = tes3.getCameraPosition(), -- whitch better? player eye
                                direction = tes3.getCameraVector(),
                                ignore = { tes3.player }, -- for no offseted TPV
                                maxDistance = tes3.getPlayerActivationDistance(),
                            })
                            if hit and hit.reference then
                                logger:debug("Hit: %s", hit.reference.id)
                                reference = hit.reference
                                context.object = reference.object
                                context.itemData = tes3.getAttachment(reference, "itemData") --[[@as tes3itemData?]]
                            end
                        end
                    end
                end
            end
            if EnterInspection({ object = context.object, itemData = context.itemData, reference = reference }) then
                context.enable = true
                tes3.worldController.menuClickSound:play()
            end
            -- reset
            context.object = nil
            context.itemData = nil
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
            context.object = e.item
            context.itemData = e.itemData
        end)
    e.element:registerAfter(tes3.uiEvent.mouseLeave,
        ---@param ev tes3uiEventData
        function(ev)
            if context.object then
                context.object = nil
                context.itemData = nil
            end
        end)
end

---@param e menuExitEventData
local function OnMenuExit(e)
    -- fail-safe
    if context.enable then
        logger:error("Inspection was not terminated")
        context.enable = false
        LeaveInspection(true)
    end
    context.object = nil
    context.itemData = nil
end

---@param e loadEventData
local function OnLoad(e)
    if context.enable then
        context.enable = false
        LeaveInspection(true)
    end
    -- or deallocate
    for _, controller in ipairs(controllers) do
        controller:Reset()
    end
    context.object = nil
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
        if context.enable then
            context.enable = false
            LeaveInspection(false)
        end
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
