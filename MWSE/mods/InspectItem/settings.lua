local this = {}
this.modName = "Inspect Item"
this.configPath = "InspectItem"
this.menuName = "InspectItem:MenuInspection"
this.returnButtonName = "InspectItem:Return"

---@class Config
local defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        keybind = {
            keyCode = tes3.scanCode.e --[[@as tes3.scanCode]], -- examine
            isShiftDown = false,
            isAltDown = false,
            isControlDown = true,
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
