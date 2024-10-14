-- State

State = class_refs["State"]

local callbacks = {}


-- ========== Enums ==========


State.ACTIVITY_FLAG = Proxy.new({
    none                = 0,
    allow_rope_cancel   = 1,
    allow_aim_turn      = 2
}):lock()

State.ACTOR_STATE_INTERRUPT_PRIORITY = Proxy.new({
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
}):lock()



-- ========== Static Methods ==========

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



-- ========== Instance Methods ==========

methods_state = {

    add_callback = function(self, callback, func)

        local callback_id = nil
        if      callback == "onEnter" then callback_id = self.on_enter
        elseif  callback == "onExit" then callback_id = self.on_exit
        elseif  callback == "onStep" then callback_id = self.on_step
        elseif  callback == "onGetInterruptPriority" then callback_id = self.on_get_interrupt_priority
        end

        if callback_id then
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        else log.error("Invalid callback name", 2) end
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


    -- Callbacks
    onEnter                     = function(self, func) self:add_callback("onEnter", func) end,
    onExit                      = function(self, func) self:add_callback("onExit", func) end,
    onStep                      = function(self, func) self:add_callback("onStep", func) end,
    on_get_interrupt_priority   = function(self, func) self:add_callback("onGetInterruptPriority", func) end
}



-- ========== Metatables ==========

metatable_class["State"] = {

    __index = function(table, key)
        -- Methods
        if methods_state[key] then
            return methods_state[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["State"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["State"].__newindex(table, key, value)
    end,


    __metatable = "state"
}

-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value), args[3].value) --(actor, data)
        end
    end
end)