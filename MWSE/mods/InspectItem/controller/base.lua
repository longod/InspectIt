---@class IController
---@field logger mwseLogger
local this = {}

---@class BodyPartsData
---@field type tes3.activeBodyPart
---@field part tes3bodyPart

---@class WeaponSheathingData
---@field path string

---@class AnotherLookData
---@field type AnotherLookType?
---@field data BodyPartsData[]|WeaponSheathingData?

---@class Activate.Params
---@field target tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@field offset number
---@field another AnotherLookData

---@class Deactivate.Params
---@field menuExit boolean

---@protected
---@param params table?
---@return IController
function this.new(params)
    ---@type IController
    local instance = {
        logger = require("InspectItem.logger"),
    }
    if params then
        table.copymissing(instance, table.deepcopy(params))
    end
    setmetatable(instance, { __index = this })
    return instance
end

---@param self IController
---@param params Activate.Params
function this.Activate(self, params)
end

---@param self IController
---@param params Deactivate.Params
function this.Deactivate(self, params)
end

---@param self IController
function this.Reset(self)
end

return this
