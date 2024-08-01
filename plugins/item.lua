-- Item

Item = {}

local callbacks = {}
local callbacks = {}



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



-- ========== Functions ==========

Item.find = function(namespace, identifier)
    if not identifier then return gm.item_find(namespace) end
    return gm.item_find(namespace.."-"..identifier)
end


Item.get_stack_count = function(actor, item)
    return gm.item_count(actor, item, false) + gm.item_count(actor, item, true)
end


Item.create = function(namespace, identifier)
    local item = gm.item_create(
        namespace,
        identifier,
        nil,
        Item.TIER.notier,
        gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0
    )

    return item

    -- gm.array_set(array, 2)  -- token_name       "item.IDENTIFIER.name"  (default)
    -- gm.array_set(array, 3)  -- token_text       "item.IDENTIFIER.pickup"
    -- gm.array_set(array, 4)  -- on_acquired      callback id 3108.0
    -- gm.array_set(array, 5)  -- on_removed       callback id 3109.0
    -- gm.array_set(array, 6)  -- tier             7.0
    -- gm.array_set(array, 7)  -- sprite_id        sprite id 1628.0
    -- gm.array_set(array, 8)  -- object_id        object id 851.0
    -- gm.array_set(array, 9)  -- item_log_id      nil
    -- gm.array_set(array, 10) -- achievement_id   nil
    -- gm.array_set(array, 11) -- is_hidden        false
    -- gm.array_set(array, 12) -- effect_display   nil
    -- gm.array_set(array, 13) -- actor_component  nil
    -- gm.array_set(array, 14) -- loot_tags        0.0
    -- gm.array_set(array, 15) -- is_new_item      true
end


Item.set_sprite = function(item, sprite)
    -- Set class_item sprite
    local array = gm.variable_global_get("class_item")[item + 1]
    gm.array_set(array, 7, sprite)

    -- Set item object sprite
    local obj = array[9]
    gm.object_set_sprite_w(obj, sprite)
end


Item.set_tier = function(item, tier)
    -- Set class_item tier
    local array = gm.variable_global_get("class_item")[item + 1]
    gm.array_set(array, 6, tier)

    -- Add to loot pool
    local pool = gm.variable_global_get("treasure_loot_pools")[tier + 1]
    local drops = pool.drop_pool
    gm.ds_list_add(drops, array[9])
end


Item.set_loot_tags = function(item, ...)
    local tags = 0
    for _, t in ipairs{...} do tags = tags + t end

    local array = gm.variable_global_get("class_item")[item + 1]
    gm.array_set(array, 14, tags)
end


Item.add_callback = function(item, callback, func)
    local array = gm.variable_global_get("class_item")[item + 1]

    if callback == "onPickup" then
        if not callbacks[array[5]] then callbacks[array[5]] = {} end
        table.insert(callbacks[array[5]], func)

    elseif callback == "onRemove" then
        if not callbacks[array[6]] then callbacks[array[6]] = {} end
        table.insert(callbacks[array[6]], func)

    elseif callback == "onShoot"
        or callback == "onHit"
        or callback == "onKill"
        or callback == "onDamaged"
        then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {item, func})

    end
end



-- ========== Internal ==========

function onShoot(self, other, result, args)
    if callbacks["onShoot"] then
        for _, c in ipairs(callbacks["onShoot"]) do
            local item = c[1]
            local count = Item.get_stack_count(self, item)
            if count > 0 then
                local func = c[2]
                func(self, args[2].value, count)   -- Attacker, Damager attack_info, Stack count
            end
        end
    end
end
Callback.add("onAttackCreate", "RMT.onShoot", onShoot, true)


function onHit(self, other, result, args)
    if callbacks["onHit"] then
        for _, c in ipairs(callbacks["onHit"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value, args[3].value, self.attack_info, count)   -- Attacker, Victim, Damager attack_info, Stack count
            end
        end
    end
end
Callback.add("onHitProc", "RMT.onHit", onHit, true)


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
Callback.add("onKillProc", "RMT.onKill", onKill, true)


function onDamaged(self, other, result, args)
    -- log.info(gm.object_get_name(self.object_index))
    -- log.info(gm.object_get_name(other.object_index))
    -- log.info(result.value)
    -- for _, a in ipairs(args) do
    --     log.info(a.value)
    -- end

    if callbacks["onDamaged"] then
        for _, c in ipairs(callbacks["onDamaged"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value, args[3].value.attack_info, count)   -- Victim, Damager attack_info, Stack count
            end
        end
    end
end
Callback.add("onDamagedProc", "RMT.onDamaged", onDamaged, true)



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value)
        end
    end
end)