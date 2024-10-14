-- Equipment

Equipment = class_refs["Equipment"]

local callbacks = {}
local other_callbacks = {
    "onPickup",
    "onDrop",
    "onStatRecalc",
    "onPostStatRecalc",
    "onStep",
    "onDraw"
}

local is_passive = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== Static Methods ==========

Equipment.new = function(namespace, identifier)
    local equip = Equipment.find(namespace, identifier)
    if equip then return equip end

    -- Create equipment
    local equipment = Equipment.wrap(
        gm.equipment_create(
            namespace,
            identifier,
            Class.EQUIPMENT:size(),   -- class_equipment index
            Item.TIER.equipment,    -- tier
            gm.object_add_w(namespace, identifier, gm.constants.pPickupEquipment),  -- pickup object
            0.0,    -- loot tags
            nil,    -- not sure; might be an anon function call
            45.0,   -- cooldown
            true,   -- ? (most have this)
            6.0,    -- ? (most have this)
            nil,    -- ? (most have this)
            nil     -- ? (most have this)
        )
    )

    -- Have to manually increase this variable for some reason (class_equipment array length)
    gm.variable_global_set("count_equipment", gm.variable_global_get("count_equipment") + 1.0)


    -- Remove previous item log position (if found)
    local item_log_order = List.wrap(gm.variable_global_get("item_log_display_list"))
    local pos = item_log_order:find(equipment.item_log_id)
    if pos then item_log_order:delete(pos) end

    -- Set item log position
    local pos = 0
    for i, log_id in ipairs(item_log_order) do
        local log_ = Class.ITEM_LOG:get(log_id)
        local iter_item = Equipment.find(log_:get(0), log_:get(1))
        if iter_item and iter_item.tier == 3.0 then pos = i end
    end
    item_log_order:insert(pos, equipment.item_log_id)

    return equipment
end


Equipment.get_random = function()
    local equips = {}

    -- Add valid equipment to table
    for i, _ in ipairs(Class.EQUIPMENT) do
        local equip = Equipment.wrap(i - 1)
        table.insert(equips, equip)
    end

    -- Pick random equipment from table
    return equips[gm.irandom_range(1, #equips)]
end



-- ========== Instance Methods ==========

methods_equipment = {

    create = function(self, x, y, target)
        if not self.object_id then return nil end

        gm.item_drop_object(self.object_id, x, y, target, false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        -- The drop spawns 40 px above y parameter
        local drop = nil
        local drops = Instance.find_all(gm.constants.pPickupEquipment, gm.constants.oCustomObject_pPickupEquipment)
        for _, d in ipairs(drops) do
            if math.abs(d.x - x) <= 1.0 and math.abs(d.y - (y - 40.0)) <= 1.0 then
                drop = d
                d.y = d.y + 40.0
                d.ystart = d.y
                break
            end
        end

        return Instance.wrap(drop)
    end,
    

    add_callback = function(self, callback, func)

        if callback == "onUse" then
            local callback_id = self.on_use
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        elseif Helper.table_has(other_callbacks, callback) then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {self.value, func})

        else log.error("Invalid callback name", 2)

        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_use] = nil

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
    end,


    set_sprite = function(self, sprite)
        -- Set class_equipment sprite
        self.sprite_id = sprite

        -- Set equipment object sprite
        gm.object_set_sprite_w(self.object_id, sprite)

        -- Set equipment log sprite
        if self.item_log_id then
            local log_array = Class.ITEM_LOG:get(self.item_log_id)
            log_array:set(9, sprite)
        end
    end,


    set_loot_tags = function(self, ...)
        local tags = 0
        for _, t in ipairs{...} do tags = tags + t end

        self.loot_tags = tags
    end,


    set_cooldown = function(self, cooldown)
        self.cooldown = cooldown * 60.0
    end,


    set_passive = function(self, bool)
        if bool and not is_passive[self.value] then is_passive[self.value] = true
        elseif not bool and is_passive[self.value] then is_passive[self.value] = nil
        end
    end,


    is_unlocked = function(self)
        return (not self.achievement_id) or gm.achievement_is_unlocked(self.achievement_id)
    end,


    add_achievement = function(self, progress_req, single_run)
        local ach = gm.achievement_create(self.namespace, self.identifier)
        gm.achievement_set_unlock_equipment(ach, self.value)
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
        local equip_array = Class.EQUIPMENT:get(self.value)
        local obj = equip_array:get(8)
        
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
    onDrop              = function(self, func) self:add_callback("onDrop", func) end,
    onUse               = function(self, func) self:add_callback("onUse", func) end,
    onStatRecalc        = function(self, func) self:add_callback("onStatRecalc", func) end,
    onPostStatRecalc    = function(self, func) self:add_callback("onPostStatRecalc", func) end,
    onStep              = function(self, func) self:add_callback("onStep", func) end,
    onDraw              = function(self, func) self:add_callback("onDraw", func) end

}



-- ========== Metatables ==========

metatable_class["Equipment"] = {
    __index = function(table, key)
        -- Methods
        if methods_equipment[key] then
            return methods_equipment[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Equipment"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Equipment"].__newindex(table, key, value)
    end,


    __metatable = "equipment"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onUse
    if callbacks[args[1].value] then
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value))   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    if callbacks["onStatRecalc"] then
        for _, fn in ipairs(callbacks["onStatRecalc"]) do
            if actor.RMT_object == "Player" then
                local equip = actor:get_equipment()
                if equip and equip.value == fn[1] then
                    fn[2](actor)  -- Player
                end
            end
        end
    end
    actor:get_data().post_stat_recalc = true
