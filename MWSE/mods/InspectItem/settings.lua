local this = {}
this.modName = "Inspect Item"
this.configPath = "InspectItem"
this.menuName = "InspectItem:MenuInspection"
this.returnButtonName = "InspectItem:ReturnButton"
this.returnEventName = "InspectItem:ReturnEvent"
this.i18n = mwse.loadTranslations("InspectItem")

---@class Config
local defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        keybind = {
            keyCode = tes3.scanCode.e --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = true,
        },
        sensitivityX = 1,
        sensitivityY = 1,
        sensitivityZ = 1,
        inversionX = false,
        inversionY = false,
        inversionZ = false,
    },
    target = {
        itemTile = true,
        -- inventry, barter, container, alchemy, enchant, item selector
        --lookAt = true,
        --hover = true,
    },
    display = {
        instruction = true,
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
