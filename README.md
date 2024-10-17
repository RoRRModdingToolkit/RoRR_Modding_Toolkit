Friendly abstractions of the game's internal functions for easier modding.  
Documentation can be found [here](https://github.com/RoRRModdingToolkit/RoRR_Modding_Toolkit/wiki).  

Include `RoRRModdingToolkit-RoRR_Modding_Toolkit-1.1.18` as a dependency in `manifest.json`.

To auto-add RMT class references directly to your workspace, place the following line in your code:  
```lua
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

```

Alternatively, you can store these references in a variable:
```lua
local RMT = mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].setup()

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
    * Difficulties
    * Objects
    * Survivors, Skills, and States
    * Stages
    * etc.

---

### Installation Instructions
Install through the Thunderstore client or r2modman [(more detailed instructions here if needed)](https://return-of-modding.github.io/ModdingWiki/Playing/Getting-Started/).  
Join the [Return of Modding server](https://discord.gg/VjS57cszMq) for support.  