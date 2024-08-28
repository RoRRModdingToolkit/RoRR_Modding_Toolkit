-- Item
-- Original custom items mod written by GrooveSalad

Item = {}

local callbacks = {}
local has_custom_item = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== Enums ==========

Item.TIER = {
    common      = 0,
    uncommon    = 1,
    rare        = 2,
    equipment   = 3,
    boss        = 4,
    special     = 5,
    food        = 6,
    notier      = 7
}


Item.LOOT_TAG = {
    category_damage                 = 1,
    category_healing                = 2,
    category_utility                = 4,
    equipment_blacklist_enigma      = 8,
    equipment_blacklist_chaos       = 16,
    equipment_blacklist_activator   = 32,
    item_blacklist_engi_turrets     = 64,
    item_blacklist_vendor           = 128,
    item_blacklist_infuser          = 256
}


Item.TYPE = {
    all         = 0,
    real        = 1,
    temporary   = 2
}



-- ========== General Functions ==========

Item.find = function(namespace, identifier)
    if not identifier then return gm.item_find(namespace) end
    return gm.item_find(namespace.."-"..identifier)
end


Item.find_all = function(...)
    local tiers = {...}
    local items = {}

    local size = gm.array_length(Class.ITEM)
    for i = 0, size - 1 do
        for _, tier in ipairs(tiers) do
            local item = gm.array_get(Class.ITEM, i)
            if gm.array_get(item, 6) == tier then
                table.insert(items, i)
                break
            end
        end
    end

    return items
end


Item.get_data = function(item)
    local item_arr = gm.array_get(Class.ITEM, item)
    return {
        namespace       = gm.array_get(item_arr, 0),
        identifier      = gm.array_get(item_arr, 1),
        token_name      = gm.array_get(item_arr, 2),
        token_text      = gm.array_get(item_arr, 3),
        on_acquired     = gm.array_get(item_arr, 4),
        on_removed      = gm.array_get(item_arr, 5),
        tier            = gm.array_get(item_arr, 6),
        sprite_id       = gm.array_get(item_arr, 7),
        object_id       = gm.array_get(item_arr, 8),
        item_log_id     = gm.array_get(item_arr, 9),
        achievement_id  = gm.array_get(item_arr, 10),
        is_hidden       = gm.array_get(item_arr, 11),
        effect_display  = gm.array_get(item_arr, 12),
        actor_component = gm.array_get(item_arr, 13),
        loot_tags       = gm.array_get(item_arr, 14),
        is_new_item     = gm.array_get(item_arr, 15)
    }
end


