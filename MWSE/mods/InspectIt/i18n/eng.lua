return {
    ["messageBox.unsupport.text"] = "It is not yet supported for inspection.",
    ["messageBox.playerRequirement.text"] = "When inspecting the player character, use third person view.",
    ["messageBox.bookRequirement.text"] = "'%{name}' cannot be opened inside because something will happen to it.",
    ["guide.rotate.text"] = "Rotate: Mouse left drag",
    ["guide.translate.text"] = "Move: Mouse middle drag",
    ["guide.zoom.text"] = "Zoom: Mouse wheel",
    ["guide.another.text"] = "Switch another",
    ["guide.lighting.text"] = "Switch lighting",
    ["guide.leftPart.text"] = "Toggle left part",
    ["guide.leftPart.normal"] = "Normal",
    ["guide.leftPart.mirror"] = "Mirrored",
    ["guide.leftPart.plugin"] = "Plugin",
    ["guide.reset.text"] = "Reset pose",
    ["guide.return.text"] = "Return",
    ["mcm.page.label"] = "Config",
    ["mcm.sidebar.info"] = "You can inspect an object by pressing the assigned key binding when you mouseover an item in the inventory and an activatable object in the world with the cursor. Or you look at an activatable object with the crosshair.",
    ["mcm.input.category.label"] = "Input",
    ["mcm.input.category.description"] = "Configure settings for input.",
    ["mcm.input.inspect.label"] = "Inspect",
    ["mcm.input.inspect.description"] = "Key binding for inspecting an object.",
    ["mcm.input.another.label"] = "Switch Another",
    ["mcm.input.another.description"] = "If another look exists, key binding for switching to it during inspection.",
    ["mcm.input.lighting.label"] = "Switch Lighting",
    ["mcm.input.lighting.description"] = "Key bindings for switching lighting during inspection.\nCurrently, when it is not lit, it is rendered in front of the UI. Also field of view probably be different.",
    ["mcm.input.reset.label"] = "Reset Pose",
    ["mcm.input.reset.description"] = "Key bindings for resetting the pose during inspection.",
    ["mcm.input.sensitivityX.label"] = "Horizontal Sensitivity",
    ["mcm.input.sensitivityX.description"] = "Horizontal sensitivity during inspection. It is further multiplied from the sensitivity of the game options.",
    ["mcm.input.sensitivityY.label"] = "Vertical Sensitivity",
    ["mcm.input.sensitivityY.description"] = "Vertical sensitivity during inspection. It is further multiplied from the sensitivity of the game options.",
    ["mcm.input.sensitivityZ.label"] = "Zoom Sensitivity",
    ["mcm.input.sensitivityZ.description"] = "Zoom sensitivity with mouse wheel during inspection.",
    ["mcm.input.inversionX.label"] = "Horizontal Inversion",
    ["mcm.input.inversionX.description"] = "Invert horizontal dragging.",
    ["mcm.input.inversionY.label"] = "Vertical Inversion",
    ["mcm.input.inversionY.description"] = "Invert vertical dragging.",
    ["mcm.input.inversionZ.label"] = "Zoom Inversion",
    ["mcm.input.inversionZ.description"] = "Invert mouse wheel in zooming.",
    ["mcm.inspection.category.label"] = "Inspection",
    ["mcm.inspection.category.description"] = "Configure settings for inspection.",
    ["mcm.inspection.inventory.label"] = "Mouseover an Item in Inventory",
    ["mcm.inspection.inventory.description"] = "When you mouseover an item in your inventory, you can inspect it.",
    ["mcm.inspection.barter.label"] = "Mouseover an Item in Barter",
    ["mcm.inspection.barter.description"] = "When you mouseover an item being bartered, you can inspect it.",
    ["mcm.inspection.contents.label"] = "Mouseover an Item in Container",
    ["mcm.inspection.contents.description"] = "When you mouseover an item in a container or pickpocketing, you can inspect it.",
    ["mcm.inspection.cursorOver.label"] = "Mouseover an Activatable Object in the World",
    ["mcm.inspection.cursorOver.description"] = "When you mouseover an activatable object in the world with the cursor, you can inspect it.",
    ["mcm.inspection.activatable.label"] = "Look at an Activatable Object",
    ["mcm.inspection.activatable.description"] = "When you are looking at an activatable object with the crosshair, you can inspect it.",
    ["mcm.inspection.playSound.label"] = "Play Sound",
    ["mcm.inspection.playSound.description"] = "Play the sound effect set for the object.",
    ["mcm.display.category.label"] = "Display",
    ["mcm.display.category.description"] = "Configure elements to be displayed on the screen.",
    ["mcm.display.instruction.label"] = "Instruction",
    ["mcm.display.instruction.description"] = "Display of key instructions. Key bindings are always enabled.",
    ["mcm.display.bokeh.label"] = "Focus Effect",
    ["mcm.display.bokeh.description"] = "Display the effect of blurring the background during inspection. 'Enable shaders' in MGE XE must be enabled to use this feature.",
    ["mcm.display.leftPart.label"] = "Mirror the Left Part",
    ["mcm.display.leftPart.description"] = "Mirror the left part of armor or clothing. Most of the left part of armor or clothing is the same as the right part, so the left hand is the right hand.\nExclusion settings for each item or plugin can be configured from 'Mirror the Left Part' tab.",
    ["mcm.display.recalculateBounds.label"] = "Recalculate Bounding Box",
    ["mcm.display.recalculateBounds.description"] = "The object to be inspected may fit more efficiently on the screen. But it requires heavy load when starting the inspection.",
    ["mcm.display.tooltipsComplete.label"] = "Tooltips Complete",
    ["mcm.display.tooltipsComplete.description"] = "If Tooltips Complete is installed, its description is displayed during the inspection. That mod's config also be applied.",
    ["mcm.development.category.label"] = "Development",
    ["mcm.development.category.description"] = "Features for development.",
    ["mcm.development.experimental.label"] = "Experimental",
    ["mcm.development.experimental.description"] = "Enable experimental features. Glitches may occur. It probably spoil the immersion.\nIn addition to activatable objects, most other objects can be inspected.",
    ["mcm.development.logLevel.label"] = "Logging Level",
    ["mcm.development.logLevel.description"] = "Set the log level.",
    ["mcm.development.logToConsole.label"] = "Log to Console",
    ["mcm.development.logToConsole.description"] = "Output the log to console.",
    ["mcm.leftPartFilter.page.label"] = "Mirror the Left Part",
    ["mcm.leftPartFilter.page.description"] = "Most of the left part of armor or clothing is the same as the right part, so the left hand is the right hand.\nIt is recommended that they be mirrored, as you can filter the left part, which uses the same mesh as the right part. This can be done by setting all items to 'Normal' once and then setting items of the same mesh to 'Mirrored'.\nAlso Plugins take priority over item IDs.\nThis setting can be toggled for that item during the inspection.",
    ["mcm.leftPartFilter.page.normal"] = "Normal",
    ["mcm.leftPartFilter.page.mirror"] = "Mirrored",
    ["mcm.leftPartFilter.armor.label"] = "Armor",
    ["mcm.leftPartFilter.clothing.label"] = "Clothing",
    ["mcm.leftPartFilter.sameArmor.label"] = "Armor (Same Mesh)",
    ["mcm.leftPartFilter.sameClothing.label"] = "Clothing (Same Mesh)",
    ["mcm.leftPartFilter.plugin.label"] = "Plugin",
}
