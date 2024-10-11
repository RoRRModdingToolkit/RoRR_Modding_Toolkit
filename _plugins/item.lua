-- Item

Item = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}
local other_callbacks = {
    "onStatRecalc",
    "onPostStatRecalc",
    "onBasicUse",
    "onAttack",
    "onAttackAll",
    "onPostAttack",
    "onPostAttackAll",
    "onHit",
    "onHitAll",
    "onKill",
    "onDamaged",
    "onDamageBlocked",
    "onHeal",
    "onShieldBreak",
    "onInteract",
    "onEquipmentUse",
    "onNewStage",
    "onStep",
    "onDraw"
}

local has_custom_item = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== Enums ==========

Item.ARRAY = {
    namespace       = 0,
    identifier      = 1,
    token_name      = 2,
    token_text      = 3,
    on_acquired     = 4,
    on_removed      = 5,
    tier            = 6,
    sprite_id       = 7,
    object_id       = 8,
    item_log_id     = 9,
    achievement_id  = 10,
    is_hidden       = 11,
    effect_display  = 12,
    actor_component = 13,
    loot_tags       = 14,
    is_new_item     = 15
}


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
    category_damage                 = 1 << 0,
    category_healing                = 1 << 1,
    category_utility                = 1 << 2,
    equipment_blacklist_enigma      = 1 << 3,
    equipment_blacklist_chaos       = 1 << 4,
    equipment_blacklist_activator   = 1 << 5,
    item_blacklist_engi_turrets     = 1 << 6,
    item_blacklist_vendor           = 1 << 7,
    item_blacklist_infuser          = 1 << 8
}


Item.TYPE = {
    all         = 0,
    real        = 1,
    temporary   = 2
}



-- ========== Static Methods ==========

Item.new = function(namespace, identifier, no_log)
    local item = Item.find(namespace, identifier)
    if item then return item end

    -- Create item
    local item = gm.item_create(
        namespace,
        identifier,
        nil,
        Item.TIER.notier,
        gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0
    )

    -- Make item abstraction
    local abstraction = Item.wrap(item)

    -- Create item log
    if not no_log then
        local log = gm.item_log_create(
            namespace,
            identifier,
            nil,
            nil,
            abstraction.object_id
        )

        abstraction.item_log_id = log
    end

    -- Add onPickup callback to add actor to has_custom_item table
    abstraction:add_callback("onPickup", function(actor, stack)
        if not Helper.table_has(has_custom_item, actor.value) then
            table.insert(has_custom_item, actor.value)
        end
    end)

    return abstraction
end


Item.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local item = gm.item_find(namespace)

    if item then return Item.wrap(item) end
    return nil
end


Item.find_all = function(filter)
    local items = {}

    local ind = 1   -- namespace
    if type(filter) == "number" then ind = 7 end    -- tier

    for i, item in ipairs(Class.ITEM) do
        if item[ind] == filter then
            table.insert(items, Item.wrap(i - 1))
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
    for i, _ in ipairs(Class.ITEM) do
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


Item.wrap = function(item_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Item",
        value = item_id
    }
    setmetatable(abstraction, metatable_item)
    return abstraction
end


Item.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end



-- ========== Instance Methods ==========

methods_item = {

    create = function(self, x, y, target)
        if not self.object_id then return nil end

        gm.item_drop_object(self.object_id, x, y, Wrap.unwrap(target), false)

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
    

    add_callback = function(self, callback, func, all_damage)
        if all_damage then callback = callback.."All" end

        if callback == "onPickup" then
            local callback_id = self.on_acquired
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
    
        elseif callback == "onRemove" then
            local callback_id = self.on_removed
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        elseif Helper.table_has(other_callbacks, callback) then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {self.value, func})

        else log.error("Invalid callback name", 2)

        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_acquired] = nil
        callbacks[self.on_removed] = nil

        for _, c in ipairs(other_callbacks) do
            local c_table = callbacks[c]
            if c_table then
                for i, v in ipairs(c_table) do
                    if v[1] == self.value then
                        table.remove(c_table, i)
                    end
                end
            end
        end

        -- Add onPickup callback to add actor to has_custom_item table
        self:add_callback("onPickup", function(actor, stack)
            if not Helper.table_has(has_custom_item, actor.value) then
                table.insert(has_custom_item, actor.value)
            end
        end)
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


    toggle_loot = function(self, enabled)
        if enabled == nil then return end

        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        local item_array = Class.ITEM:get(self.value)
        local obj = item_array:get(8)
        
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


