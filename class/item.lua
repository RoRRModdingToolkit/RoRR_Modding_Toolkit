-- Item

Item = class_refs["Item"]

local callbacks = {}
local valid_callbacks = {
    onAcquire               = true,
    onRemove                = true,
    onPreStep               = true,
    onPostStep              = true,
    onPreDraw               = true,
    onPostDraw              = true,
    onStatRecalc            = true,
    onPostStatRecalc        = true,
    onAttackCreate          = true,
    onAttackCreateProc      = true,
    onAttackHit             = true,
    onAttackHandleEnd       = true,
    onAttackHandleEndProc   = true,
    onDamageCalculate       = true,
    onDamageCalculateProc   = true,
    onHitProc               = true,
    onKillProc              = true,
    onDamagedProc           = true,
    onDamageBlocked         = true,
    onHeal                  = true,
    onShieldBreak           = true,
    onInteractableActivate  = true,
    onPickupCollected       = true,
    onPrimaryUse            = true,
    onSecondaryUse          = true,
    onUtilityUse            = true,
    onSpecialUse            = true,
    onEquipmentUse          = true,
    onStageStart            = true
}

local has_custom_item = {}
local has_callbacks = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== Enums ==========

Item.TIER = Proxy.new({
    common      = 0,
    uncommon    = 1,
    rare        = 2,
    equipment   = 3,
    boss        = 4,
    special     = 5,
    food        = 6,
    notier      = 7
}):lock()


Item.LOOT_TAG = Proxy.new({
    category_damage                 = 1 << 0,
    category_healing                = 1 << 1,
    category_utility                = 1 << 2,
    equipment_blacklist_enigma      = 1 << 3,
    equipment_blacklist_chaos       = 1 << 4,
    equipment_blacklist_activator   = 1 << 5,
    item_blacklist_engi_turrets     = 1 << 6,
    item_blacklist_vendor           = 1 << 7,
    item_blacklist_infuser          = 1 << 8
}):lock()


Item.STACK_KIND = Proxy.new({
    normal          = 0,
    temporary_blue  = 1,
    temporary_red   = 2,
    any             = 3,
    temporary_any   = 4
}):lock()



-- ========== Static Methods ==========

Item.new = function(namespace, identifier, no_log)
    local item = Item.find(namespace, identifier)
    if item then return item end

    -- Create item
    local item = Item.wrap(
        gm.item_create(
            namespace,
            identifier,
            nil,
            Item.TIER.notier,
            gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
            0
        )
    )

    -- Create item log
    if not no_log then
        local log = gm.item_log_create(
            namespace,
            identifier,
            nil,
            nil,
            item.object_id
        )

        item.item_log_id = log
    end
    
    return item
end


Item.find_all = function(filter)
    local items = {}

    local ind = 1   -- namespace
    if type(filter) == "number" then ind = 7 end    -- tier

    local array = Class.ITEM
    local size = #array
    for i = 0, size - 1 do
        local item = array:get(i)
        if (item[ind] == filter)
        or (filter == nil) then
            table.insert(items, Item.wrap(i))
        end
    end

    return items, #items > 0
end


