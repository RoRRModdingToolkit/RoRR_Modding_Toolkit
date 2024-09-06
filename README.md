Friendly abstractions of the game's internal functions for easier modding.  
Documentation can be found [here](https://github.com/RoRRModdingToolkit/RoRR_Modding_Toolkit/wiki).  

To use, include `RoRRModdingToolkit-RoRR_Modding_Toolkit-1.1.0` as a dependency, and place the following line in your code:  
```lua
mods.on_all_mods_loaded(function() for _, m in pairs(mods) do if type(m) == "table" and m.RoRR_Modding_Toolkit then Actor = m.Actor Alarm = m.Alarm Array = m.Array Buff = m.Buff Callback = m.Callback Class = m.Class Color = m.Color Equipment = m.Equipment Helper = m.Helper Instance = m.Instance Item = m.Item List = m.List Net = m.Net Object = m.Object Player = m.Player Resources = m.Resources Skill = m.Skill Survivor = m.Survivor Wrap = m.Wrap break end end end)

```

### Current Functionality
* General-purpose helper functions
* GameMaker structure wrapping (arrays and ds_lists)
* Instance finding
* Callback setup
* Network syncing
* Custom content
    * Buffs
    * Items and Equipment
    * Objects
    * Skills
    * Survivors (still a WIP, but usable)

---

### Installation Instructions
Follow the instructions [listed here](https://docs.google.com/document/d/1NgLwb8noRLvlV9keNc_GF2aVzjARvUjpND2rxFgxyfw/edit?usp=sharing).