methods_item_callbacks = {

    onPickup            = function(self, func) self:add_callback("onPickup", func) end,
    onRemove            = function(self, func) self:add_callback("onRemove", func) end,
    onStatRecalc        = function(self, func) self:add_callback("onStatRecalc", func) end,
    onPostStatRecalc    = function(self, func) self:add_callback("onPostStatRecalc", func) end,
    onBasicUse          = function(self, func) self:add_callback("onBasicUse", func) end,
    onAttack            = function(self, func, all_damage) self:add_callback("onAttack", func, all_damage) end,
    onPostAttack        = function(self, func, all_damage) self:add_callback("onPostAttack", func, all_damage) end,
    onHit               = function(self, func, all_damage) self:add_callback("onHit", func, all_damage) end,
    onKill              = function(self, func) self:add_callback("onKill", func) end,
    onDamaged           = function(self, func) self:add_callback("onDamaged", func) end,
    onDamageBlocked     = function(self, func) self:add_callback("onDamageBlocked", func) end,
    onHeal              = function(self, func) self:add_callback("onHeal", func) end,
    onShieldBreak       = function(self, func) self:add_callback("onShieldBreak", func) end,
    onInteract          = function(self, func) self:add_callback("onInteract", func) end,
    onEquipmentUse      = function(self, func) self:add_callback("onEquipmentUse", func) end,
    onNewStage          = function(self, func) self:add_callback("onNewStage", func) end,
    onStep              = function(self, func) self:add_callback("onStep", func) end,
    onDraw              = function(self, func) self:add_callback("onDraw", func) end

}



-- ========== Metatables ==========

metatable_item_gs = {
    -- Getter
    __index = function(table, key)
        local index = Item.ARRAY[key]
        if index then
            local item_array = Class.ITEM:get(table.value)
            return item_array:get(index)
        end
        log.error("Non-existent item property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Item.ARRAY[key]
        if index then
            local item_array = Class.ITEM:get(table.value)
            item_array:set(index, value)
            return
        end
        log.error("Non-existent item property", 2)
    end
}


metatable_item_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_item_callbacks[key] then
            return methods_item_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_item_gs.__index(table, key)
    end
}


metatable_item = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_item[key] then
            return methods_item[key]
        end

        -- Pass to next metatable
        return metatable_item_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_item_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onPickup and onRemove
    if callbacks[args[1].value] then
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value), args[3].value)
        end
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    if callbacks["onStatRecalc"] then
        for _, fn in ipairs(callbacks["onStatRecalc"]) do
            local count = actor:item_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, count)   -- Actor, Stack count
            end
        end
    end
    actor:get_data().post_stat_recalc = true
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if args[1].value ~= 0.0 or gm.array_get(self.skills, 0).active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for _, fn in ipairs(callbacks["onBasicUse"]) do
            local actor = Instance.wrap(self)
            local count = actor:item_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, count)   -- Actor, Stack count
            end
        end
    end
end)


gm.post_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for _, fn in ipairs(callbacks["onHeal"]) do
            local actor = Instance.wrap(args[1].value)
            local count = actor:item_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, args[2].value, count)   -- Actor, Heal amount, Stack count
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
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
    if callbacks["onPostStatRecalc"] then
        for _, fn in ipairs(callbacks["onPostStatRecalc"]) do
            local count = actor:item_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, count)   -- Actor, Stack count
            end
        end
    end
end


