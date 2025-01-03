-- Array

Array = Proxy.new()



-- ========== Static Methods ==========

Array.new = function(size, value)
    size = Wrap.unwrap(size)

    -- Overload 1
    if type(size) == "table" then
        local arr = gm.array_create(0)
        for _, v in ipairs(size) do
            gm.array_push(arr, Wrap.unwrap(v))
        end
        return Array.wrap(arr)
    end

    -- Overload 2
    return Array.wrap(gm.array_create(size or 0, value or 0))
end


Array.wrap = function(value)
    if not gm.is_array(value) then
        log.error("value is not an array", 2)
    end

    return make_wrapper(value, metatable_array, lock_table_array)
end



-- ========== Instance Methods ==========

methods_array = {

    get = function(self, index)
        index = Wrap.unwrap(index)
        if index < 0 or index >= self:size() then return nil end
        return Wrap.wrap(gm.array_get(self.value, index))
    end,


    set = function(self, index, value)
        gm.array_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.array_length(self.value)
    end,


    resize = function(self, size)
        gm.array_resize(self.value, Wrap.unwrap(size))
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
        gm.array_insert(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,
    

    delete = function(self, index, number)
        gm.array_delete(self.value, Wrap.unwrap(index), number or 1)
    end,


    clear = function(self)
        gm.array_delete(self.value, 0, self:size())
    end,


    contains = function(self, value, offset, length)
        return gm.array_contains(self.value, Wrap.unwrap(value), offset or 0, length or (#self - 1))
    end,


    find = function(self, value)
        value = Wrap.unwrap(value)
        for i, v in ipairs(self) do
            if v == value then return i - 1 end
        end
        return nil
    end,


    sort = function(self, descending)
        gm.array_sort(self.value, not descending)
    end
    
}
lock_table_array = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_array))})



-- ========== Metatables ==========

metatable_array = {
    __index = function(table, key)
        -- Methods
        if methods_array[key] then
            return methods_array[key]
        end

        -- Getter
        key = tonumber(Wrap.unwrap(key))
        if key and key >= 1 and key <= table:size() then
            return Wrap.wrap(gm.array_get(table.value, key - 1))
        end
        return nil
    end,
    

    __newindex = function(table, key, value)
        -- Setter
        key = tonumber(Wrap.unwrap(key))
        if key then
            gm.array_set(table.value, key - 1, Wrap.unwrap(value))
        end
    end,
    
    
    __len = function(table)
        return gm.array_length(table.value)
    end,


    __metatable = "Array"
}



return Array