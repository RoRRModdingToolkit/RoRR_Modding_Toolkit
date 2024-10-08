-- State

State = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}


-- ========== Enums ==========

State.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    on_enter                    = 2,
    on_exit                     = 3,
    on_step                     = 4,
    on_get_interrupt_priority   = 5,
    callable_serialize          = 6,    --WIP
    callable_deserialize        = 7,    --WIP
    is_skill_state              = 8,
    is_climb_state              = 9,
    activity_flags              = 10
}

State.ACTIVITY_FLAG = {
    none                = 0,
    allow_rope_cancel   = 1,
    allow_aim_turn      = 2
}

State.ACTOR_STATE_INTERRUPT_PRIORITY = {
    any                     = 0,
    skill_interrupt_period  = 1,
    skill                   = 2,
    priority_skill          = 3,
    legacy_activity_state   = 4,
    climb                   = 5,
    pain                    = 6,
    frozen                  = 7,
    charge                  = 8,
    vehicle                 = 9,
    burrowed                = 10,
    spawn                   = 11,
    teleport                = 12
}


-- ========== Static Methods ==========

State.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end

    -- ipairs doesn't work on this class
    -- because there are random "nil"s scattered around
    -- where indexes were skipped
    for i = 0, #Class.ACTOR_STATE - 1 do
        local state = Class.ACTOR_STATE:get(i)
        if state then
            local _namespace = state:get(0)
            local _identifier = state:get(1)
            if namespace == _namespace.."-".._identifier then
                return State.wrap(i)
            end
        end
    end

    return nil
end


State.wrap = function(state_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "State",
        value = state_id
    }
    setmetatable(abstraction, metatable_state)

    return abstraction
end

State.new = function(namespace, identifier)
    -- Check if state already exist
    local state = State.find(namespace, identifier)
    if state then return state end

    -- Create state
    state = gm.actor_state_create(
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

        if callback == "onEnter" then 
            local callback_id = self.on_enter
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onExit" then 
            local callback_id = self.on_exit
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onGetInterruptPriority" then
            local callback_id = self.on_get_interrupt_priority
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
    end,

    clear_callbacks = function(self)
        callbacks[self.on_enter] = nil
        callbacks[self.on_exit] = nil
        callbacks[self.on_step] = nil
        callbacks[self.on_get_interrupt_priority] = nil
    end,

    -- WIP (typecheck)
    set_callables = function(self, serialize, deserialize)
        self.callable_serialize = serialize
        self.callable_deserialize = deserialize
    end,

    -- set_activity_flag = function(self, activity_flag)

    -- end,
}

methods_state_callbacks = {
    onEnter                     = function(self, func) self:add_callback("onEnter", func) end,
    onExit                      = function(self, func) self:add_callback("onExit", func) end,
    onStep                      = function(self, func) self:add_callback("onStep", func) end,
    on_get_interrupt_priority   = function(self, func) self:add_callback("onGetInterruptPriority", func) end
}

-- ========== Metatables ==========

metatable_state_gs = {
    -- Getter
    __index = function(table, key)
        local index = State.ARRAY[key]
        if index then
            local state_array = Class.ACTOR_STATE:get(table.value)
            return state_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = State.ARRAY[key]
        if index then
            local state_array = Class.ACTOR_STATE:get(table.value)
            state_array:set(index, value)
        end
    end
}

metatable_state_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_state_callbacks[key] then
            return methods_state_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_state_gs.__index(table, key)
    end
}


metatable_state = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_state[key] then
            return methods_state[key]
        end

        -- Pass to next metatable
        return metatable_state_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_state_gs.__newindex(table, key, value)
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