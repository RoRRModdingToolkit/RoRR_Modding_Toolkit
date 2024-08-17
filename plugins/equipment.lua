-- Equipment

Equipment = {}

local callbacks = {}



-- ========== General Functions ==========

Equipment.find = function(namespace, identifier)
    if not identifier then return gm.equipment_find(namespace) end
    return gm.equipment_find(namespace.."-"..identifier)
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