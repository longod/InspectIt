local this = {}
this.modName = "Inspect Item"
this.configPath = "InspectItem"

---@class Config
local defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        keybind = {
            keyCode = tes3.scanCode.x --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        -- sensivility
    },
    target = {
        itemTile = true,
        -- inventry, barter, container, alchemy, enchant, item selector
        --lookAt = true,
        --hover = true,
    },
    vfx = {
        -- show guide ui
        bokeh = true,
        -- apply book and scroll, journal
    },
    ---@class Config.Development
    development = {
        logLevel = "INFO",
        logToConsole = false,
        -- test = false,
    }
}

---@return Config
function this.DefaultConfig()
    return table.deepcopy(defaultConfig)
end

return this
