-- Equipment

Equipment = {}



-- ========== Enums ==========

Equipment.ARRAY = {
    namespace           = 0,
    identifier          = 1,
    token_name          = 2,
    token_text          = 3,
    on_use              = 4,
    cooldown            = 5,
    tier                = 6,
    sprite_id           = 7,
    object_id           = 8,
    item_log_id         = 9,
    achievement_id      = 10,
    effect_display      = 11,
    loot_tags           = 12,
    is_new_equipment    = 13
}



-- ========== Static Methods ==========

Equipment.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local equip = gm.equipment_find(namespace)

    if equip then
        return Equipment.wrap(equip)
    end

    return nil
end


Equipment.new = function(namespace, identifier)
    if Equipment.find(namespace, identifier) then return nil end

    -- Create equipment
    local equipment = gm.equipment_create(
        namespace,
        identifier,
        gm.array_length(Class.EQUIPMENT),   -- class_equipment index
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

    -- Make equipment abstraction
    local abstraction = Equipment.wrap(equipment)

    -- Have to manually increase this variable for some reason (class_equipment array length)
    gm.variable_global_set("count_equipment", gm.variable_global_get("count_equipment") + 1.0)


    -- Remove previous item log position (if found)
    local item_log_order = gm.variable_global_get("item_log_display_list")
    local pos = gm.ds_list_find_index(item_log_order, abstraction.item_log_id)
    if pos >= 0 then gm.ds_list_delete(item_log_order, pos) end

    -- Set item log position
    local pos = 0
    local size = gm.ds_list_size(item_log_order)
    for i = 0, size - 1 do
        local log_id = gm.ds_list_find_value(item_log_order, i)
        local log_ = gm.array_get(Class.ITEM_LOG, log_id)
        local iter_item = Equipment.find(gm.array_get(log_, 0), gm.array_get(log_, 1))
        
        if iter_item then
            if iter_item.tier == 3.0 then pos = i end
        end
    end
    gm.ds_list_insert(item_log_order, pos + 1, abstraction.item_log_id)


    return abstraction
end


Equipment.wrap = function(equipment_id)
    local abstraction = {
        RMT_wrapper = true,
        value = equipment_id
    }
    setmetatable(abstraction, metatable_equipment)
    return abstraction
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

        end
    end,


    set_sprite = function(self, sprite)
        -- Set class_equipment sprite
        self.sprite_id = sprite

        -- Set equipment object sprite
        gm.object_set_sprite_w(self.object_id, sprite)

        -- Set equipment log sprite
        if self.item_log_id then
            local log_array = gm.array_get(Class.ITEM_LOG, self.item_log_id)
            gm.array_set(log_array, 9, sprite)
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


    is_unlocked = function(self)
        return (not self.achievement_id) or gm.achievement_is_unlocked(self.achievement_id)
    end,


    add_achievement = function(self, progress_req, single_run)
        local ach = gm.achievement_create(self.namespace, self.identifier)
        gm.achievement_set_unlock_equipment(ach, self.value)
        gm.achievement_set_requirement(ach, progress_req or 1)
    
        if single_run then
            local ach_array = gm.array_get(Class.ACHIEVEMENT, ach)
            gm.array_set(ach_array, 21, single_run)
        end
    end,


    progress_achievement = function(self, amount)
        if self:is_unlocked() then return end
        gm.achievement_add_progress(self.achievement_id, amount or 1)
    end,


    toggle_loot = function(self, enabled)
        
    end

}



-- ========== Metatables ==========

metatable_equipment_gs = {
    -- Getter
    __index = function(table, key)
        local index = Equipment.ARRAY[key]
        if index then
            local equipment_array = gm.array_get(Class.EQUIPMENT, table.value)
            return gm.array_get(equipment_array, index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Equipment.ARRAY[key]
        if index then
            local equipment_array = gm.array_get(Class.EQUIPMENT, table.value)
            gm.array_set(equipment_array, index, value)
        end
    end
}


metatable_equipment = {
    __index = function(table, key)
        -- Methods
        if methods_equipment[key] then
            return methods_equipment[key]
        end

        -- Pass to next metatable
        return metatable_equipment_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_equipment_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onUse
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value))   -- Actor
        end
    end
end)