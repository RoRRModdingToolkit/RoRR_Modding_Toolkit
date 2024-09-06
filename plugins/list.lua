-- List

List = {}



-- ========== Static Methods ==========

List.new = function()
    return List.wrap(gm.ds_list_create())
end


List.wrap = function(list)
    local abstraction = {
        RMT_wrapper = true,
        value = list
    }
    setmetatable(abstraction, metatable_list)
    return abstraction
end



-- ========== Instance Methods ==========

methods_list = {

    exists = function(self)
        return gm.ds_exists(self.value, 2) == 1.0
    end,


    destroy = function(self)
        gm.ds_list_destroy(self.value)
        self.value = -1
    end,


    get = function(self, index)
        return Wrap.wrap(gm.ds_list_find_value(table.value, index))
    end,


    set = function(self, index, value)
        gm.ds_list_set(table.value, index, Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.ds_list_size(self.value)
    end,


    add = function(self, ...)
        local values = {...}
        gm.ds_list_add(self.value, table.unpack(values))
    end,


    insert = function(self, index, value)
        gm.ds_list_insert(self.value, index, value)
    end,
    

    delete = function(self, index)
        gm.ds_list_delete(self.value, index)
    end,


    contains = function(self, value)
        return gm.ds_list_find_index(self.value, value) >= 0
    end,


    find = function(self)
        local pos = gm.ds_list_find_index(self.value, value)
        if pos < 0 then return nil end
        return pos
    end,


    sort = function(self, descending)
        gm.ds_list_sort(self.value, not descending)
    end

}



-- ========== Metatables ==========

metatable_list_gs = {
    -- Getter
    __index = function(table, key)
        key = tonumber(key)
        if key then
            return Wrap.wrap(gm.ds_list_find_value(table.value, key - 1))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        key = tonumber(key)
        if key then
            gm.ds_list_set(table.value, key - 1, Wrap.unwrap(value))
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