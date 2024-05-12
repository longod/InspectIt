local this = {}
this.modName = "Inspect It!"
this.configPath = "InspectIt"
this.guideMenu = "InspectIt:MenuInspection"
this.guideMenuID = tes3ui.registerID(this.guideMenu)
this.returnButtonName = "InspectIt:ReturnButton"
this.returnEventName = "InspectIt:ReturnEvent"
this.switchAnotherLookEventName = "InspectIt:SwitchAnotherLookEvent"
this.resetPoseEventName = "InspectIt:ResetPoseEvent"
this.i18n = mwse.loadTranslations("InspectIt")

---@return boolean
function this.OnOtherMenu()
    local top = tes3ui.getMenuOnTop()
    if top and top.id ~= this.guideMenuID then
        return true
    end
    return false
end

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
    inspection = {
        inventory = true,
        barter = true,
        contents = true,
        activatable = true,
        -- cursorover = true,
    },
    display = {
        instruction = true,
        bokeh = true,
        recalculateBounds = true,
        tooltipsComplete = true,
    },
    ---@class Config.Development
    development = {
        logLevel = "INFO",
        logToConsole = false,
    }
}

return this
