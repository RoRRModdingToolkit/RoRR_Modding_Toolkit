-- List

List = Proxy.new()



-- ========== Static Methods ==========

List.new = function()
    return List.wrap(gm.ds_list_create())
end


List.wrap = function(value)
    local wrapper = Proxy.new()
    wrapper.RMT_object = "List"
    wrapper.value = value
    wrapper:setmetatable(metatable_list)
    wrapper:lock(
        "RMT_object",
        "value",
        table.unpack(methods_list_lock)
    )
    return wrapper
end



-- ========== Instance Methods ==========

methods_list = {

    exists = function(self)
        return gm.ds_exists(self.value, 2) == 1.0
    end,


    destroy = function(self)
        gm.ds_list_destroy(self.value)
    end,


    get = function(self, index)
        index = Wrap.unwrap(index)
        return Wrap.wrap(gm.ds_list_find_value(self.value, index))
    end,


    set = function(self, index, value)
        index = Wrap.unwrap(index)
        gm.ds_list_set(self.value, index, Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.ds_list_size(self.value)
    end,


    add = function(self, ...)
        local values = {...}
        for _, v in ipairs(values) do
            gm.ds_list_add(self.value, Wrap.unwrap(v))
        end
    end,


    insert = function(self, index, value)
        gm.ds_list_insert(self.value, index, Wrap.unwrap(value))
    end,
    

    delete = function(self, index)
        gm.ds_list_delete(self.value, index)
    end,

    
    clear = function(self)
        gm.ds_list_clear(self.value)
    end,


    contains = function(self, value)
        return gm.ds_list_find_index(self.value, Wrap.unwrap(value)) >= 0
    end,


    find = function(self, value)
        local pos = gm.ds_list_find_index(self.value, Wrap.unwrap(value))
        if pos < 0 then return nil end
        return pos
    end,


    sort = function(self, descending)
        gm.ds_list_sort(self.value, not descending)
    end

}
methods_list_lock = Helper.table_get_keys(methods_list)



-- ========== Metatables ==========

metatable_list = {
    __index = function(table, key)
        -- Methods
        if methods_list[key] then
            return methods_list[key]
        end

        -- Getter
        key = tonumber(Wrap.unwrap(key))
        if key and key >= 1 and key <= table:size() then
            return Wrap.wrap(gm.ds_list_find_value(table.value, key - 1))
        end
        return nil
    end,
    

    __newindex = function(table, key, value)
        -- Setter
        key = tonumber(Wrap.unwrap(key))
        if key then
            gm.ds_list_set(table.value, key - 1, Wrap.unwrap(value))
        end
    end,
    
    
    __len = function(table)
        return gm.ds_list_size(table.value)
    end,

    
    __metatable = "list"
}



return List