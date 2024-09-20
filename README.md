Friendly abstractions of the game's internal functions for easier modding.  
Documentation can be found [here](https://github.com/RoRRModdingToolkit/RoRR_Modding_Toolkit/wiki).  

To use, include `RoRRModdingToolkit-RoRR_Modding_Toolkit-1.1.0` as a dependency, and place the following line in your code:  
```lua
mods.on_all_mods_loaded(function() for _, m in pairs(mods) do if type(m) == "table" and m.RoRR_Modding_Toolkit then Achievement = m.Achievement Actor = m.Actor Alarm = m.Alarm Array = m.Array Artifact = m.Artifact Buff = m.Buff Callback = m.Callback Class = m.Class Color = m.Color Equipment = m.Equipment Helper = m.Helper Instance = m.Instance Interactable = m.Interactable Item = m.Item Language = m.Language List = m.List Net = m.Net Object = m.Object Player = m.Player Resources = m.Resources Skill = m.Skill State = m.State Survivor_Log = m.Survivor_Log Survivor = m.Survivor Wrap = m.Wrap break end end end)

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
    * Survivors, Skills, and States
    * etc.

---

### Installation Instructions
Install on Thunderstore or r2modman [(more detailed instructions here if needed)](https://return-of-modding.github.io/ModdingWiki/Playing/Getting-Started/).  
Join the [Return of Modding server](https://discord.gg/VjS57cszMq) for support.  