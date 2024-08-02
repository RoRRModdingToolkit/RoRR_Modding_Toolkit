-- Item
-- Original custom items mod written by GrooveSalad

Item = {}

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



-- ========== General Functions ==========

Item.find = function(namespace, identifier)
    if not identifier then return gm.item_find(namespace) end
    return gm.item_find(namespace.."-"..identifier)
end


Item.find_all = function(...)
    local array = gm.variable_global_get("class_item")
    local tiers = {...}
    local items = {}
    for i = 1, gm.array_length(array) do
        for _, tier in ipairs(tiers) do
            if array[i][7] == tier then
                table.insert(items, i - 1)
                break
            end
        end
    end
    return items
end


Item.get_data = function(item)
    local array = gm.variable_global_get("class_item")
    local item_arr = array[item + 1]
    return {
        namespace       = item_arr[1],
        identifier      = item_arr[2],
        token_name      = item_arr[3],
        token_text      = item_arr[4],
        on_acquired     = item_arr[5],
        on_removed      = item_arr[6],
        tier            = item_arr[7],
        sprite_id       = item_arr[8],
        object_id       = item_arr[9],
        item_log_id     = item_arr[10],
        achievement_id  = item_arr[11],
        is_hidden       = item_arr[12],
        effect_display  = item_arr[13],
        actor_component = item_arr[14],
        loot_tags       = item_arr[15],
        is_new_item     = item_arr[16]
    }
end


Item.get_random = function(...)
    local items = Item.find_all(...)
    return items[gm.irandom_range(1, #items)]
end


Item.get_stack_count = function(actor, item)
    return gm.item_count(actor, item, false) + gm.item_count(actor, item, true)
end



-- ========== Custom Item Functions ==========

Item.create = function(namespace, identifier)
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

    -- Create item log
    local array = gm.variable_global_get("class_item")[item + 1]
    local log = gm.item_log_create(
        namespace,
        identifier,
        nil,
        nil,
        array[9]
    )

    -- Set item log ID into item array
    gm.array_set(array, 9, log)

    return item
end


Item.set_sprite = function(item, sprite)
    -- Set class_item sprite
    local array = gm.variable_global_get("class_item")[item + 1]
    gm.array_set(array, 7, sprite)

    -- Set item object sprite
    local obj = array[9]
    gm.object_set_sprite_w(obj, sprite)

    -- Set item log sprite
    local log_array = gm.variable_global_get("class_item_log")[array[10] + 1]
    gm.array_set(log_array, 9, sprite)
end


Item.set_tier = function(item, tier)
    -- Set class_item tier
    local array = gm.variable_global_get("class_item")[item + 1]
    gm.array_set(array, 6, tier)

    local obj = array[9]
    local pools = gm.variable_global_get("treasure_loot_pools")

    -- Remove from all loot pools (if found)
    for _, p in ipairs(pools) do
        local drops = p.drop_pool
        local pos = gm.ds_list_find_index(obj)
        if pos >= 0 then gm.ds_list_delete(drops, pos) end
    end

    -- Add to new loot pool
    local pool = pools[tier + 1]
    local drops = pool.drop_pool
    gm.ds_list_add(drops, obj)
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
        or callback == "onPostShoot"
        or callback == "onHit"
        or callback == "onKill"
        or callback == "onDamaged"
        or callback == "onDamageBlocked"
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

function onShoot(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks["onShoot"] then
        for _, c in ipairs(callbacks["onShoot"]) do
            local item = c[1]
            local count = Item.get_stack_count(self, item)
            if count > 0 then
                local func = c[2]
                func(self, args[2].value, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end
Callback.add("onAttackCreate", "RMT.onShoot", onShoot, true)


function onPostShoot(self, other, result, args)
    if not args[2].value.proc or not args[2].value.parent then return end
    if callbacks["onPostShoot"] then
        for _, c in ipairs(callbacks["onPostShoot"]) do
            local item = c[1]
            local count = Item.get_stack_count(args[2].value.parent, item)
            if count > 0 then
                local func = c[2]
                func(args[2].value.parent, args[2].value, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end
Callback.add("onAttackHandleEnd", "RMT.onPostShoot", onPostShoot, true)


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
Callback.add("onDamagedProc", "RMT.onDamaged", onDamaged, true)


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
Callback.add("onDamageBlocked", "RMT.onDamageBlocked", onDamageBlocked, true)


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
Callback.add("onInteractableActivate", "RMT.onInteract", onInteract, true)


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
Callback.add("onEquipmentUse", "RMT.onEquipmentUse", onEquipmentUse, true)


function onStep(self, other, result, args)
    if callbacks["onStep"] then
        for _, c in ipairs(callbacks["onStep"]) do
            local actors = Instance.find_all(gm.constants.pActor)
            for _, a in ipairs(actors) do
                local item = c[1]
                local count = Item.get_stack_count(a, item)
                if count > 0 then
                    local func = c[2]
                    func(a, count)  -- Actor, Stack count
                end
            end
        end
    end
end
Callback.add("preStep", "RMT.onStep", onStep, true)


function onDraw(self, other, result, args)
    if callbacks["onDraw"] then
        for _, c in ipairs(callbacks["onDraw"]) do
            local actors = Instance.find_all(gm.constants.pActor)
            for _, a in ipairs(actors) do
                local item = c[1]
                local count = Item.get_stack_count(a, item)
                if count > 0 then
                    local func = c[2]
                    func(a, count)  -- Actor, Stack count
                end
            end
        end
    end
end
Callback.add("onHUDDraw", "RMT.onDraw", onDraw, true)



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value)
        end
    end
end)