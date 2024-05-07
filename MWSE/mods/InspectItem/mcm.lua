--- @param e modConfigReadyEventData
local function OnModConfigReady(e)
    local config = require("InspectItem.config")
    local settings = require("InspectItem.settings")
    local template = mwse.mcm.createTemplate(settings.modName)
    template:saveOnClose(settings.configPath, config)
    template:register()

    local page = template:createSideBarPage({
        label = settings.modName,
    })
    page.sidebar:createInfo({
        text = settings.i18n("mcm.sidebar.info")
    })

    do
        local input = page:createCategory({
            label = settings.i18n("mcm.input.category.label"),
            description = settings.i18n("mcm.input.category.description"),
        })
        input:createKeyBinder({
            label = settings.i18n("mcm.input.category.label"),
            description = settings.i18n("mcm.input.category.description"),
            variable = mwse.mcm.createTableVariable({
                id = "keybind",
                table = config.input,
            }),
            allowCombinations = true,
            allowMouse = false,
        })

        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityX.label"),
            description = settings.i18n("mcm.input.sensitivityX.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityX",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityY.label"),
            description = settings.i18n("mcm.input.sensitivityY.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityY",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityZ.label"),
            description = settings.i18n("mcm.input.sensitivityZ.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityZ",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionX.label"),
            description = settings.i18n("mcm.input.inversionX.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionX",
                table = config.input,
            }),
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionY.label"),
            description = settings.i18n("mcm.input.inversionY.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionY",
                table = config.input,
            }),
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionZ.label"),
            description = settings.i18n("mcm.input.inversionZ.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionZ",
                table = config.input,
            }),
        })
    end
    do
        local display = page:createCategory({
            label = settings.i18n("mcm.display.category.label"),
            description = settings.i18n("mcm.display.category.description"),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.instruction.label"),
            description = settings.i18n("mcm.display.instruction.description"),
            variable = mwse.mcm.createTableVariable({
                id = "instruction",
                table = config.display,
            }),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.bokeh.label"),
            description = settings.i18n("mcm.display.bokeh.description"),
            variable = mwse.mcm.createTableVariable({
                id = "bokeh",
                table = config.display,
            }),
        })
    end
    do
        local dev = page:createCategory({
            label = settings.i18n("mcm.development.category.label"),
            description = settings.i18n("mcm.development.category.description"),
        })
        dev:createDropdown({
            label = settings.i18n("mcm.development.logLevel.label"),
            description = settings.i18n("mcm.development.logLevel.description"),
            options = {
                { label = "TRACE", value = "TRACE" },
                { label = "DEBUG", value = "DEBUG" },
                { label = "INFO",  value = "INFO" },
                { label = "WARN",  value = "WARN" },
                { label = "ERROR", value = "ERROR" },
                { label = "NONE",  value = "NONE" },
            },
            variable = mwse.mcm.createTableVariable({
                id = "logLevel",
                table = config.development,
            }),
            callback = function(self)
                local logger = require("InspectItem.logger")
                logger:setLogLevel(self.variable.value)
            end
        })
        dev:createOnOffButton({
            label = settings.i18n("mcm.development.logToConsole.label"),
            description = settings.i18n("mcm.development.logToConsole.description"),
            variable = mwse.mcm.createTableVariable({
                id = "logToConsole",
                table = config.development,
            }),
            callback = function(self)
                local logger = require("InspectItem.logger")
                logger.logToConsole = config.development.logToConsole
            end
        })
    end
end
event.register(tes3.event.modConfigReady, OnModConfigReady)