Item.get_random = function(...)
    local items = Item.find_all(...)
    return items[gm.irandom_range(1, #items)]
end


Item.get_stack_count = function(actor, item, type_)
    if not Instance.exists(actor) then return 0 end
    if not gm.object_is_ancestor(actor.object_index, gm.constants.pActor) then return 0 end

    if type_ == Item.TYPE.real then return gm.item_count(actor, item, false) end
    if type_ == Item.TYPE.temporary then return gm.item_count(actor, item, true) end
    return gm.item_count(actor, item, false) + gm.item_count(actor, item, true)
end


Item.spawn_drop = function(item, x, y, target)
    local obj = Item.get_data(item).object_id
    if obj then gm.item_drop_object(obj, x, y, target, false) end

    -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
    -- The drop spawns 40 px above y parameter
    local drop = nil
    local drops = Instance.find_all(gm.constants.pPickupItem, gm.constants.oCustomObject_pPickupItem)
    for _, d in ipairs(drops) do
        if math.abs(d.x - x) <= 1.0 and math.abs(d.y - (y - 40.0)) <= 1.0 then
            drop = d
            d.y = d.y + 40.0
            d.ystart = d.y
            break
        end
    end

    return drop
end


Item.toggle_loot = function(item, enabled)
    if enabled == nil then return end

    local loot_pools = gm.variable_global_get("treasure_loot_pools")

    local item_array = gm.array_get(Class.ITEM, item)
    local obj = gm.array_get(item_array, 8)
    
    if enabled then
        if disabled_loot[item] then
            -- Add back to loot pools
            for _, pool_id in ipairs(disabled_loot[item]) do
                gm.ds_list_add(gm.array_get(loot_pools, pool_id).drop_pool, obj)
                if not Helper.table_has(loot_toggled, pool_id) then
                    table.insert(loot_toggled, pool_id)
                end
            end

            disabled_loot[item] = nil
        end

    else
        if not disabled_loot[item] then
            -- Remove from loot pools
            -- and store the pool indexes
            local pools = {}

            local size = gm.array_length(loot_pools)
            for i = 0, size - 1 do
                local drops = gm.array_get(loot_pools, i).drop_pool
                local pos = gm.ds_list_find_index(drops, obj)
                if pos >= 0 then
                    gm.ds_list_delete(drops, pos)
                    table.insert(pools, i)
                end
            end

            disabled_loot[item] = pools
        end

    end
end



-- ========== Custom Item Functions ==========

Item.create = function(namespace, identifier, no_log)
    if Item.find(namespace, identifier) then return nil end

    -- Create item
    local item = gm.item_create(
        namespace,
        identifier,
        nil,
        Item.TIER.notier,
        gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0
    )

    if not no_log then
        -- Create item log
        local item_array = gm.array_get(Class.ITEM, item)
        local log = gm.item_log_create(
            namespace,
            identifier,
            nil,
            nil,
            gm.array_get(item_array, 8)
        )

        -- Set item log ID into item array
        gm.array_set(item_array, 9, log)
    end

    -- Add onPickup callback to add actor to has_custom_item table
    Item.add_callback(item, "onPickup", function(actor, stack)
        if not Helper.table_has(has_custom_item, actor) then
            table.insert(has_custom_item, actor)
        end
    end)

    return item
end


Item.set_sprite = function(item, sprite)
    -- Set class_item sprite
    local array = gm.array_get(Class.ITEM, item)
    gm.array_set(array, 7, sprite)

    -- Set item object sprite
    local obj = gm.array_get(array, 8)
    gm.object_set_sprite_w(obj, sprite)

    -- Set item log sprite
    if array[10] then
        local log_array = gm.array_get(Class.ITEM_LOG, gm.array_get(array, 9))
        gm.array_set(log_array, 9, sprite)
    end
end


Item.set_tier = function(item, tier)
    -- Set class_item tier
    local array = gm.array_get(Class.ITEM, item)
    gm.array_set(array, 6, tier)

    local obj = gm.array_get(array, 8)
    local pools = gm.variable_global_get("treasure_loot_pools")


    -- Remove from all loot pools (if found)
    local size = gm.array_length(pools)
    for i = 0, size - 1 do
        local drops = gm.array_get(pools, i).drop_pool
        local pos = gm.ds_list_find_index(drops, obj)
        if pos >= 0 then gm.ds_list_delete(drops, pos) end
    end

    -- Add to new loot pool
    local pool = pools[tier + 1]
    local drops = pool.drop_pool
    gm.ds_list_add(drops, obj)


    -- Remove previous item log position (if found)
    local item_log_order = gm.variable_global_get("item_log_display_list")
    local pos = gm.ds_list_find_index(item_log_order, array[10])
    if pos >= 0 then gm.ds_list_delete(item_log_order, pos) end

    -- Set item log position
    local pos = 0
    for i = 0, gm.ds_list_size(item_log_order) - 1 do
        local log_id = gm.ds_list_find_value(item_log_order, i)
        local log_ = gm.array_get(Class.ITEM_LOG, log_id)
        local item_id = Item.find(log_[1], log_[2])
        
        local tier_ = Item.TIER.equipment
        if item_id then
            local iter_item = gm.array_get(Class.ITEM, item_id)
            tier_ = gm.array_get(iter_item, 6)
        end
        if tier_ > tier then
            pos = i
            break
        end
    end
    gm.ds_list_insert(item_log_order, pos, array[10])
end


Item.set_loot_tags = function(item, ...)
    local tags = 0
    for _, t in ipairs{...} do tags = tags + t end

    local array = gm.array_get(Class.ITEM, item)
    gm.array_set(array, 14, tags)
end


Item.add_achievement = function(item, progress_req, single_run)
    local array = gm.array_get(Class.ITEM, item)

    local namespace = gm.array_get(array, 0)
    local identifier = gm.array_get(array, 1)

    local ach = gm.achievement_create(namespace, identifier)
    gm.achievement_set_unlock_item(ach, item)
    gm.achievement_set_requirement(ach, progress_req or 1)

    if single_run then
        local ach_array = gm.array_get(Class.ACHIEVEMENT, ach)
        gm.array_set(ach_array, 21, single_run)
    end
end


Item.progress_achievement = function(item, amount)
    local array = gm.array_get(Class.ITEM, item)
    local ach_id = gm.array_get(array, 10)

    if gm.achievement_is_unlocked(ach_id) then return end
    gm.achievement_add_progress(ach_id, amount or 1)
end


Item.add_callback = function(item, callback, func)
    local array = gm.array_get(Class.ITEM, item)

    if callback == "onPickup" then
        local callback_id = gm.array_get(array, 4)
        if not callbacks[callback_id] then callbacks[callback_id] = {} end
        table.insert(callbacks[callback_id], func)

    elseif callback == "onRemove" then
        local callback_id = gm.array_get(array, 5)
        if not callbacks[callback_id] then callbacks[callback_id] = {} end
        table.insert(callbacks[callback_id], func)

    elseif callback == "onBasicUse"
        or callback == "onAttack"
        or callback == "onPostAttack"
        or callback == "onHit"
        or callback == "onKill"
        or callback == "onDamaged"
        or callback == "onDamageBlocked"
        or callback == "onHeal"
        or callback == "onShieldBreak"
        or callback == "onInteract"
        or callback == "onEquipmentUse"
        or callback == "onStep"
        or callback == "onDraw"
        then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {item, func})

    end
end



-- ========== Internal ==========

function onAttack(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks["onAttack"] then
        for _, c in ipairs(callbacks["onAttack"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value.parent, item)
            if count > 0 then
                local func = c[2]
                func(self, args[2].value, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


function onPostAttack(self, other, result, args)
    if not args[2].value.proc or not args[2].value.parent then return end
    if callbacks["onPostAttack"] then
        for _, c in ipairs(callbacks["onPostAttack"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value.parent, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value.parent, args[2].value, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


function onHit(self, other, result, args)
    if not self.attack_info.proc then return end
    if callbacks["onHit"] then
        for _, c in ipairs(callbacks["onHit"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value, args[3].value, self.attack_info, count) -- Attacker, Victim, Damager attack_info, Stack count
            end
        end
    end
end


function onKill(self, other, result, args)
    if callbacks["onKill"] then
        for _, c in ipairs(callbacks["onKill"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[3].value, item)
            if count > 0 then
                local func = c[2]
                func(args[3].value, args[2].value, count)   -- Attacker, Victim, Stack count
            end
        end
    end
end


function onDamaged(self, other, result, args)
    if callbacks["onDamaged"] then
        for _, c in ipairs(callbacks["onDamaged"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value, args[3].value.attack_info, count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


function onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for _, c in ipairs(callbacks["onDamageBlocked"]) do
            local item = c[1]
            local count = Item.get_stack_count(self, item)
            if count > 0 then
                local func = c[2]
                func(self, other.attack_info, count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


function onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        for _, c in ipairs(callbacks["onInteract"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[3].value, item)
            if count > 0 then
                local func = c[2]
                func(args[3].value, args[2].value, count)   -- Actor, Interactable, Stack count
            end
        end
    end
end


function onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for _, c in ipairs(callbacks["onEquipmentUse"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value, args[3].value, count)   -- Actor, Equipment ID, Stack count
            end
        end
    end
end


function onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onStep"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onStep"]) do
                    local count = Item.get_stack_count(a, c[1])
                    if count > 0 then
                        c[2](a, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end

    if callbacks["onShieldBreak"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                if a.shield and a.shield > 0.0 then a.RMT_has_shield = true end
                if a.RMT_has_shield and a.shield <= 0.0 then
                    a.RMT_has_shield = nil
                    for _, c in ipairs(callbacks["onShieldBreak"]) do
                        local count = Item.get_stack_count(a, c[1])
                        if count > 0 then
                            c[2](a, count)  -- Actor, Stack count
                        end
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end
end


function onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    if callbacks["onDraw"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onDraw"]) do
                    local count = Item.get_stack_count(a, c[1])
                    if count > 0 then
                        c[2](a, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end
end


Item.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value)
        end
    end
end)


gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if args[1].value ~= 0.0 or self.skills[1].active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for _, fn in pairs(callbacks["onBasicUse"]) do
            local count = Item.get_stack_count(self, fn[1])
            if count > 0 then
                fn[2](self, count)   -- Actor, Stack count
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for _, fn in pairs(callbacks["onHeal"]) do
            local count = Item.get_stack_count(args[1].value, fn[1])
            if count > 0 then
                fn[2](args[1].value, args[2].value, count)   -- Actor, Heal amount, Stack count
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Sort loot tables that have been added to
    for _, pool_id in ipairs(loot_toggled) do
        local loot_pools = gm.variable_global_get("treasure_loot_pools")

        -- Get item IDs from objects and sort
        local ids = gm.ds_list_create()
        local pool = gm.array_get(loot_pools, pool_id).drop_pool
        local size = gm.ds_list_size(pool)
        for i = 0, size - 1 do
            local obj = gm.ds_list_find_value(pool, i)
            gm.ds_list_add(ids, gm.object_to_item(obj))
        end
        gm.ds_list_sort(ids, true)

        -- Add objects of sorted IDs back into loot pool
        gm.ds_list_clear(pool)
        for i = 0, size - 1 do
            local id = gm.ds_list_find_value(ids, i)
            local _item = gm.array_get(Class.ITEM, id)
            local obj = gm.array_get(_item, 8)
            gm.ds_list_add(pool, obj)
        end
        gm.ds_list_destroy(ids)
    end
    loot_toggled = {}
end)



-- ========== Initialize ==========

Item.__initialize = function()
    Callback.add("onAttackCreate", "RMT.item_onAttack", onAttack, true)
    Callback.add("onAttackHandleEnd", "RMT.item_onPostAttack", onPostAttack, true)
    Callback.add("onHitProc", "RMT.item_onHit", onHit, true)
    Callback.add("onKillProc", "RMT.item_onKill", onKill, true)
    Callback.add("onDamagedProc", "RMT.item_onDamaged", onDamaged, true)
    Callback.add("onDamageBlocked", "RMT.item_onDamageBlocked", onDamageBlocked, true)
    Callback.add("onInteractableActivate", "RMT.item_onInteract", onInteract, true)
    Callback.add("onEquipmentUse", "RMT.item_onEquipmentUse", onEquipmentUse, true)
    Callback.add("preStep", "RMT.item_onStep", onStep, true)
    Callback.add("postHUDDraw", "RMT.item_onDraw", onDraw, true)
end