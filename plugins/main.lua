-- RoRR Modding Toolkit v1.0.0

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./callback")
require("./helper")
require("./instance")
require("./item")
require("./net")
require("./player")

local spr = gm.sprite_add(_ENV["!plugins_mod_folder_path"].."/plugins/sCancel.png", 1, false, false, 16, 16)



-- ========== Testing ==========

gui.add_imgui(function()
    if ImGui.Begin("RoRR Modding Toolkit") then

        if ImGui.Button("Destroy all chests") then
            local chests = Instance.find_all(Instance.chests)
            for _, c in ipairs(chests) do
                gm.instance_destroy(c)
            end

        elseif ImGui.Button("Log Net.TYPE") then
            log.info(Net.get_type())

        elseif ImGui.Button("Kill self") then
            local player = Player.get_client()
            if player then player.hp = -1.0 end

        elseif ImGui.Button("Create new item") then
            gm.translate_load_file(gm.variable_global_get("_language_map"), _ENV["!plugins_mod_folder_path"].."/plugins/language/english.json")

            local item = Item.create("rmt", "customItem")
            Item.set_sprite(item, spr)
            Item.set_tier(item, Item.TIER.uncommon)
            Item.add_callback(item, "onPickup", function(player, stack)
                player.maxhp = player.maxhp + 10.0 * stack
                player.hp = player.hp + 10.0 * stack
                player.infusion_hp = player.infusion_hp + 10.0 * stack
            end)
            Item.add_callback(item, "onRemove", function(player, stack)
                player.maxhp = player.maxhp - 10.0 * stack
                player.infusion_hp = player.infusion_hp - 10.0 * stack
            end)
            Item.add_callback(item, "onHit", function(damager, hit)
                hit.hp = -1.0
            end)

        elseif ImGui.Button("Give new item") then
            gm.item_give(Player.get_client(), gm.item_find("rmt-customItem"), 1, false)

        elseif ImGui.Button("Give new item temp") then
            gm.item_give(Player.get_client(), gm.item_find("rmt-customItem"), 1, true)
            
        end
    end
    ImGui.End()
end)


-- log.info(Helper.table_to_string)
-- log.info(Net.get_type())

-- function test(a, b, ...)
--     return {...}
-- end

-- log.info(test(1, 2, 3, 4, 5)[2])

-- log.info(4 or nil)
-- log.info(nil or 5)
-- log.info(nil or nil)
-- log.info(4 or 5)


-- local pool = gm.variable_global_get("treasure_loot_pools")[1]
-- local names = gm.struct_get_names(pool)
-- for _, n in ipairs(names) do
--     log.info(n)
-- end
-- local drop = pool.drop_pool
-- log.info(drop)
-- log.info(gm.ds_list_size(drop))
-- log.info(gm.object_get_name(gm.ds_list_find_value(drop, 0)))    -- oNugget