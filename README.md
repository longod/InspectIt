# Inspect It!
This mod allow you to inspect a variety of objects.

![Inspect It!](InspectIt.gif)

## How to use
### Begin Inspection
- You can inspect an object by pressing the assigned key binding (default: `F2`) when you mouseover an item in the inventory and an activatable object in the world with the cursor. Or you look at an activatable object with the crosshair.

### During Inspection
- You can rotate, move and zoom an object with your mouse.
- If there is another look, you can switch to it. E.g., armors, clothes, sheathed weapons or the contents of books and scrolls.
- To finish the inspection, press the same key binding as for the beginning.

## Requirements
- The latest nightly build of Morrowind Script Extender 2.1
- [Morrowind Graphics Extender XE](https://www.nexusmods.com/morrowind/mods/41102)
    - `Enable shaders` in MGE XE must be enabled to use focuse effect. But there is no need to set up anything in `Shader setup`.

## Compatibility
- [Right Click Menu Exit](https://www.nexusmods.com/morrowind/mods/48458) by Merlord
  - Right-click to exit inspection.
- [Tooltips Complete](https://www.nexusmods.com/morrowind/mods/46842) by Anumaril21
  - If those are descriptions by that mod, it can be displayed during the inspection.
- [Weapon Sheathing](https://www.nexusmods.com/morrowind/mods/46069) by TES3 Community
  - If those are sheathed weapons by that mod, you can switch the display to it.

## Known Issues and Future Work
- To inspect the player yourself, you have to be TPV (experimental).
- For some objects, the initial orientation is not appropriate.
- It does not open and read books and scrolls that include a script. The reason for this is to avoid accidentally opening them, for some of them involve a quest to see if they have been opened or not.
- If you look at an object from an angle you do not normally see, you may see that there is no geometry there and it looks like a hole. This problem possibly can be solved by model replacer mods.
- Animations are not played. Especially particles.
- Trailer-type particles are not displayed.
- Light sources do not light up.
