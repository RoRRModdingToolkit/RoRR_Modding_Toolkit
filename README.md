description

To use, include the following line in your code:
```lua
mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            Helper = m.Helper
            Instance = m.Instance
            Item = m.Item
            Net = m.Net
            break
        end
    end
end)
```
^^^ this will get compacted into one line later like previously

---

### Installation Instructions
Follow the instructions [listed here](https://docs.google.com/document/d/1NgLwb8noRLvlV9keNc_GF2aVzjARvUjpND2rxFgxyfw/edit?usp=sharing).


### Credits
* Everybody active in the [Return of Modding server](https://discord.gg/VjS57cszMq).