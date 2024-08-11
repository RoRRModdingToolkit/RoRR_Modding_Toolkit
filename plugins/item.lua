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
    local drops = Instance.find_all(gm.constants.oCustomObject_pPickupItem)
    for _, d in ipairs(drops) do
        if math.abs(d.x - x) <= 1.0 and math.abs(d.y - (y - 40.0)) <= 1.0 then
            drop = d
            d.y = d.y + 40.0
            break
        end
    end

    return drop
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
    end

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
    if array[10] then
        local log_array = gm.variable_global_get("class_item_log")[array[10] + 1]
        gm.array_set(log_array, 9, sprite)
    end
end


Item.set_tier = function(item, tier)
    -- Set class_item tier
    local class_item = gm.variable_global_get("class_item")
    local array = class_item[item + 1]
    gm.array_set(array, 6, tier)

    local obj = array[9]
    local pools = gm.variable_global_get("treasure_loot_pools")


    -- Remove from all loot pools (if found)
    for _, p in ipairs(pools) do
        local drops = p.drop_pool
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
    local class_item_log = gm.variable_global_get("class_item_log")
    local pos = 0
    for i = 0, gm.ds_list_size(item_log_order) - 1 do
        local log_id = gm.ds_list_find_value(item_log_order, i)
        local log_ = class_item_log[log_id + 1]
        local item_id = Item.find(log_[1], log_[2])
        
        local tier_ = Item.TIER.equipment
        if item_id then tier_ = class_item[item_id + 1][7] end
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



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value)
        end
    end
end)


gm.pre_script_hook(gm.constants.skill_util_update_heaven_cracker, function(self, other, result, args)
    if callbacks["onBasicUse"] then
        for _, fn in pairs(callbacks["onBasicUse"]) do
            local count = Item.get_stack_count(args[1].value, fn[1])
            if count > 0 then
                fn[2](args[1].value, count)   -- Actor, Stack count
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


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if self.shield and self.shield > 0.0 then self.RMT_has_shield = true end
    if self.RMT_has_shield and self.shield <= 0.0 then
        self.RMT_has_shield = nil
        if callbacks["onShieldBreak"] then
            for _, fn in pairs(callbacks["onShieldBreak"]) do
                local count = Item.get_stack_count(self, fn[1])
                if count > 0 then
                    fn[2](self, count)   -- Actor, Stack count
                end
            end
        end
    end
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
    Callback.add("onHUDDraw", "RMT.item_onDraw", onDraw, true)
end