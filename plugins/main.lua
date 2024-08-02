-- RoRR Modding Toolkit v1.0.0

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./callback")
require("./helper")
require("./initialize")
require("./instance")
require("./item")
require("./net")
require("./player")



-- ========== Testing ==========

local spr = gm.sprite_add(_ENV["!plugins_mod_folder_path"].."/plugins/sCancel.png", 1, false, false, 16, 16)

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
            if Item.find("rmt-customItem") then return end

            gm.translate_load_file(gm.variable_global_get("_language_map"), _ENV["!plugins_mod_folder_path"].."/plugins/language/english.json")

            local item = Item.create("rmt", "customItem")
            Item.set_sprite(item, spr)
            Item.set_tier(item, Item.TIER.uncommon)
            Item.set_loot_tags(item, Item.LOOT_TAG.category_damage, Item.LOOT_TAG.category_healing)

            Item.add_callback(item, "onPickup", function(actor, stack)
                actor.maxhp = actor.maxhp + 10.0 * stack
                actor.hp = actor.hp + 10.0 * stack
                actor.infusion_hp = actor.infusion_hp + 10.0 * stack
            end)

            Item.add_callback(item, "onRemove", function(actor, stack)
                actor.maxhp = actor.maxhp - 10.0 * stack
                actor.infusion_hp = actor.infusion_hp - 10.0 * stack
            end)

            Item.add_callback(item, "onShoot", function(actor, damager, stack)
                -- Crit every 6 shots
                -- Additional stacks increase the shot's damage by 20%
                if not actor.six_shooter then actor.six_shooter = 0 end
                actor.six_shooter = actor.six_shooter + 1
                if actor.six_shooter >= 6 then
                    actor.six_shooter = 0
                    damager.damage = damager.damage * 2.0
                    damager.critical = true
                    if stack > 1 then
                        damager.damage = damager.damage * (0.8 + (0.2 * stack))
                    end
                end
            end)

            Item.add_callback(item, "onHit", function(attacker, victim, damager, stack)
                -- Reduce victim health to 50% if over that
                local ceil = victim.maxhp * 0.5
                if victim.hp > ceil then victim.hp = ceil end
            end)

            Item.add_callback(item, "onKill", function(attacker, victim, stack)
                -- Increase maximum shield
                attacker.maxshield = attacker.maxshield + 5.0 * stack
                attacker.maxshield_base = attacker.maxshield_base + 5.0 * stack
                attacker.shield = attacker.shield + 5.0 * stack
            end)

            Item.add_callback(item, "onDamaged", function(actor, damager, stack)
                -- Increase max health
                -- Also make attacker take damage
                actor.maxhp = actor.maxhp + 2.0 * stack
                actor.infusion_hp = actor.infusion_hp + 2.0 * stack
                if Instance.exists(damager.parent) then
                    damager.parent.hp = damager.parent.hp - (damager.parent.maxhp * 0.1)
                end
            end)

            Item.add_callback(item, "onDamageBlocked", function(actor, damager, stack)
                -- Kill attacker
                damager.parent.hp = -1.0
            end)

            Item.add_callback(item, "onInteract", function(actor, interactable, stack)
                -- Increase max health
                actor.maxhp = actor.maxhp + 50.0
                actor.infusion_hp = actor.infusion_hp + 50.0
            end)

            Item.add_callback(item, "onEquipmentUse", function(actor, equipment, stack)
                -- Increase max health
                actor.maxhp = actor.maxhp + 20.0 * stack
                actor.infusion_hp = actor.infusion_hp + 20.0 * stack
            end)

            Item.add_callback(item, "onStep", function(actor, stack)
                -- Spawn a chest every 7 seconds
                if not actor.spawn_chest then actor.spawn_chest = 0 end
                actor.spawn_chest = actor.spawn_chest + 1
                if actor.spawn_chest >= 420 then
                    actor.spawn_chest = 0
                    gm.instance_create_depth(actor.x, actor.y, 0, gm.constants.oChest1)
                end
            end)

            Item.add_callback(item, "onDraw", function(actor, stack)
                -- Draw a circle around actor that expands with more stacks
                gm.draw_circle(actor.x, actor.y, 60.0 + (20.0 * stack), true)
            end)


        elseif ImGui.Button("Give new item") then
            gm.item_give(Player.get_client(), gm.item_find("rmt-customItem"), 1, false)

        elseif ImGui.Button("Give new item temp") then
            gm.item_give(Player.get_client(), gm.item_find("rmt-customItem"), 1, true)

        elseif ImGui.Button("Destroy oChest1 and oChest2") then
            local cs = Instance.find_all(gm.constants.oChest1, gm.constants.oChest2)
            for _, c in ipairs(cs) do
                gm.instance_destroy(c)
            end

        elseif ImGui.Button("Find non-existent item") then
            log.info(Item.find("test1-test2"))

        elseif ImGui.Button("Spawn green crate with custom") then
            local player = Player.get_client()
            Instance.spawn_crate(player.x, player.y, Item.TIER.uncommon, {Item.find("ror-fireShield"), Item.find("ror-redWhip")})

        elseif ImGui.Button("Spawn all crates") then
            local player = Player.get_client()
            Instance.spawn_crate(player.x - 80, player.y, Item.TIER.common)
            Instance.spawn_crate(player.x - 40, player.y, Item.TIER.uncommon)
            Instance.spawn_crate(player.x, player.y, Item.TIER.rare)
            Instance.spawn_crate(player.x + 40, player.y, Item.TIER.equipment)
            Instance.spawn_crate(player.x + 80, player.y, Item.TIER.boss)

        -- elseif ImGui.Button("Add item log") then
        --     local item = Item.find("rmt-customItem")
        --     local data = Item.get_data(item)
            --gm.item_log_create("rmt", "customItem", nil, data.sprite_id, data.object_id)
            --gm.item_log_create("rmt", "test")

            -- local logs = gm.variable_global_get("class_item_log")
            -- log.info(logs)
            -- for _, a in ipairs(logs) do
            --     for _, v in ipairs(a) do
            --         local str = _.." : "
            --         if v then str = str..v end
            --         log.info(str)
            --     end
            --     log.info("")
            -- end
            
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


-- local test = {1, 2, true, false, 5}
-- local str = Helper.table_to_string(test)
-- local test2 = Helper.string_to_table(str)
-- log.info(test2[3])
-- log.info(test2[3] == true)
-- log.info(test2[4])
-- log.info(test2[4] == true)
-- log.info(test2[4] == false)

-- local function func2(...)
--     for _, i in ipairs{...} do
--         log.info(i)
--     end
-- end

-- local function func1(...)
--     func2(...)
-- end

-- log.info(func1(1, 3, 4, 56))


-- Code Storage

-- local names = gm.struct_get_names(damager)
-- log.info(names)
-- for _, n in ipairs(names) do
--     log.info(n.." = "..tostring(gm.struct_get(damager, n)))
-- end

-- log.info(gm.object_get_name(self.object_index))
-- log.info(gm.object_get_name(other.object_index))
-- log.info(result.value)
-- for _, a in ipairs(args) do
--     log.info(a.value)
-- end
-- log.info("")