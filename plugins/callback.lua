-- Callback
-- Original system written by SmoothSpatula

Callback = {}

local callbacks = {}



-- ========== Enums ==========

Callback.TYPE = {}



-- ========== Functions ==========

Callback.add = function(callback, id, func, replace)
    local callback_id = Callback.TYPE[callback]
    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if replace or not callbacks[callback_id][id] then callbacks[callback_id][id] = func end
end



-- ========== Internal ==========

Callback.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        for _, c in pairs(callbacks) do
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



-- ========== Initialize ==========

Callback.__initialize = function()
    -- Populate Callback.TYPE
    local callback_names = gm.variable_global_get("callback_names")
    for i = 1, #callback_names do
        Callback.TYPE[callback_names[i]] = i - 1
    end
end