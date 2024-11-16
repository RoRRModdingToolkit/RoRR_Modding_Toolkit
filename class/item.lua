-- Item

Item = class_refs["Item"]

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


Item.TYPE = Proxy.new({
    all         = 0,
    real        = 1,
    temporary   = 2
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

    -- Add onPickup callback to add actor to has_custom_item table
    item:onPickup(function(actor, stack)
        if not Helper.table_has(has_custom_item, actor.value) then
            table.insert(has_custom_item, actor.value)
        end
    end)
    
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
        if item[ind] == filter then
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
        if not self.object_id then return nil end

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
    

    add_callback = function(self, callback, func, all_damage)
        if all_damage then callback = callback.."All" end

        local callback_id = nil
        if      callback == "onPickup" then callback_id = self.on_acquired
        elseif  callback == "onRemove" then callback_id = self.on_removed
        end

        if callback_id then
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
        self:onPickup(function(actor, stack)
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
    end,


    -- Callbacks
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


    __metatable = "item"
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


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    local actor = Instance.wrap(self)

    if callbacks["onPreStep"] then
        for _, c in ipairs(callbacks["onPreStep"]) do
            local count = actor:item_stack_count(c[1])
            if count > 0 then
                c[2](actor, count)  -- Actor, Stack count
            end
        end
    end

    if self.shield and self.shield > 0.0 then self.RMT_has_shield_item = true end
    if self.RMT_has_shield_item and self.shield <= 0.0 then
        self.RMT_has_shield_item = nil
        if callbacks["onShieldBreak"] then
            for _, c in ipairs(callbacks["onPreStep"]) do
                local count = actor:item_stack_count(c[1])
                if count > 0 then
                    c[2](actor, count)  -- Actor, Stack count
                end
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onStep"] then
        local actor = Instance.wrap(self)
        for _, c in ipairs(callbacks["onStep"]) do
            local count = actor:item_stack_count(c[1])
            if count > 0 then
                c[2](actor, count)  -- Actor, Stack count
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if callbacks["onPreDraw"] then
        local actor = Instance.wrap(self)
        for _, c in ipairs(callbacks["onPreDraw"]) do
            local count = actor:item_stack_count(c[1])
            if count > 0 then
                c[2](actor, count)  -- Actor, Stack count
            end
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if callbacks["onDraw"] then
        local actor = Instance.wrap(self)
        for _, c in ipairs(callbacks["onDraw"]) do
            local count = actor:item_stack_count(c[1])
            if count > 0 then
                c[2](actor, count)  -- Actor, Stack count
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
        local actor = Instance.wrap(args[2].value.parent)
        local damager = Damager.wrap(args[2].value)
        for _, c in ipairs(callbacks["onAttack"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onAttackAll(self, other, result, args)
    if not Instance.exists(args[2].value.parent) then return end
    if callbacks["onAttackAll"] then
        local actor = Instance.wrap(args[2].value.parent)
        local damager = Damager.wrap(args[2].value)
        for _, c in ipairs(callbacks["onAttackAll"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttack"] then
        local actor = Instance.wrap(args[2].value.parent)
        local damager = Damager.wrap(args[2].value)
        for _, c in ipairs(callbacks["onPostAttack"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onPostAttackAll(self, other, result, args)
    if not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttackAll"] then
        local actor = Instance.wrap(args[2].value.parent)
        local damager = Damager.wrap(args[2].value)
        for _, c in ipairs(callbacks["onPostAttackAll"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)    -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onHit(self, other, result, args)
    if callbacks["onHit"] then
        local actor = Instance.wrap(args[2].value)
        local victim = Instance.wrap(args[3].value)
        local damager = Damager.wrap(args[4].value.attack_info)
        damager.instance = args[4].value.inflictor
        for _, c in ipairs(callbacks["onHit"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, victim, damager, count, args[4].value) -- Attacker, Victim, Damager attack_info, Stack count, hit_info
            end
        end
    end
end


local function item_onHitAll(self, other, result, args)
    local attack = args[2].value
    if not Instance.exists(attack.inflictor) then return end
    if callbacks["onHitAll"] then
        local actor = Instance.wrap(attack.inflictor)
        local victim = Instance.wrap(attack.target_true)
        local damager = Damager.wrap(attack.attack_info)
        damager.instance = attack
        for _, c in ipairs(callbacks["onHitAll"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, victim, damager, count, attack) -- Attacker, Victim, Damager attack_info, Stack count, hit_info
            end
        end
    end
end


local function item_onKill(self, other, result, args)
    if callbacks["onKill"] then
        local actor = Instance.wrap(args[3].value)
        local victim = Instance.wrap(args[2].value)
        for _, c in ipairs(callbacks["onKill"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, victim, count)   -- Attacker, Victim, Stack count
            end
        end
    end
end


local function item_onDamaged(self, other, result, args)
    if not args[3].value.attack_info then return end
    if callbacks["onDamaged"] then
        local actor = Instance.wrap(args[2].value)
        local damager = Damager.wrap(args[3].value.attack_info)
        damager.instance = args[3].value
        for _, c in ipairs(callbacks["onDamaged"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        local actor = Instance.wrap(self)
        local damager = Damager.wrap(other.attack_info)
        damager.instance = other
        for _, c in ipairs(callbacks["onDamageBlocked"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, damager, count)   -- Actor, Damager attack_info, Stack count
            end
        end
    end
end


local function item_onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        local actor = Instance.wrap(args[3].value)
        local interactable = Instance.wrap(args[2].value)
        for _, c in ipairs(callbacks["onInteract"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, interactable, count)   -- Actor, Interactable, Stack count
            end
        end
    end
end


local function item_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        local actor = Instance.wrap(args[2].value)
        local equip = Equipment.wrap(args[3].value)
        for _, c in ipairs(callbacks["onEquipmentUse"]) do
            local item = c[1]
            local count = actor:item_stack_count(item)
            if count > 0 then
                local func = c[2]
                func(actor, equip, count)   -- Actor, Equipment ID, Stack count
            end
        end
    end
end


local function item_onNewStage(self, other, result, args)
    if callbacks["onNewStage"] then
        for n, a in ipairs(has_custom_item) do
            if Instance.exists(a) then
                local actor = Instance.wrap(a)
                for _, c in ipairs(callbacks["onNewStage"]) do
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


-- local function item_onStep(self, other, result, args)
--     if gm.variable_global_get("pause") then return end
    
--     if callbacks["onStep"] then
--         for n, a in ipairs(has_custom_item) do
--             if Instance.exists(a) then
--                 local actor = Instance.wrap(a)
--                 for _, c in ipairs(callbacks["onStep"]) do
--                     local count = actor:item_stack_count(c[1])
--                     if count > 0 then
--                         c[2](actor, count)  -- Actor, Stack count
--                     end
--                 end
--             else table.remove(has_custom_item, n)
--             end
--         end
--     end

--     if callbacks["onShieldBreak"] then
--         for n, a in ipairs(has_custom_item) do
--             if Instance.exists(a) then
--                 if a.shield and a.shield > 0.0 then a.RMT_has_shield = true end
--                 if a.RMT_has_shield and a.shield <= 0.0 then
--                     a.RMT_has_shield = nil
--                     local actor = Instance.wrap(a)
--                     for _, c in ipairs(callbacks["onShieldBreak"]) do
--                         local count = actor:item_stack_count(c[1])
--                         if count > 0 then
--                             c[2](actor, count)  -- Actor, Stack count
--                         end
--                     end
--                 end
--             else table.remove(has_custom_item, n)
--             end
--         end
--     end
-- end


-- local function item_onDraw(self, other, result, args)
--     if gm.variable_global_get("pause") then return end

--     if callbacks["onDraw"] then
--         for n, a in ipairs(has_custom_item) do
--             if Instance.exists(a) then
--                 local actor = Instance.wrap(a)
--                 for _, c in ipairs(callbacks["onDraw"]) do
--                     local count = actor:item_stack_count(c[1])
--                     if count > 0 then
--                         c[2](actor, count)  -- Actor, Stack count
--                     end
--                 end
--             else table.remove(has_custom_item, n)
--             end
--         end
--     end
-- end



-- ========== Initialize ==========

Callback.add("onAttackCreate", "RMT-item_onAttack", item_onAttack)
Callback.add("onAttackCreate", "RMT-item_onAttackAll", item_onAttackAll)
Callback.add("onAttackHandleEnd", "RMT-item_onPostAttack", item_onPostAttack)
Callback.add("onAttackHandleEnd", "RMT-item_onPostAttackAll", item_onPostAttackAll)
Callback.add("onHitProc", "RMT-item_onHit", item_onHit)
Callback.add("onAttackHit", "RMT-item_onHitAll", item_onHitAll)
Callback.add("onKillProc", "RMT-item_onKill", item_onKill)
Callback.add("onDamagedProc", "RMT-item_onDamaged", item_onDamaged)
Callback.add("onDamageBlocked", "RMT-item_onDamageBlocked", item_onDamageBlocked)
Callback.add("onInteractableActivate", "RMT-item_onInteract", item_onInteract)
Callback.add("onEquipmentUse", "RMT-item_onEquipmentUse", item_onEquipmentUse)
Callback.add("onStageStart", "RMT-item_onNewStage", item_onNewStage)
-- Callback.add("preStep", "RMT-item_onStep", item_onStep)
-- Callback.add("postHUDDraw", "RMT-item_onDraw", item_onDraw)



return Item