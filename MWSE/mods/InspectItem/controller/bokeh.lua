local base = require("InspectItem.controller.base")

---@class Bokeh : IController
---@field shader mgeShaderHandle?
local this = {}
setmetatable(this, { __index = base })

---@type Bokeh
local defaults = {
    -- blur = 0,
    -- focalLength = 0,
}

local fx = "InspectItem/Bokeh"
local disabledShaders = { "Depth of Field" }

-- TODO focal length sync node translation

---@return Bokeh
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Bokeh

    return instance
end

---@param self Bokeh
---@param params Activate.Params
function this.Activate(self, params)
    if not self.shader then
        self.shader = mge.shaders.load({ name = fx })
        if self.shader then
            self.logger:info("Loaded shader: %s", fx)
        else
            self.logger:error("Failed to load shader: %s", fx)
        end
    end
    if self.shader then
        self.shader.enabled = true
    end
end

---@param self Bokeh
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.shader then
        self.shader.enabled = false
    end
end

return this
