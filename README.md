Friendly abstractions of the game's internal functions for easier modding.  
Documentation can be found [here](https://github.com/RoRRModdingToolkit/RoRR_Modding_Toolkit/wiki).  

To use, include `RoRRModdingToolkit-RoRR_Modding_Toolkit-1.1.7` as a dependency, and place the following line in your code:  
```lua
mods.on_all_mods_loaded(function() for _, m in pairs(mods) do if type(m) == "table" and m.RoRR_Modding_Toolkit then for _, c in ipairs(m.Classes) do if m[c] then _G[c] = m[c] end end end end end)

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
Install through the Thunderstore client or r2modman [(more detailed instructions here if needed)](https://return-of-modding.github.io/ModdingWiki/Playing/Getting-Started/).  
Join the [Return of Modding server](https://discord.gg/VjS57cszMq) for support.  