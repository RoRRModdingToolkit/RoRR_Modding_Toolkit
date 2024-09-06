-- Array

Array = {}



-- ========== Static Methods ==========

Array.new = function(size, value)
    return Array.wrap(gm.array_create(size, value or 0))
end


Array.wrap = function(array)
    local abstraction = {
        RMT_wrapper = true,
        value = array
    }
    setmetatable(abstraction, metatable_array)
    return abstraction
end



-- ========== Instance Methods ==========

methods_array = {

    size = function(self)
        return gm.array_length(self.value)
    end,


    push = function(self, ...)
        local values = {...}
        gm.array_push(self.value, table.unpack(values))
    end,


    pop = function(self)
        return gm.array_pop(self.value)
    end,


    insert = function(self, index, value)
        gm.array_insert(self.value, index, value)
    end,
    

    delete = function(self, index, number)
        gm.array_delete(self.value, index, number or 1)
    end,


    contains = function(self, value, offset, length)
        return gm.array_contains(self.value, value, offset, length)
    end,


    sort = function(self, descending)
        gm.array_sort(self.value, not descending)
    end

}



-- ========== Metatables ==========

metatable_array_gs = {
    -- Getter
    __index = function(table, key)
        key = tonumber(key)
        if key then
            return Wrap.wrap(gm.array_get(table.value, key))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        key = tonumber(key)
        if key then
            gm.array_set(table.value, key, Wrap.unwrap(value))
        end
    end
}


metatable_array = {
    __index = function(table, key)
        -- Methods
        if methods_array[key] then
            return methods_array[key]
        end

        -- Pass to next metatable
        return metatable_array_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_array_gs.__newindex(table, key, value)
    end
}