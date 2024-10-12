-- Ending

Ending = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Enums ==========

Ending.ARRAY = {
    namespace                       = 0,
    identifier                      = 1,
    primary_color                   = 2,
    is_victory                      = 3
}



-- ========== Static Methods ==========

Ending.new = function(namespace, identifier)
    local ending = Ending.find(namespace, identifier)
    if ending then return ending end

    return Ending.wrap(gm.ending_create(namespace, identifier))
end


Ending.find = function(namespace, identifier)
    local id_string = namespace
    
    if identifier then id_string = namespace.."-"..identifier end
    
    local ending_id = gm.ending_find(id_string)

    if not ending_id then return nil end

    return Ending.wrap(ending_id)
end


Ending.wrap = function(ending_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Ending",
        value = ending_id
    }
    setmetatable(abstraction, metatable_ending)
    return abstraction
end


-- ========== Instance Methods ==========

methods_ending = {
    set_primary_color = function(self, R, G, B)
        self.primary_color = Color.from_rgb(R, G, B)
    end,

    is_victory = function(self, is_victory)
        if type(is_victory) ~= "boolean" then log.error("Victory is not a boolean, got a "..type(is_victory), 2) return end
        
        self.is_victory = is_victory
    end,
}

-- ========== Metatables ==========

metatable_ending_gs = {
    -- Getter
    __index = function(table, key)
        local index = Ending.ARRAY[key]
        if index then
            local array = Class.ENDING:get(table.value)
            return array:get(index)
        end
        log.warning("Non-existent ending property")
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Ending.ARRAY[key]
        if index then
            local array = Class.ENDING:get(table.value)
            array:set(index, value)
            return
        end
        log.warning("Non-existent ending property")
    end
}


metatable_ending = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_ending[key] then
            return methods_ending[key]
        end

        -- Pass to next metatable
        return metatable_ending_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.warning("Cannot modify RMT object values")
            return
        end
        
        metatable_ending_gs.__newindex(table, key, value)
    end
}