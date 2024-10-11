-- Item_Log

Item_Log = {}

local abstraction_data = setmetatable({}, {__mode = "k"})


-- ========== Enums ==========

Item_Log.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_description           = 3,
    token_story                 = 4,
    token_date                  = 5,
    token_destination           = 6,
    token_priority              = 7,
    pickup_object_id            = 8,
    sprite_id                   = 9,
    group                       = 10,
    achievement_id              = 11
}

Item_Log.GROUP = {
    common          = 1,
    uncommon        = 3,
    rare            = 5,
    equipment       = 7,
    boss            = 8
}

-- ========== Static Methods ==========

Item_Log.find = function(namespace, identifier)
    local id_string = namespace.."-"..identifier
    
    for i, item_log in ipairs(Class.ITEM_LOG) do
        local _namespace = item_log:get(0)
        local _identifier = item_log:get(1)
        if namespace == _namespace.."-".._identifier then
            return Item_Log.wrap(i - 1)
        end
    end
    
    return nil
end

Item_Log.wrap = function(item_log_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Item_Log",
        value = item_log_id
    }
    setmetatable(abstraction, metatable_item_log)
    
    return abstraction
end

-- 
Item_Log.new = function(item)
    
    if type(item) ~= "table" or (item.RMT_object ~= "Item" and not item.value) then log.error("Item is not a RMT item, got a "..type(item), 2) return end
    
    -- Check if item_log already exist
    local item_log = Item_Log.find(item.namespace, item.identifier)
    if item_log then return item_log end

    -- Decide in which group to put the item log
    -- NOTE: Each tier of items have 2 groups except boss tier item
    local group = 2 * item.tier + 1
    if item.tier == Item.TIER.boss then group = group - 1 end

    -- Create item_log
    item_log = gm.item_log_create(item.namespace, item.identifier, group, item.sprite_id, item.object_id)

    -- Make item_log abstraction
    local abstraction = Item_Log.wrap(item_log)

    -- Set the log id of the item
    item.item_log_id = abstraction.value

    return abstraction
end


-- ========== Instance Methods ==========

methods_item_log = {

    set_achievement = function(self, achivement_id)
        if type(achievement_id) ~= "number" then log.error("Achievement ID is not a number, got a "..type(achievement_id), 2) return end
    
        self.achievement_id = achievement_id
    end,
}


-- ========== Metatables ==========

metatable_item_log_gs = {
    -- Getter
    __index = function(table, key)
        local index = Item_Log.ARRAY[key]
        if index then
            local item_log_array = Class.ITEM_LOG:get(table.value)
            return Wrap.wrap(item_log_array:get(index))
        end
        log.error("Non-existent item log property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Item_Log.ARRAY[key]
        if index then
            local item_log_array = Class.ITEM_LOG:get(table.value)
            item_log_array:set(index, Wrap.unwrap(value))
        end
        log.error("Non-existent item log property", 2)
    end
}

metatable_item_log = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_item_log[key] then
            return methods_item_log[key]
        end

        -- Pass to next metatable
        return metatable_item_log_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end

        metatable_item_log_gs.__newindex(table, key, value)
    end
}