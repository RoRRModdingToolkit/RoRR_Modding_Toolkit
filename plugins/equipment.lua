-- Equipment

Equipment = {}

local callbacks = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== General Functions ==========

Equipment.find = function(namespace, identifier)
    if not identifier then return gm.equipment_find(namespace) end
    return gm.equipment_find(namespace.."-"..identifier)
end


Equipment.toggle_loot = function(equipment, enabled)
    if enabled == nil then return end

    local loot_pools = gm.variable_global_get("treasure_loot_pools")

    local equip_array = gm.array_get(Class.EQUIPMENT, equipment)
    local obj = gm.array_get(equip_array, 8)
    
    if enabled then
        if disabled_loot[equipment] then
            -- Add back to loot pools
            for _, pool_id in ipairs(disabled_loot[equipment]) do
                gm.ds_list_add(gm.array_get(loot_pools, pool_id).drop_pool, obj)
                if not Helper.table_has(loot_toggled, pool_id) then
                    table.insert(loot_toggled, pool_id)
                end
            end

            disabled_loot[equipment] = nil
        end

    else
        if not disabled_loot[equipment] then
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

            disabled_loot[equipment] = pools
        end

    end
end



-- ========== Custom Equipment Functions ==========

Equipment.create = function(namespace, identifier)
    if Equipment.find(namespace, identifier) then return nil end

    -- Create equipment
    local equipment = gm.equipment_create(
        namespace,
        identifier,
        gm.array_length(Class.EQUIPMENT),   -- class_equipment index
        3.0,    -- tier (3 is equipment)
        gm.object_add_w(namespace, identifier, gm.constants.pPickupEquipment),  -- pickup object
        0.0,    -- loot tags
        nil,    -- not sure; might be an anon function call
        45.0,   -- cooldown
        true,   -- ? (most have this)
        6.0,    -- ? (most have this)
        nil,    -- ? (most have this)
        nil     -- ? (most have this)
    )

    -- Have to manually increase this variable for some reason (class_equipment array length)
    gm.variable_global_set("count_equipment", gm.variable_global_get("count_equipment") + 1.0)

    local item_log_order = gm.variable_global_get("item_log_display_list")

    -- Remove previous item log position (if found)
    local array = gm.array_get(Class.EQUIPMENT, equipment)
    local pos = gm.ds_list_find_index(item_log_order, gm.array_get(array, 9))
    if pos >= 0 then gm.ds_list_delete(item_log_order, pos) end

    -- Set item log position
    local pos = 0
    for i = 0, gm.ds_list_size(item_log_order) - 1 do
        local log_id = gm.ds_list_find_value(item_log_order, i)
        local log_ = gm.array_get(Class.ITEM_LOG, log_id)
        local equip_id = Equipment.find(gm.array_get(log_, 0), gm.array_get(log_, 1))
        if equip_id then
            local equip_array = gm.array_get(Class.EQUIPMENT, equip_id)
            local rarity = gm.array_get(equip_array, 6)
            if rarity == 3.0 then pos = i end
        end
    end
    gm.ds_list_insert(item_log_order, pos + 1, array[10])

    return equipment
end


Equipment.set_sprite = function(equipment, sprite)
    -- Set class_equipment sprite
    local array = gm.array_get(Class.EQUIPMENT, equipment)
    gm.array_set(array, 7, sprite)

    -- Set equipment object sprite
    local obj = gm.array_get(array, 8)
    gm.object_set_sprite_w(obj, sprite)

    -- Set equipment log sprite
    local log_id = gm.array_get(array, 9)
    if log_id then
        local log_array = gm.array_get(Class.ITEM_LOG, log_id)
        gm.array_set(log_array, 9, sprite)
    end
end


Equipment.set_cooldown = function(equipment, cooldown)
    local array = gm.array_get(Class.EQUIPMENT, equipment)
    gm.array_set(array, 5, cooldown * 60.0)
end


Equipment.set_loot_tags = function(equipment, ...)
    local tags = 0
    for _, t in ipairs{...} do tags = tags + t end

    local array = gm.array_get(Class.EQUIPMENT, equipment)
    gm.array_set(array, 12, tags)
end


Equipment.add_achievement = function(equipment, progress_req, single_run)
    local array = gm.array_get(Class.EQUIPMENT, equipment)

    local ach = gm.achievement_create(gm.array_get(array, 0), gm.array_get(array, 1))
    gm.achievement_set_unlock_equipment(ach, equipment)
    gm.achievement_set_requirement(ach, progress_req or 1)

    if single_run then
        local ach_array = gm.array_get(Class.ACHIEVEMENT, ach)
        gm.array_set(ach_array, 21, single_run)
    end
end


Equipment.progress_achievement = function(equipment, amount)
    local array = gm.array_get(Class.EQUIPMENT, equipment)

    if gm.achievement_is_unlocked(array[11]) then return end
    gm.achievement_add_progress(array[11], amount or 1)
end


Equipment.add_callback = function(equipment, callback, func)
    local array = gm.array_get(Class.EQUIPMENT, equipment)

    if callback == "onUse" then
        if not callbacks[array[5]] then callbacks[array[5]] = {} end
        table.insert(callbacks[array[5]], func)

    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value)
        end
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Sort loot tables that have been added to
    for _, pool_id in ipairs(loot_toggled) do
        local loot_pools = gm.variable_global_get("treasure_loot_pools")

        -- Get equipment IDs from objects and sort
        local ids = gm.ds_list_create()
        local pool = gm.array_get(loot_pools, pool_id).drop_pool
        local size = gm.ds_list_size(pool)
        for i = 0, size - 1 do
            local obj = gm.ds_list_find_value(pool, i)
            gm.ds_list_add(ids, gm.object_to_equipment(obj))
        end
        gm.ds_list_sort(ids, true)

        -- Add objects of sorted IDs back into loot pool
        gm.ds_list_clear(pool)
        for i = 0, size - 1 do
            local id = gm.ds_list_find_value(ids, i)
            local _equip = gm.array_get(Class.EQUIPMENT, id)
            local obj = gm.array_get(_equip, 8)
            gm.ds_list_add(pool, obj)
        end
        gm.ds_list_destroy(ids)
    end
    loot_toggled = {}
end)