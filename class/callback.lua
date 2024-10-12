-- Callback

Callback = Proxy.new()

local callbacks = {}



-- ========== Enums ==========

Callback.TYPE = Proxy.new()



-- ========== Functions ==========

Callback.add = function(callback, id, func)
    local callback_id = Callback.TYPE[callback]
    if not callback_id then log.error("Invalid callback name", 2) end

    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if not callbacks[callback_id][id] then
        callbacks[callback_id][id] = func
    else log.error("Callback ID already exists", 2)
    end
end


Callback.remove = function(id)
    if id:sub(1, 3) == "RMT" then log.error("Cannot remove RMT callbacks", 2) end
    
    for _, c in ipairs(Callback.TYPE) do
        local c_table = callbacks[c]
        if c_table and c_table[id] then
            c_table[id] = nil
        end
    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)



-- ========== Initialize ==========

initialize_callback = function()
    -- Populate Callback.TYPE
    local callback_names = gm.variable_global_get("callback_names")
    local size = gm.array_length(callback_names)
    for i = 0, size - 1 do
        Callback.TYPE[gm.array_get(callback_names, i)] = i
    end

    Callback.TYPE:lock()
end



return Callback