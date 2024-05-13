# Inspect It!
This mod allow you to inspect a variety of objects.

![Inspect It!](InspectIt.gif)

## How to use
### Begin the Inspection
- You can inspect an object by pressing the assigned key binding (default: `F2`) when you mouseover an item in the inventory or you look at an activatable object with the crosshair.

### During Inspection
- You can rotate and zoom an object with your mouse.
- If there is another look, you can switch to it. E.g., a sheathed weapon or the contents of a book or scroll.
- To finish the inspection, press the same key binding as for the beginning.

## Requirements
- The latest nightly build of Morrowind Script Extender 2.1
- [Morrowind Graphics Extender XE](https://www.nexusmods.com/morrowind/mods/41102)
    - `Enable shaders` in MGE XE must be enabled to use focuse effect. However, there is no need to set up anything in `Shader setup`.

## Mod Compatibility
- [Right Click Menu Exit](https://www.nexusmods.com/morrowind/mods/48458)
  - Right-click to exit the inspection.
- [Tooltips Complete](https://www.nexusmods.com/morrowind/mods/46842)
  - If those are descriptions by that mod, it can be displayed during the inspection.
- [Weapon Sheathing](https://www.nexusmods.com/morrowind/mods/46069)
  - If those are sheathed weapons by that mod, you can switch the display to it.

## Known Issues and Future Work
- Animations are not played. Especially particles.
- Trailer-type particles are not displayed.
- If you look at an object from an angle you do not normally see, you may see that there is no geometry there and it looks like a hole. This problem possibly can be solved by model replacer mods.
- For some objects, the initial orientation or position is not appropriate.
- Another look at armor and clothing with body parts is under research. This also applies to NPCs.
- Inspection of mouseovered object in the world during the menu is not yet supported.
