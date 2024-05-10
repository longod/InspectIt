local this = {}
this.modName = "Inspect It!"
this.configPath = "InspectItem"
this.menuName = "InspectItem:MenuInspection"
this.helpLayerName = "InspectItem:MenuInspectionDescription"
this.returnButtonName = "InspectItem:ReturnButton"
this.returnEventName = "InspectItem:ReturnEvent"
this.switchAnotherLookEventName = "InspectItem:SwitchAnotherLookEvent"
this.resetPoseEventName = "InspectItem:ResetPoseEvent"
this.i18n = mwse.loadTranslations("InspectItem")

---@enum AnotherLookType
this.anotherLookType = {
    BodyParts = 1,
    WeaponSheathing = 2,
    Book = 3,
}

---@class Config
local defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        inspect = {
            keyCode = tes3.scanCode.tab --[[@as tes3.scanCode]],
            isShiftDown = true,
            isAltDown = true,
            isControlDown = false,
        },
        ---@type mwseKeyCombo
        another = {
            keyCode = tes3.scanCode.s --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        ---@type mwseKeyCombo
        reset = {
            keyCode = tes3.scanCode.r --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        sensitivityX = 1,
        sensitivityY = 1,
        sensitivityZ = 1,
        inversionX = false,
        inversionY = false,
        inversionZ = false,
    },
    target = {
        item = true,
        activation = true,
        -- hover = true
        -- inventry, barter, container, alchemy, enchant, item selector
    },
    display = {
        instruction = true,
        bokeh = true,
        tooltipsComplete = true,
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