Item.get_random = function(...)
    local tiers = {}
    if ... then
        tiers = {...}
        if type(tiers[1]) == "table" then tiers = tiers[1] end
    end

    local items = {}

    -- Add valid items to table
    local array = Class.ITEM
    for i, _ in ipairs(array) do
        local item = Item.wrap(i - 1)
        if (#tiers <= 0 and item.tier < Item.TIER.notier and item.identifier ~= "dummyItem") or Helper.table_has(tiers, item.tier) then
            table.insert(items, item)
        end
    end

    -- Pick random item from table
    return items[gm.irandom_range(1, #items)]
end


Item.spawn_crate = function(x, y, tier, items)
    local inst = Object.find("ror-generated_CommandCrate_"..tier):create(x, y)

    -- Replace default items with custom set
    if items then
        local arr = Array.new()
        for _, item in ipairs(items) do
            if type(item) ~= "table" then item = Item.wrap(item) end
            arr:push(item.object_id)
        end
        inst.contents = arr
    end

    return inst
end



-- ========== Instance Methods ==========

methods_item = {

    create = function(self, x, y, target)
        if self.object_id == nil
        or self.object_id == -1 then return nil end

        GM.item_drop_object(self.object_id, x, y, target, false)

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
    end,
    

    add_callback = function(self, callback, func)
        -- Add onAcquire callback to add actor to has_custom_item
        local function add_onAcquire()
            if has_callbacks[self.value] then return end
            has_callbacks[self.value] = true
            
            self:onAcquire(function(actor, stack)
                has_custom_item[actor.id] = true
            end)
        end

        local callback_id = nil
        if      callback == "onAcquire"     then callback_id = self.on_acquired
        elseif  callback == "onRemove"      then callback_id = self.on_removed
        end

        if callback_id then
            add_onAcquire()
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        elseif valid_callbacks[callback] then
            add_onAcquire()
            if not callbacks[callback] then callbacks[callback] = {} end
            if not callbacks[callback][self.value] then callbacks[callback][self.value] = {} end
            table.insert(callbacks[callback][self.value], func)

        else log.error("Invalid callback name", 2)
        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_acquired] = nil
        callbacks[self.on_removed] = nil
    
        for callback, _ in pairs(valid_callbacks) do
            local c_table = callbacks[callback]
            if c_table then c_table[self.value] = nil end
        end

        has_callbacks[self.value] = nil
    end,


    set_sprite = function(self, sprite)
        -- Set class_item sprite
        self.sprite_id = sprite

        -- Set item object sprite
        gm.object_set_sprite_w(self.object_id, sprite)

        -- Set item log sprite
        if self.item_log_id then
            local log_array = Class.ITEM_LOG:get(self.item_log_id)
            log_array:set(9, sprite)
        end
    end,


    set_tier = function(self, tier)
        self.tier = tier


        -- Remove from all loot pools that the item is in
        local pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        for _, drop in ipairs(pools) do
            local drop_pool = List.wrap(drop.drop_pool)
            local pos = drop_pool:find(self.object_id)
            if pos then drop_pool:delete(pos) end
        end

        -- Add to new loot pool
        local pool = List.wrap(pools:get(tier).drop_pool)
        pool:add(self.object_id)
        

        -- Remove previous item log position (if found)
        local item_log_order = List.wrap(gm.variable_global_get("item_log_display_list"))
        local pos = item_log_order:find(self.item_log_id)
        if pos then item_log_order:delete(pos) end

        -- Set new item log position
        local pos = 0
        for i, log_id in ipairs(item_log_order) do
            local log_ = Class.ITEM_LOG:get(log_id)
            local iter_item = Item.find(log_:get(0), log_:get(1))
            
            local tier_ = Item.TIER.equipment
            if iter_item then tier_ = iter_item.tier end
            if tier_ > tier then
                pos = i
                break
            end
        end
        item_log_order:insert(pos - 1, self.item_log_id)
    end,


    set_loot_tags = function(self, ...)
        local tags = 0
        for _, t in ipairs{...} do tags = tags + t end

        self.loot_tags = tags
    end,


    is_unlocked = function(self)
        return (not self.achievement_id) or gm.achievement_is_unlocked(self.achievement_id)
    end,


    add_achievement = function(self, progress_req, single_run)
        local ach = gm.achievement_create(self.namespace, self.identifier)
        gm.achievement_set_unlock_item(ach, self.value)
        gm.achievement_set_requirement(ach, progress_req or 1)
    
        if single_run then
            local ach_array = Class.ACHIEVEMENT:get(ach)
            ach_array:set(21, single_run)
        end
    end,


    progress_achievement = function(self, amount)
        if self:is_unlocked() then return end
        gm.achievement_add_progress(self.achievement_id, amount or 1)
    end,


    is_loot = function(self)
        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        local obj = self.object_id

        for i = 0, #loot_pools - 1 do
            local drop_pool = List.wrap(loot_pools:get(i).drop_pool)
            local pos = drop_pool:find(obj)
            if pos then return true end
        end

        return false
    end,


    toggle_loot = function(self, enabled)
        if enabled == nil then return end

        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        local obj = self.object_id
        
        if enabled then
            if disabled_loot[self.value] then
                -- Add back to loot pools
                for _, pool_id in ipairs(disabled_loot[self.value]) do
                    local drop_pool = List.wrap(loot_pools:get(pool_id).drop_pool)
                    drop_pool:add(obj)

                    if not Helper.table_has(loot_toggled, pool_id) then
                        table.insert(loot_toggled, pool_id)
                    end
                end

                disabled_loot[self.value] = nil
            end

        else
            if not disabled_loot[self.value] then
                -- Remove from loot pools
                -- and store the pool indexes
                local pools = {}
                
                for i = 0, #loot_pools - 1 do
                    local drop_pool = List.wrap(loot_pools:get(i).drop_pool)
                    local pos = drop_pool:find(obj)
                    if pos then
                        drop_pool:delete(pos)
                        table.insert(pools, i)
                    end
                end

                disabled_loot[self.value] = pools
            end

        end
    end

}

-- Callbacks
for c, _ in pairs(valid_callbacks) do
    methods_item[c] = function(self, func)
        self:add_callback(c, func)
    end
end



-- ========== Metatables ==========

metatable_class["Item"] = {
    __index = function(table, key)
        -- Methods
        if methods_item[key] then
            return methods_item[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Item"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Item"].__newindex(table, key, value)
    end,


    __metatable = "Item"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onAcquire and onRemove
    if callbacks[args[1].value] then
        local actor = Instance.wrap(args[2].value)
        local stack = args[3].value
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(actor, stack)
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_item[self.id] then return end

    local actor = Instance.wrap(self)
    local actorData = actor:get_data("item")

    if callbacks["onPreStep"] then
        for item_id, c_table in pairs(callbacks["onPreStep"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end

    if not callbacks["onShieldBreak"] then return end

    if self.shield and self.shield > 0.0 then actorData.has_shield = true end
    if actorData.has_shield and self.shield <= 0.0 then
        actorData.has_shield = nil

        for item_id, c_table in pairs(callbacks["onShieldBreak"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_item[self.id] then return end
    if not callbacks["onPostStep"] then return end

    local actor = Instance.wrap(self)

    for item_id, c_table in pairs(callbacks["onPostStep"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not has_custom_item[self.id] then return end
    if not callbacks["onPreDraw"] then return end

    local actor = Instance.wrap(self)

    for item_id, c_table in pairs(callbacks["onPreDraw"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not has_custom_item[self.id] then return end
    if not callbacks["onPostDraw"] then return end

    local actor = Instance.wrap(self)

    for item_id, c_table in pairs(callbacks["onPostDraw"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    actor:get_data(nil, _ENV["!guid"]).post_stat_recalc = true

    if not callbacks["onStatRecalc"] then return end
    if not has_custom_item[actor.id] then return end

    for item_id, c_table in pairs(callbacks["onStatRecalc"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    if not callbacks["onDamageCalculate"] then return end

    local actor = Instance.wrap(args[6].value)
    if not Instance.exists(actor) then return end
    if not has_custom_item[actor.id] then return end

    local victim = Instance.wrap(args[2].value)
    local damage = args[4].value
    local hit_info = Hit_Info.wrap(args[1].value)

    if callbacks["onDamageCalculate"] then
        for item_id, c_table in pairs(callbacks["onDamageCalculate"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    local new = fn(actor, victim, stack, damage, hit_info)
                    if type(new) == "number" then damage = new end   -- Replace damage
                end
            end
        end
        args[4].value = damage
    end

    if Helper.is_false(hit_info.proc) then return end

    if callbacks["onDamageCalculateProc"] then
        for item_id, c_table in pairs(callbacks["onDamageCalculateProc"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    local new = fn(actor, victim, stack, damage, hit_info)
                    if type(new) == "number" then damage = new end   -- Replace damage
                end
            end
        end
        args[4].value = damage
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if not has_custom_item[self.id] then return end
    
    local callback = {
        "onPrimaryUse",
        "onSecondaryUse",
        "onUtilityUse",
        "onSpecialUse"
    }
    callback = callback[args[1].value + 1]
    if not callbacks[callback] then return end

    local actor = Instance.wrap(self)
    local active_skill = actor:get_active_skill(args[1].value)

    for item_id, c_table in pairs(callbacks[callback]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, active_skill)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if not callbacks["onHeal"] then return end

    local actor = args[1].value
    if not has_custom_item[actor.id] then return end

    actor = Instance.wrap(actor)
    local heal_amount = args[2].value

    for item_id, c_table in pairs(callbacks["onHeal"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                local new = fn(actor, stack, heal_amount)
                if type(new) == "number" then heal_amount = new end   -- Replace heal_amount
            end
        end
    end
    args[2].value = heal_amount
end)


gm.post_script_hook(gm.constants.__input_system_tick, function()
    -- Sort loot tables that have been added to
    for _, pool_id in ipairs(loot_toggled) do
        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))

        -- Get item IDs from objects and sort
        local ids = List.new()
        local drop_pool = List.wrap(loot_pools:get(pool_id).drop_pool)
        for _, obj in ipairs(drop_pool) do
            ids:add(gm.object_to_item(obj))
        end
        ids:sort()

        -- Add objects of sorted IDs back into loot pool
        drop_pool:clear()
        for _, id in ipairs(ids) do
            local item = Class.ITEM:get(id)
            local obj = item:get(8)
            drop_pool:add(obj)
        end
        ids:destroy()
    end
    loot_toggled = {}
end)



-- ========== Callbacks ==========

function item_onPostStatRecalc(actor)
    if not callbacks["onPostStatRecalc"] then return end
    if not has_custom_item[actor.id] then return end

    for item_id, c_table in pairs(callbacks["onPostStatRecalc"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end


Callback.add("onAttackCreate", "RMT-Item.onAttackCreate", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end
    if not has_custom_item[actor.id] then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackCreate"] then
        for item_id, c_table in pairs(callbacks["onAttackCreate"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackCreateProc"] then
        for item_id, c_table in pairs(callbacks["onAttackCreateProc"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end
end)


Callback.add("onAttackHit", "RMT-Item.onAttackHit", function(self, other, result, args)
    if not callbacks["onAttackHit"] then return end

    local hit_info = Hit_Info.wrap(args[2].value)
    local actor = hit_info.inflictor

    if not Instance.exists(actor) then return end
    if not has_custom_item[actor.id] then return end

    actor = Instance.wrap(actor)
    local victim = Instance.wrap(hit_info.target_true)

    for item_id, c_table in pairs(callbacks["onAttackHit"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack, hit_info)
            end
        end
    end
end)


Callback.add("onAttackHandleEnd", "RMT-Item.onAttackHandleEnd", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end
    if not has_custom_item[actor.id] then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackHandleEnd"] then
        for item_id, c_table in pairs(callbacks["onAttackHandleEnd"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackHandleEndProc"] then
        for item_id, c_table in pairs(callbacks["onAttackHandleEndProc"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end
end)


Callback.add("onHitProc", "RMT-Item.onHitProc", function(self, other, result, args)     -- Runs before onAttackHit
    if not callbacks["onHitProc"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_item[actor.id] then return end

    local victim = Instance.wrap(args[3].value)
    local hit_info = Hit_Info.wrap(args[4].value)

    for item_id, c_table in pairs(callbacks["onHitProc"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack, hit_info)
            end
        end
    end
end)


Callback.add("onKillProc", "RMT-Item.onKillProc", function(self, other, result, args)
    if not callbacks["onKillProc"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_item[actor.id] then return end

    local victim = Instance.wrap(args[2].value)

    for item_id, c_table in pairs(callbacks["onKillProc"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack)
            end
        end
    end
end)


Callback.add("onDamagedProc", "RMT-Item.onDamagedProc", function(self, other, result, args)
    if not callbacks["onDamagedProc"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_item[actor.id] then return end

    local hit_info = Hit_Info.wrap(args[3].value)
    local attacker = Instance.wrap(hit_info.inflictor)

    for item_id, c_table in pairs(callbacks["onDamagedProc"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, attacker, stack, hit_info)
            end
        end
    end
end)


Callback.add("onDamageBlocked", "RMT-Item.onDamageBlocked", function(self, other, result, args)
    if not callbacks["onDamageBlocked"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_item[actor.id] then return end

    local damage = args[4].value
    -- local source = Instance.wrap(other)

    for item_id, c_table in pairs(callbacks["onDamageBlocked"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, damage)
            end
        end
    end
end)


Callback.add("onInteractableActivate", "RMT-Item.onInteractableActivate", function(self, other, result, args)
    if not callbacks["onInteractableActivate"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_item[actor.id] then return end

    local interactable = Instance.wrap(args[2].value)

    for item_id, c_table in pairs(callbacks["onInteractableActivate"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, interactable)
            end
        end
    end
end)


Callback.add("onPickupCollected", "RMT-Item.onPickupCollected", function(self, other, result, args)
    if not callbacks["onPickupCollected"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_item[actor.id] then return end

    local pickup_object = Instance.wrap(args[2].value)  -- Will be oCustomObject_pPickupItem/Equipment for all custom items/equipment

    for item_id, c_table in pairs(callbacks["onPickupCollected"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, pickup_object)
            end
        end
    end
end)


Callback.add("onEquipmentUse", "RMT-Item.onEquipmentUse", function(self, other, result, args)
    if not callbacks["onEquipmentUse"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_item[actor.id] then return end

    local equipment = Equipment.wrap(args[3].value)
    local direction = args[5].value

    for item_id, c_table in pairs(callbacks["onEquipmentUse"]) do
        local stack = actor:item_stack_count(item_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, equipment, direction)
            end
        end
    end
end)


Callback.add("onStageStart", "RMT-Item.onStageStart", function(self, other, result, args)
    for actor_id, _ in pairs(has_custom_item) do
        if not Instance.exists(actor_id) then
            has_custom_item[actor_id] = nil
        end
    end

    if not callbacks["onStageStart"] then return end

    for actor_id, _ in pairs(has_custom_item) do
        local actor = Instance.wrap(actor_id)

        for item_id, c_table in pairs(callbacks["onStageStart"]) do
            local stack = actor:item_stack_count(item_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end
end)



return Item