-- Callback

Callback = {}

local callbacks = {}
local pre_callbacks = {}



-- ========== Enums ==========

Callback.TYPE = {}



-- ========== Functions ==========

Callback.add = function(callback, id, func, replace)
    local callback_id = Callback.TYPE[callback]
    if not callback_id then
        log.error("Invalid callback name", 2)
        return
    end
    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if replace or not callbacks[callback_id][id] then callbacks[callback_id][id] = func end
end


Callback.add_pre = function(callback, id, func, replace)
    local callback_id = Callback.TYPE[callback]
    if not callback_id then
        log.error("Invalid callback name", 2)
        return
    end
    if not pre_callbacks[callback_id] then pre_callbacks[callback_id] = {} end
    if replace or not pre_callbacks[callback_id][id] then pre_callbacks[callback_id][id] = func end
end


Callback.remove = function(id)
    for _, c in ipairs(Callback.TYPE) do
        local c_table = callbacks[c]        -- callbacks["onAttackCreate"]
        if c_table and c_table[id] then
            c_table[id] = nil
        end

        local c_table = pre_callbacks[c]    -- pre_callbacks["onAttackCreate"]
        if c_table and c_table[id] then
            c_table[id] = nil
        end
    end
end



-- ========== Internal ==========

Callback.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        for _, c in pairs(callbacks) do
            count = count + 1
        end
    end
    for k, v in pairs(pre_callbacks) do
        for _, c in pairs(pre_callbacks) do
            count = count + 1
        end
    end
    return count
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)


gm.pre_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if pre_callbacks[args[1].value] then
        for _, fn in pairs(pre_callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)



-- ========== Initialize ==========

Callback.__initialize = function()
    -- Populate Callback.TYPE
    local callback_names = gm.variable_global_get("callback_names")
    local size = gm.array_length(callback_names)
    for i = 0, size - 1 do
        Callback.TYPE[gm.array_get(callback_names, i)] = i
    end
end