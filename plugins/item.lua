-- Item

Item = {}



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

Item.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local item = gm.item_find(namespace)

    if item then
        local abstraction = {
            value = item
        }
        setmetatable(abstraction, metatable_item)
        return abstraction
    end

    return nil
end


Item.new = function(namespace, identifier, no_log)
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

    -- Make item abstraction
    local abstraction = {
        value = item
    }
    setmetatable(abstraction, metatable_item)

    -- Create item log
    if not no_log then
        local log = gm.item_log_create(
            namespace,
            identifier,
            nil,
            nil,
            abstraction.sprite_id
        )

        abstraction.item_log_id = log
    end

    -- Add onPickup callback to add actor to has_custom_item table
    -- Item.add_callback(item, "onPickup", function(actor, stack)
    --     if not Helper.table_has(has_custom_item, actor) then
    --         table.insert(has_custom_item, actor)
    --     end
    -- end)

    return abstraction
end



-- ========== Instance Methods ==========

methods_item = {

    add_callback = function(self, callback, fn)

    end,


    set_sprite = function(self, sprite)
        -- Set class_item sprite
        self.sprite_id = sprite

        -- Set item object sprite
        gm.object_set_sprite_w(self.object_id, sprite)

        -- Set item log sprite
        if self.item_log_id then
            local log_array = gm.array_get(Class.ITEM_LOG, self.item_log_id)
            gm.array_set(log_array, 9, sprite)
        end
    end,


    set_tier = function(self, tier)
        self.tier = tier


        local pools = gm.variable_global_get("treasure_loot_pools")

        -- Remove from all loot pools that the item is in
        local size = gm.array_length(pools)
        for i = 0, size - 1 do
            local drops = gm.array_get(pools, i).drop_pool
            local pos = gm.ds_list_find_index(drops, self.object_id)
            if pos >= 0 then gm.ds_list_delete(drops, pos) end
        end

        -- Add to new loot pool
        local pool = gm.array_get(pools, tier).drop_pool
        gm.ds_list_add(pool, self.object_id)
        

        -- Remove previous item log position (if found)
        local item_log_order = gm.variable_global_get("item_log_display_list")
        local pos = gm.ds_list_find_index(item_log_order, self.item_log_id)
        if pos >= 0 then gm.ds_list_delete(item_log_order, pos) end

        -- Set new item log position
        local pos = 0
        local size = gm.ds_list_size(item_log_order)
        for i = 0, size - 1 do
            local log_id = gm.ds_list_find_value(item_log_order, i)
            local log_ = gm.array_get(Class.ITEM_LOG, log_id)
            local item_id = Item.find(gm.array_get(log_, 0), gm.array_get(log_, 1))
            
            local tier_ = Item.TIER.equipment
            if item_id then
                local iter_item = gm.array_get(Class.ITEM, item_id.value)
                tier_ = gm.array_get(iter_item, 6)
            end
            if tier_ > tier then
                pos = i
                break
            end
        end
        gm.ds_list_insert(item_log_order, pos, self.item_log_id)
    end,


    set_loot_tags = function(self, ...)
        local tags = 0
        for _, t in ipairs{...} do tags = tags + t end

        self.loot_tags = tags
    end,


    add_achievement = function(self, progress_req, single_run)

    end,


    progress_achievement = function(self, amount)

    end

}



-- ========== Metatables ==========

metatable_item_gs = {
    -- Getter
    __index = function(table, key)
        local index = Item.ARRAY[key]
        if index then
            local item_array = gm.array_get(Class.ITEM, table.value)
            return gm.array_get(item_array, index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Item.ARRAY[key]
        if index then
            local item_array = gm.array_get(Class.ITEM, table.value)
            gm.array_set(item_array, index, value)
        end
    end
}


metatable_item = {
    __index = function(table, key)
        -- Methods
        if methods_item[key] then
            return methods_item[key]
        end

        -- Pass to next metatable
        return metatable_item_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_item_gs.__newindex(table, key, value)
    end
}