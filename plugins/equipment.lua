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

    local class_equipment = gm.variable_global_get("class_equipment")
    local loot_pools = gm.variable_global_get("treasure_loot_pools")

    local obj = class_equipment[equipment + 1][9]
    
    if enabled then
        if disabled_loot[equipment] then
            -- Add back to loot pools
            for _, pool_id in ipairs(disabled_loot[equipment]) do
                gm.ds_list_add(loot_pools[pool_id].drop_pool, obj)
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

            for i, p in ipairs(loot_pools) do
                local drops = p.drop_pool
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
        gm.array_length(gm.variable_global_get("class_equipment")),   -- class_equipment index
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

    -- Remove previous item log position (if found)
    local class_equipment = gm.variable_global_get("class_equipment")
    local array = class_equipment[equipment + 1]
    local item_log_order = gm.variable_global_get("item_log_display_list")
    local pos = gm.ds_list_find_index(item_log_order, array[10])
    if pos >= 0 then gm.ds_list_delete(item_log_order, pos) end

    -- Set item log position
    local class_item_log = gm.variable_global_get("class_item_log")
    local pos = 0
    for i = 0, gm.ds_list_size(item_log_order) - 1 do
        local log_id = gm.ds_list_find_value(item_log_order, i)
        local log_ = class_item_log[log_id + 1]
        local equip_id = Equipment.find(log_[1], log_[2])
        if equip_id and class_equipment[equip_id + 1][7] == 3.0 then pos = i end
    end
    gm.ds_list_insert(item_log_order, pos + 1, array[10])

    return equipment
end


Equipment.set_sprite = function(equipment, sprite)
    -- Set class_equipment sprite
    local array = gm.variable_global_get("class_equipment")[equipment + 1]
    gm.array_set(array, 7, sprite)

    -- Set equipment object sprite
    local obj = array[9]
    gm.object_set_sprite_w(obj, sprite)

    -- Set equipment log sprite
    if array[10] then
        local log_array = gm.variable_global_get("class_item_log")[array[10] + 1]
        gm.array_set(log_array, 9, sprite)
    end
end


Equipment.set_cooldown = function(equipment, cooldown)
    local array = gm.variable_global_get("class_equipment")[equipment + 1]
    gm.array_set(array, 5, cooldown * 60.0)
end


Equipment.set_loot_tags = function(equipment, ...)
    local tags = 0
    for _, t in ipairs{...} do tags = tags + t end

    local array = gm.variable_global_get("class_equipment")[equipment + 1]
    gm.array_set(array, 12, tags)
end


Equipment.add_achievement = function(equipment, progress_req, single_run)
    local class_equipment = gm.variable_global_get("class_equipment")
    local array = class_equipment[equipment + 1]

    local ach = gm.achievement_create(array[1], array[2])
    gm.achievement_set_unlock_equipment(ach, equipment)
    gm.achievement_set_requirement(ach, progress_req or 1)

    if single_run then
        local class_achievement = gm.variable_global_get("class_achievement")
        local ach_array = class_achievement[ach + 1]
        gm.array_set(ach_array, 21, single_run)
    end
end


Equipment.progress_achievement = function(equipment, amount)
    local class_equipment = gm.variable_global_get("class_equipment")
    local array = class_equipment[equipment + 1]

    if gm.achievement_is_unlocked(array[11]) then return end
    gm.achievement_add_progress(array[11], amount or 1)
end


Equipment.add_callback = function(equipment, callback, func)
    local array = gm.variable_global_get("class_equipment")[equipment + 1]

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
        local class_equipment = gm.variable_global_get("class_equipment")
        local loot_pools = gm.variable_global_get("treasure_loot_pools")

        -- Get equipment IDs from objects and sort
        local ids = gm.ds_list_create()
        local pool = loot_pools[pool_id].drop_pool
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
            gm.ds_list_add(pool, class_equipment[id + 1][9])
        end
        gm.ds_list_destroy(ids)
    end
    loot_toggled = {}
end)