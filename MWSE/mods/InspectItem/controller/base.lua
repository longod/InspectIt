---@class IController
---@field logger mwseLogger
local this = {}

---@class Activate.Params
---@field target tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon?

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

return this
