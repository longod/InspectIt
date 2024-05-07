local base = require("InspectItem.controller.base")

---@class Visibility : IController
---@field visibility {[string] : boolean}
local this = {}
setmetatable(this, { __index = base })

---@type Visibility
local defaults = {
    visibility = {},
}

local menus = {
    "MenuAlchemy", --
    "MenuAttributes", --
    -- "MenuAttributesList", -- Enchanting/spellmaking effect attribute
    -- "MenuAudio", -- Options, audio
    "MenuBarter", --
    -- "MenuBirthSign", --
    "MenuBook", --
    -- "MenuChooseClass", --
    -- "MenuClassChoice", --
    -- "MenuClassMessage", --
    -- "MenuConsole", --
    "MenuContents", -- Container/NPC inventory
    -- "MenuCreateClass", --
    -- "MenuCtrls", -- Options, controls
    -- "MenuDialog", --
    "MenuEnchantment", --
    -- "MenuInput", --
    -- "MenuInputSave", --
    "MenuInventory", -- Player inventory
    "MenuInventorySelect", -- Item selector
    "MenuJournal", --
    -- "MenuLevelUp", --
    -- "MenuLoad", --
    -- "MenuLoading", --
    "MenuMagic", -- Spell/enchanted item selector
    -- "MenuMagicSelect", --
    "MenuMap", --
    -- "MenuMapNoteEdit", --
    -- "MenuMessage", --
    -- "MenuMulti", -- Status bars, current weapon/magic, active effects and minimap
    -- "MenuName", --
    -- "MenuNotify1", --
    -- "MenuNotify2", --
    -- "MenuNotify3", --
    -- "MenuOptions", -- Main menu
    -- "MenuPersuasion", --
    -- "MenuPrefs", -- Options, preferences
    -- "MenuQuantity", --
    -- "MenuQuick", -- Quick keys
    -- "MenuRaceSex", --
    "MenuRepair", --
    -- "MenuRestWait", --
    -- "MenuSave", --
    -- "MenuScroll", --
    "MenuServiceRepair", --
    "MenuServiceSpells", --
    -- "MenuServiceTraining", --
    -- "MenuServiceTravel", --
    -- "MenuSetValues", -- Enchanting/spellmaking effect values
    "MenuSkills", --
    -- "MenuSkillsList", -- Enchanting/spellmaking effect skill
    "MenuSpecialization", --
    "MenuSpellmaking", --
    "MenuStat", -- Player attributes, skills, factions etc.
    -- "MenuStatReview", --
    -- "MenuSwimFillBar", --
    -- "MenuTimePass", --
    -- "MenuTopic", --
    -- "MenuVideo", -- Options, video
}

---@return Visibility
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Visibility

    return instance
end

---@param self Visibility
---@param params Activate.Params
function this.Activate(self, params)
    tes3ui.suppressTooltip(true)
    for _, menu in ipairs(menus) do
        local element = tes3ui.findMenu(menu)
        if element and element.visible == true then
            self.logger:debug("[Activate] Menu %s visibility %s to false", menu, tostring(element.visible))
            element.visible = false
            self.visibility[menu] = true
        else
            self.visibility[menu] = false
        end
    end
end

---@param self Visibility
---@param params Deactivate.Params
function this.Deactivate(self, params)
    tes3ui.suppressTooltip(false)
    if not params.menuExit then
        for menu, value in pairs(self.visibility) do
            if value then
                local element = tes3ui.findMenu(menu)
                if element then
                    self.logger:debug("[Deactivate] Menu %s visibility %s to true", menu, tostring(element.visible))
                    element.visible = true
                end
            end
        end
    end
end

---@param self Visibility
function this.Reset(self)
    self.visibility = {}
end

return this
