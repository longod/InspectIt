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
        text = "Inspect It!"
    })

    do
        local input = page:createCategory({
            label = "Input",
            description = "input",
        })
        input:createKeyBinder({
            label = "Assign Keybind",
            description = "Assign a new keybind to perform awesome tasks.",
            variable = mwse.mcm.createTableVariable({
                id = "keybind",
                table = config.input
            }),
            allowCombinations = true,
            allowMouse = false,
        })
    end
    do
        local dev = page:createCategory({
            label = "Development",
            description = "Features for Development",
        })
        dev:createDropdown({
            label = "Logging Level",
            description = "Set the log level.",
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
                table = config.development
            }),
            callback = function(self)
                local logger = require("InspectItem.logger")
                logger:setLogLevel(self.variable.value)
            end
        })
        dev:createOnOffButton({
            label = "Log to Console",
            description = "Output the log to console.",
            variable = mwse.mcm.createTableVariable({
                id = "logToConsole",
                table = config.development,
            }),
            callback = function(self)
                local logger = require("InspectItem.logger")
                logger.logToConsole = config.development.logToConsole
            end
        })
        dev:createOnOffButton({
            label = "Unit testing",
            description = "Run Unit testing on startup.",
            variable = mwse.mcm.createTableVariable({
                id = "test",
                table = config.development,
                restartRequired = true,
            })
        })
    end
end
event.register(tes3.event.modConfigReady, OnModConfigReady)
