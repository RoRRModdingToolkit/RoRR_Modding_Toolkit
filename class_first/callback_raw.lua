-- Callback_Raw

Callback_Raw = Proxy.new()

local callbacks = {}



-- ========== Functions ==========

Callback_Raw.add = function(callback, id, func)
    local callback_id = Callback.TYPE[callback]
    if not callback_id then log.error("Invalid callback name", 2) end

    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if callbacks[callback_id][id] and id:sub(1, 3) == "RMT" then log.error("Cannot overwrite RMT callbacks", 2) end
    callbacks[callback_id][id] = func
end


Callback_Raw.remove = function(id)
    if id:sub(1, 3) == "RMT" then log.error("Cannot remove RMT callbacks", 2) end
    
    for _, c_id in pairs(Callback.TYPE) do
        local c_table = callbacks[c_id]
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



return Callback_Raw