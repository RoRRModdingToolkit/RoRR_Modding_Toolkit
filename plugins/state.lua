-- State

State = {}

local callbacks = {}


-- ========== Enums ==========

State.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    on_enter                    = 2,
    on_exit                     = 3,
    on_step                     = 4,
    on_get_interrupt_priority   = 5,
    callable_serialize          = 6,
    callable_deserialize        = 7,
    is_skill_state              = 8,
    is_climb_state              = 9,
    activity_flags              = 10
}



-- ========== Static Methods ==========

State.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    local size = gm.array_length(Class.ACTOR_STATE)
    for i = 0, size - 1 do
        local state = gm.array_get(Class.ACTOR_STATE, i)
        if gm.is_array(state) then
            local _namespace = gm.array_get(state, 0)
            local _identifier = gm.array_get(state, 1)
            if namespace == _namespace.."-".._identifier then
                return State.wrap(i)
            end
        end
    end

    return nil
end


State.wrap = function(state_id)
    local abstraction = {
        RMT_wrapper = true,
        value = state_id
    }
    setmetatable(abstraction, metatable_state)
    return abstraction
end

State.new = function(namespace, identifier)
    if State.find(namespace, identifier) then return nil end

    -- Create state
    local state = gm.actor_state_create(
        namespace,      -- Namespace
        identifier      -- Identifier
    )

    -- Make state abstraction
    local abstraction = State.wrap(state)

    return abstraction

end

State.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_state = {

    add_callback = function(self, callback, func)

        if callback == "OnEnter" then 
            local callback_id = self.on_enter
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "OnExit" then 
            local callback_id = self.on_exit
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "OnStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "OnGetInterruptPriority" then
            local callback_id = self.on_get_interrupt_priority
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
    end,

}

-- ========== Metatables ==========

metatable_state_gs = {
    -- Getter
    __index = function(table, key)
        local index = State.ARRAY[key]
        if index then
            local state_array = gm.array_get(Class.ACTOR_STATE, table.value)
            return gm.array_get(state_array, index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = State.ARRAY[key]
        if index then
            local state_array = gm.array_get(Class.ACTOR_STATE, table.value)
            gm.array_set(state_array, index, value)
        end
    end
}


metatable_state = {
    __index = function(table, key)
        -- Methods
        if methods_state[key] then
            return methods_state[key]
        end

        -- Pass to next metatable
        return metatable_state_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_state_gs.__newindex(table, key, value)
    end
}

-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value) --(actor, data)
        end
    end
end)