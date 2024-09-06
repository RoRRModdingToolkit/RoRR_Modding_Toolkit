-- List

List = {}



-- ========== Static Methods ==========

List.wrap = function(list)
    local abstraction = {
        value = list
    }
    setmetatable(abstraction, metatable_list)
    return abstraction
end



-- ========== Instance Methods ==========

methods_list = {

    a = function(self)
        
    end

}



-- ========== Metatables ==========

metatable_list_gs = {
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


metatable_list = {
    __index = function(table, key)
        -- Methods
        if methods_list[key] then
            return methods_list[key]
        end

        -- Pass to next metatable
        return metatable_list_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_list_gs.__newindex(table, key, value)
    end
}