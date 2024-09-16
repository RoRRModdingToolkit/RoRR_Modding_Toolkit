-- Array

Array = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

Array.new = function(size, value)
    return Array.wrap(gm.array_create(size or 0, value or 0))
end


Array.wrap = function(array)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Array",
        value = array
    }
    setmetatable(abstraction, metatable_array)
    return abstraction
end



-- ========== Instance Methods ==========

methods_array = {

    get = function(self, index)
        if index < 0 or index >= self:size() then return nil end
        return Wrap.wrap(gm.array_get(self.value, index))
    end,


    set = function(self, index, value)
        gm.array_set(self.value, index, Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.array_length(self.value)
    end,


    resize = function(self, size)
        gm.array_resize(self.value, size)
    end,


    push = function(self, ...)
        local values = {...}
        for _, v in ipairs(values) do
            gm.array_push(self.value, Wrap.unwrap(v))
        end
    end,


    pop = function(self)
        return gm.array_pop(self.value)
    end,


    insert = function(self, index, value)
        gm.array_insert(self.value, index, Wrap.unwrap(value))
    end,
    

    delete = function(self, index, number)
        gm.array_delete(self.value, index, number or 1)
    end,


    clear = function(self)
        gm.array_delete(self.value, 0, self:size())
    end,


    contains = function(self, value, offset, length)
        return gm.array_contains(self.value, Wrap.unwrap(value), offset, length)
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
        if key and key >= 1 and key <= table:size() then
            return Wrap.wrap(gm.array_get(table.value, key - 1))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        key = tonumber(key)
        if key then
            gm.array_set(table.value, key - 1, Wrap.unwrap(value))
        end
    end
}


metatable_array = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_array[key] then
            return methods_array[key]
        end

        -- Pass to next metatable
        return metatable_array_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end

        metatable_array_gs.__newindex(table, key, value)
    end,
    
    
    __len = function(table)
        return gm.array_length(table.value)
    end
}