end)


gm.pre_script_hook(gm.constants.equipment_set, function(self, other, result, args)
    if callbacks["onDrop"] then
        for _, fn in ipairs(callbacks["onDrop"]) do
            local player = Instance.wrap(args[1].value)
            local equip = player:get_equipment()
            if equip and equip.value == fn[1] then
                fn[2](player, Equipment.wrap(args[2].value))  -- Player, New equipment wrapper
            end
        end
    end
end)


gm.post_script_hook(gm.constants.equipment_set, function(self, other, result, args)
    local player = Instance.wrap(args[1].value)
    player:recalculate_stats()
    if callbacks["onPickup"] then
        for _, fn in ipairs(callbacks["onPickup"]) do
            local equip = player:get_equipment()
            if equip and equip.value == fn[1] then
                fn[2](player)  -- Player
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.item_use_equipment, function(self, other, result, args)
    local equip = Instance.wrap(self):get_equipment()
    if equip and is_passive[equip.value] then
        return false
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Sort loot tables that have been added to
    for _, pool_id in ipairs(loot_toggled) do
        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))

        -- Get equipment IDs from objects and sort
        local ids = List.new()
        local drop_pool = List.wrap(loot_pools:get(pool_id).drop_pool)
        for _, obj in ipairs(drop_pool) do
            ids:add(gm.object_to_equipment(obj))
        end
        ids:sort()

        -- Add objects of sorted IDs back into loot pool
        drop_pool:clear()
        for _, id in ipairs(ids) do
            local equip = Class.EQUIPMENT:get(id)
            local obj = equip:get(8)
            drop_pool:add(obj)
        end
        ids:destroy()
    end
    loot_toggled = {}
end)



-- ========== Callbacks ==========

function equipment_onPostStatRecalc(actor)
    if callbacks["onPostStatRecalc"] then
        for _, fn in ipairs(callbacks["onPostStatRecalc"]) do
            if actor.RMT_object == "Player" then
                local equip = actor:get_equipment()
                if equip and equip.value == fn[1] then
                    fn[2](actor)  -- Player
                end
            end
        end
    end
end


local function equipment_onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onStep"] then
        local players = Instance.find_all(gm.constants.oP)
        for n, player in ipairs(players) do
            for _, c in ipairs(callbacks["onStep"]) do
                local equip = player:get_equipment()
                if equip and equip.value == c[1] then
                    c[2](player)  -- Player
                end
            end
        end
    end
end


local function equipment_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    if callbacks["onDraw"] then
        local players = Instance.find_all(gm.constants.oP)
        for n, player in ipairs(players) do
            for _, c in ipairs(callbacks["onDraw"]) do
                local equip = player:get_equipment()
                if equip and equip.value == c[1] then
                    c[2](player)  -- Player
                end
            end
        end
    end
end



-- ========== Initialize ==========

initialize_equipment = function()
    Callback.add("preStep", "RMT-equipment_onStep", equipment_onStep)
    Callback.add("postHUDDraw", "RMT-equipment_onDraw", equipment_onDraw)
end



return Equipment