local config = require("InspectItem.config")

local logger = require("logging.logger").new({
    name = "Inspect Item",
    logLevel = config.development.logLevel,
    logToConsole = config.development.logToConsole,
    includeTimestamp = false,
})

return logger
