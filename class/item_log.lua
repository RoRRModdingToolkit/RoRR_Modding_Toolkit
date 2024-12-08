-- Item_Log

Item_Log = class_refs["Item_Log"]



-- ========== Enums ==========

Item_Log.GROUP = Proxy.new({
    common          = 1,
    uncommon        = 3,
    rare            = 5,
    equipment       = 7,
    boss            = 8
}):lock()



-- ========== Static Methods ==========

Item_Log.new = function(item)
    
    if type(item) ~= "table" or item.RMT_object ~= "Item" then log.error("Item is not a RMT item, got a "..type(item), 2) return end
    
    -- Check if item_log already exist
    local item_log = Item_Log.find(item.namespace, item.identifier)
    if item_log then return item_log end

    -- Decide in which group to put the item log
    -- NOTE: Each tier of items have 2 groups except boss tier item
    local group = 2 * item.tier + 1
    if item.tier == Item.TIER.boss then group = group - 1 end

    -- Create item_log
    item_log = gm.item_log_create(
        item.namespace,         -- Namespace
        item.identifier,        -- Identifier
        group,                  -- Item Group in the Log page
        item.sprite_id,         -- Sprite of the Item
        item.object_id          -- Item Pickup Object
    )

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

metatable_class["Item_Log"] = {
    __index = function(table, key)
        -- Methods
        if methods_item_log[key] then
            return methods_item_log[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Item_Log"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Item_Log"].__newindex(table, key, value)
    end,


    __metatable = "Item_Log"
}



return Item_Log