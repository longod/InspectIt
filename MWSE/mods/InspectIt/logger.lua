local config = require("InspectIt.config")

local logger = require("logging.logger").new({
    name = "Inspect It!",
    logLevel = config.development.logLevel,
    includeTimestamp = false,
})

return logger