local function item_onAttack(self, other, result, args)
    if not args[2].value.proc or not Instance.exists(args[2].value.parent) then return end
    if callbacks["onAttack"] then
        for _, c in ipairs(callbacks["onAttack"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value.parent)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(args[2].value), count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onAttackAll(self, other, result, args)
    if not Instance.exists(args[2].value.parent) then return end
    if callbacks["onAttackAll"] then
        for _, c in ipairs(callbacks["onAttackAll"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value.parent)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(args[2].value), count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttack"] then
        for _, c in ipairs(callbacks["onPostAttack"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value.parent)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(args[2].value), count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onPostAttackAll(self, other, result, args)
    if not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttackAll"] then
        for _, c in ipairs(callbacks["onPostAttackAll"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value.parent)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(args[2].value), count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onHit(self, other, result, args)
    if callbacks["onHit"] then
        for _, c in ipairs(callbacks["onHit"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Instance.wrap(args[3].value), Damager.wrap(self.attack_info), count) -- Attacker, Victim, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onHitAll(self, other, result, args)
    local attack = args[2].value
    if not Instance.exists(attack.inflictor) then return end
    if callbacks["onHitAll"] then
        for _, c in ipairs(callbacks["onHitAll"]) do
            local item = c[1]
            local actor = Instance.wrap(attack.inflictor)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Instance.wrap(attack.target_true), Damager.wrap(attack.attack_info), count) -- Attacker, Victim, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onKill(self, other, result, args)
    if callbacks["onKill"] then
        for _, c in ipairs(callbacks["onKill"]) do
            local item = c[1]
            local actor = Instance.wrap(args[3].value)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Instance.wrap(args[2].value), count)   -- Attacker, Victim, Stack count
            end
        end
    end
end


local function item_onDamaged(self, other, result, args)
    if not args[3].value.attack_info then return end
    if callbacks["onDamaged"] then
        for _, c in ipairs(callbacks["onDamaged"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(args[3].value.attack_info), count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for _, c in ipairs(callbacks["onDamageBlocked"]) do
            local item = c[1]
            local actor = Instance.wrap(self)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Damager.wrap(other.attack_info), count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        for _, c in ipairs(callbacks["onInteract"]) do
            local item = c[1]
            local actor = Instance.wrap(args[3].value)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Instance.wrap(args[2].value), count)   -- Actor, Interactable, Stack count
            end
        end
    end
end


local function item_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for _, c in ipairs(callbacks["onEquipmentUse"]) do
            local item = c[1]
            local actor = Instance.wrap(args[2].value)
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, Equipment.wrap(args[3].value), count)   -- Actor, Equipment ID, Stack count
            end
        end
    end
end


local function item_onNewStage(self, other, result, args)
    if callbacks["onNewStage"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onNewStage"]) do
                    local actor = Instance.wrap(a)
                    local count = actor:item_stack_count(c[1])
                    if count > 0 then
                        c[2](actor, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end
end


local function item_onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onStep"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onStep"]) do
                    local actor = Instance.wrap(a)
                    local count = actor:item_stack_count(c[1])
                    if count > 0 then
                        c[2](actor, count)  -- Actor, Stack count
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
                        local actor = Instance.wrap(a)
                        local count = actor:item_stack_count(c[1])
                        if count > 0 then
                            c[2](actor, count)  -- Actor, Stack count
                        end
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end
end


local function item_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    if callbacks["onDraw"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onDraw"]) do
                    local actor = Instance.wrap(a)
                    local count = actor:item_stack_count(c[1])
                    if count > 0 then
                        c[2](actor, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_item, n)
            end
        end
    end
end



-- ========== Initialize ==========

Item.__initialize = function()
    Callback.add("onAttackCreate", "RMT.item_onAttack", item_onAttack, true)
    Callback.add("onAttackCreate", "RMT.item_onAttackAll", item_onAttackAll, true)
    Callback.add("onAttackHandleEnd", "RMT.item_onPostAttack", item_onPostAttack, true)
    Callback.add("onAttackHandleEnd", "RMT.item_onPostAttackAll", item_onPostAttackAll, true)
    Callback.add("onHitProc", "RMT.item_onHit", item_onHit, true)
    Callback.add("onAttackHit", "RMT.item_onHitAll", item_onHitAll, true)
    Callback.add("onKillProc", "RMT.item_onKill", item_onKill, true)
    Callback.add("onDamagedProc", "RMT.item_onDamaged", item_onDamaged, true)
    Callback.add("onDamageBlocked", "RMT.item_onDamageBlocked", item_onDamageBlocked, true)
    Callback.add("onInteractableActivate", "RMT.item_onInteract", item_onInteract, true)
    Callback.add("onEquipmentUse", "RMT.item_onEquipmentUse", item_onEquipmentUse, true)
    Callback.add("onStageStart", "RMT.item_onNewStage", item_onNewStage, true)
    Callback.add("preStep", "RMT.item_onStep", item_onStep, true)
    Callback.add("postHUDDraw", "RMT.item_onDraw", item_onDraw, true)
end