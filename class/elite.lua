-- Elite

Elite = class_refs["Elite"]

local callbacks = {}



-- ========== Static Methods ==========

Elite.new = function(namespace, identifier)
    -- Check if elite already exist
    local elite = Elite.find(namespace, identifier)
    if elite then return elite end

    -- Create elite
    elite = Elite.wrap(
        gm.elite_type_create(
            namespace,      -- Namespace
            identifier      -- Identifier
        )
    )

    class_find_repopulate("Elite")
    return elite
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


    -- Callbacks
    onApply     = function(self, func) self:add_callback("onApply", func) end
    
}



-- ========== Metatables ==========

metatable_class["Elite"] = {
    __index = function(table, key)
        -- Methods
        if methods_elite[key] then
            return methods_elite[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Elite"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Elite"].__newindex(table, key, value)
    end,


    __metatable = "elite"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value), args[3].value) --(actor, data)
        end
    end
end)



return Elite