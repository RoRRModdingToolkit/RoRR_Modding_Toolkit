-- Array

Array = Proxy.new()



-- ========== Static Methods ==========

Array.new = function(size, value)
    return Array.wrap(gm.array_create(size or 0, value or 0))
end


Array.wrap = function(value)
    if not gm.is_array(value) then
        log.error("value is not an array", 2)
    end

    local wrapper = Proxy.new()
    wrapper.RMT_object = "Array"
    wrapper.value = value
    wrapper:lock()
    return wrapper

    -- local abstraction = {}
    -- abstraction_data[abstraction] = {
    --     RMT_object = "Array",
    --     value = array
    -- }
    -- setmetatable(abstraction, metatable_array)
    -- return abstraction
end



-- ========== Instance Methods ==========

methods_array = {

}



-- ========== Metatables ==========

metatable_array_gs = {
    -- Getter
    __index = function(table, key)
        key = tonumber(Wrap.unwrap(key))
        if key and key >= 1 and key <= table:size() then
            return Wrap.wrap(gm.array_get(table.value, key - 1))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        key = tonumber(Wrap.unwrap(key))
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



-- ========== Lock proxy after setup ==========

Array:lock()