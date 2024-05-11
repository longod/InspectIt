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

 ---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
 ---@return AnotherLookType? type
 ---@return BodyPartsData|WeaponSheathingData? data
local function FindAnotherLook(target)
    if target.objectType == tes3.objectType.armor or target.objectType == tes3.objectType.clothing then
        -- Body Parts
        ---@cast target tes3armor|tes3clothing
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
            -- exclude in barter?
            logger:info("Find book %d: %s", target.type, target.name)
            -- check owner?
            local data = { type = target.type, text = target.text }
            return settings.anotherLookType.Book, data
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
        [tes3.objectType.bodyPart] = true,
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

---@param target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
---@param down boolean
local function PlayItemSound(target, down)
    if not target then
        return
    end
    -- TODO use Character Sound Overhaul data, but API is local.
    local axeFix = tes3.isModActive("Axe Sound ID Fix.esp")
    local downId = {
        [tes3.objectType.ammunition] = "Item Ammo Down",
        [tes3.objectType.apparatus] = "Item Apparatus Down",
        [tes3.objectType.armor] = {
            [tes3.armorWeightClass.light] = "Item Armor Light Down",
            [tes3.armorWeightClass.medium] = "Item Armor Medium Down",
            [tes3.armorWeightClass.heavy] = "Item Armor Heavy Down",
        },
        [tes3.objectType.bodyPart] = "Item Bodypart Down",
        [tes3.objectType.book] = "Item Book Down",
        [tes3.objectType.clothing] = {
            [tes3.clothingSlot.amulet] = "Item Ring Down",
            [tes3.clothingSlot.ring] = "Item Ring Down",
            ["falllback"] = "Item Clothes Down",
        },
        [tes3.objectType.miscItem] = {
            ["gold_001"] = "Item Gold Down",
            ["gold_005"] = "Item Gold Down",
            ["gold_010"] = "Item Gold Down",
            ["gold_025"] = "Item Gold Down",
            ["gold_100"] = "Item Gold Down",
            ["gold_dae_cursed_001"] = "Item Gold Down",
            ["gold_dae_cursed_005"] = "Item Gold Down",
            ["lucky_coin"] = "Item Gold Down",
            ["fallback"] = "Item Misc Down",
        },
        [tes3.objectType.ingredient] = "Item Ingredient Down",
        [tes3.objectType.lockpick] = "Item Lockpick Down",
        [tes3.objectType.alchemy] = "Item Potion Down",
        [tes3.objectType.probe] = "Item Probe Down",
        [tes3.objectType.repairItem] = "Item Repair Down",
        [tes3.objectType.weapon] = {
            [tes3.weaponType.shortBladeOneHand] = "Item Weapon Shortblade Down",
            [tes3.weaponType.longBladeOneHand] = "Item Weapon Longblade Down",
            [tes3.weaponType.longBladeTwoClose] = "Item Weapon Longblade Down",
            [tes3.weaponType.bluntOneHand] = "Item Weapon Blunt Down",
            [tes3.weaponType.bluntTwoClose] = "Item Weapon Blunt Down",
            [tes3.weaponType.bluntTwoWide] = "Item Weapon Blunt Down",
            [tes3.weaponType.spearTwoWide] = "Item Weapon Spear Down",
            [tes3.weaponType.axeOneHand] = axeFix and "Item Weapon Axe Down" or "Item Weapon Blunt Down",
            [tes3.weaponType.axeTwoHand] = axeFix and "Item Weapon Axe Down" or "Item Weapon Blunt Down",
            [tes3.weaponType.marksmanBow] = "Item Weapon Bow Down",
            [tes3.weaponType.marksmanCrossbow] = "Item Weapon Crossbow Down",
            --[tes3.weaponType.marksmanThrown] = "Item Weapon TEMP Down",
            --[tes3.weaponType.arrow] = "Item Weapon TEMP Down",
            --[tes3.weaponType.bolt] = "Item Weapon TEMP Down",
        },
    }
    local upId = {
        [tes3.objectType.ammunition] = "Item Ammo Up",
        [tes3.objectType.apparatus] = "Item Apparatus Up",
        [tes3.objectType.armor] = {
            [tes3.armorWeightClass.light] = "Item Armor Light Up",
            [tes3.armorWeightClass.medium] = "Item Armor Medium Up",
            [tes3.armorWeightClass.heavy] = "Item Armor Heavy Up",
        },
        [tes3.objectType.bodyPart] = "Item Bodypart Up",
        [tes3.objectType.book] = "Item Book Up",
        [tes3.objectType.clothing] = {
            [tes3.clothingSlot.amulet] = "Item Ring Up",
            [tes3.clothingSlot.ring] = "Item Ring Up",
            ["falllback"] = "Item Clothes Up",
        },
        [tes3.objectType.miscItem] = {
            ["gold_001"] = "Item Gold Up",
            ["gold_005"] = "Item Gold Up",
            ["gold_010"] = "Item Gold Up",
            ["gold_025"] = "Item Gold Up",
            ["gold_100"] = "Item Gold Up",
            ["gold_dae_cursed_001"] = "Item Gold Up",
            ["gold_dae_cursed_005"] = "Item Gold Up",
            ["fallback"] = "Item Misc Up",
        },
        [tes3.objectType.ingredient] = "Item Ingredient Up",
        [tes3.objectType.lockpick] = "Item Lockpick Up",
        [tes3.objectType.alchemy] = "Item Potion Up",
        [tes3.objectType.probe] = "Item Probe Up",
        [tes3.objectType.repairItem] = "Item Repair Up",
        [tes3.objectType.weapon] = {
            [tes3.weaponType.shortBladeOneHand] = "Item Weapon Shortblade Up",
            [tes3.weaponType.longBladeOneHand] = "Item Weapon Longblade Up",
            [tes3.weaponType.longBladeTwoClose] = "Item Weapon Longblade Up",
            [tes3.weaponType.bluntOneHand] = "Item Weapon Blunt Up",
            [tes3.weaponType.bluntTwoClose] = "Item Weapon Blunt Up",
            [tes3.weaponType.bluntTwoWide] = "Item Weapon Blunt Up",
            [tes3.weaponType.spearTwoWide] = "Item Weapon Spear Up",
            [tes3.weaponType.axeOneHand] = axeFix and "Item Weapon Axe Down" or "Item Weapon Blunt Up",
            [tes3.weaponType.axeTwoHand] = axeFix and "Item Weapon Axe Down" or "Item Weapon Blunt Up",
            [tes3.weaponType.marksmanBow] = "Item Weapon Bow Up",
            [tes3.weaponType.marksmanCrossbow] = "Item Weapon Crossbow Up",
            --[tes3.weaponType.marksmanThrown] = "Item Weapon TEMP Up",
            --[tes3.weaponType.arrow] = "Item Weapon TEMP Up",
            --[tes3.weaponType.bolt] = "Item Weapon TEMP Up",
        },
    }
    local primary = down and downId or upId
    local id = primary[target.objectType]
    if target.objectType == tes3.objectType.armor then
        ---@cast target tes3armor
        local sub = id[target.weightClass]
        if sub then
            id = sub
        end
    elseif target.objectType == tes3.objectType.clothing then
        ---@cast target tes3clothing
        local sub = id[target.slot]
        if sub then
            id = sub
        else
            id = id["fallback"]
        end
    elseif target.objectType == tes3.objectType.miscItem then
        ---@cast target tes3misc
        local sub = id[target.id:lower()]
        if sub then
            id = sub
        else
            id = id["fallback"]
        end
    elseif target.objectType == tes3.objectType.weapon then
        ---@cast target tes3weapon
        local sub = id[target.type]
        if sub then
            id = sub
        else
            id = id["fallback"]
        end
    end
    -- door has open/close sound
    if not id or type(id) == "table" then
        -- fallback
        return
    end
    logger:debug("play sound: %",id)
    local sound = tes3.getSound(id)
    sound:play()
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
    local status, description = pcall(function() return require("InspectIt.mod").FindTooltipsComplete(context.target, context.itemData) end)
    if not status then
        logger:error("Failed to call Tooltips Complete: %s", tostring(description))
        description = nil
    end

    ---@type Activate.Params
    local params = { target = context.target, offset = 20, another = { type = another, data = data }, description = description }
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
    if TestInput(e, config.input.inspect) then
        if context.enable then
            if LeaveInspection(false) then
                tes3.worldController.menuClickSound:play()
            end
        else
            if not context.target then
                if tes3.menuMode() then
                    -- TODO get cursor obj
                else
                    local ref = tes3.getPlayerTarget()
                    if ref and ref.object then -- and more conditions
                        context.target = ref.object
                        context.itemData = tes3.getAttachment(ref, "itemData") --[[@as tes3itemData?]]
                    end
                end
            end

            -- PlayItemSound(context.target, false)

            if EnterInspection() then
                tes3.worldController.menuClickSound:play()
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

---@param e menuExitEventData
local function OnMenuExit(e)
    -- fail-safe
    --LeaveInspection(true)
    if context.enable then
        logger:error("Not terminated")
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

event.register(tes3.event.initialized, OnInitialized)

require("InspectIt.mcm")

--- @class tes3scriptVariables
