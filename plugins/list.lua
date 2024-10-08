-- List

List = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

List.new = function()
    return List.wrap(gm.ds_list_create())
end


List.wrap = function(list)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "List",
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
        abstraction_data[self].value = -1
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



-- ========== Metatables ==========

metatable_list_gs = {
    -- Getter
    __index = function(table, key)
        key = tonumber(Wrap.unwrap(key))
        if key and key >= 1 and key <= table:size() then
            return Wrap.wrap(gm.ds_list_find_value(table.value, key - 1))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        key = tonumber(Wrap.unwrap(key))
        if key then
            gm.ds_list_set(table.value, key - 1, Wrap.unwrap(value))
        end
    end
}


metatable_list = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_list[key] then
            return methods_list[key]
        end

        -- Pass to next metatable
        return metatable_list_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_list_gs.__newindex(table, key, value)
    end,
    
    
    __len = function(table)
        return gm.ds_list_size(table.value)
    end
}