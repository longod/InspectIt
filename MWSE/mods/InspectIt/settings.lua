local this = {}
this.modName = "Inspect It!"
this.configPath = "InspectIt"
this.guideMenu = "InspectIt:MenuInspection"
this.returnButtonName = "InspectIt:ReturnButton"
this.returnEventName = "InspectIt:ReturnEvent"
this.switchAnotherLookEventName = "InspectIt:SwitchAnotherLookEvent"
this.resetPoseEventName = "InspectIt:ResetPoseEvent"
this.i18n = mwse.loadTranslations("InspectIt")

---@enum AnotherLookType
this.anotherLookType = {
    BodyParts = 1,
    WeaponSheathing = 2,
    Book = 3,
}

---@class Config
this.defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        inspect = {
            keyCode = tes3.scanCode.F2 --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
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
        -- logToConsole = false,
        -- test = false,
    }
}

return this
