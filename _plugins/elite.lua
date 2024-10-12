-- Elite

Elite = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}


-- ========== Enums ==========

Elite.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    palette                     = 3,
    blend_col                   = 4,
    healthbar_icon              = 5,
    effect_display              = 6,
    on_apply                    = 7
}


-- ========== Static Methods ==========

Elite.find = function(namespace, identifier)
    -- The built-in gm.elite_type_find does not accept a namespace for some reason
    
    if identifier then namespace = namespace.."-"..identifier end
    if not string.find(namespace, "-") then namespace = "ror-"..namespace end
    
    for i, elite in ipairs(Class.ELITE) do
        local _namespace = elite:get(0)
        local _identifier = elite:get(1)
        if namespace == _namespace.."-".._identifier then
            return Elite.wrap(i - 1)
        end
    end

    return nil
end

Elite.wrap = function(elite_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Elite",
        value = elite_id
    }
    setmetatable(abstraction, metatable_elite)

    return abstraction
end

Elite.new = function(namespace, identifier)
    -- Check if elite already exist
    local elite = Elite.find(namespace, identifier)
    if elite then return elite end

    -- Create elite
    elite = gm.elite_type_create(
        namespace,      -- Namespace
        identifier      -- Identifier
    )

    -- Make elite abstraction
    local abstraction = Elite.wrap(elite)

    return abstraction

end

Elite.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_elite = {

    add_callback = function(self, callback, func)

        if callback == "onApply" then 
            local callback_id = self.on_enter
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        else log.error("Invalid callback name", 2) end

    end,

    clear_callbacks = function(self)
        callbacks[self.on_apply] = nil
    end,


}

methods_elite_callbacks = {
    onApply     = function(self, func) self:add_callback("onApply", func) end,
}

-- ========== Metatables ==========

metatable_elite_gs = {
    -- Getter
    __index = function(table, key)
        local index = Elite.ARRAY[key]
        if index then
            local elite_array = Class.ELITE:get(table.value)
            return elite_array:get(index)
        end
        log.warning("Non-existent elite type property")
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Elite.ARRAY[key]
        if index then
            local elite_array = Class.ELITE:get(table.value)
            elite_array:set(index, value)
        end
        log.warning("Non-existent elite type property")
    end
}

metatable_elite_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_elite_callbacks[key] then
            return methods_elite_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_elite_gs.__index(table, key)
    end
}


metatable_elite = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_elite[key] then
            return methods_elite[key]
        end

        -- Pass to next metatable
        return metatable_elite_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.warning("Cannot modify RMT object values")
            return
        end
        
        metatable_elite_gs.__newindex(table, key, value)
    end
}

-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value), args[3].value) --(actor, data)
        end
    end
end)