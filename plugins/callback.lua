-- Callback

Callback = {}

local callbacks = {}



-- ========== Enums ==========

Callback.TYPE = {}

-- Populate Callback.TYPE
local callback_names = gm.variable_global_get("callback_names")
for i = 1, #callback_names do
    Callback.TYPE[callback_names[i]] = i - 1
end



-- ========== Functions ==========

Callback.add = function(callback, id, func, replace)
    local callback_id = Callback.TYPE[callback]
    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if replace or not callbacks[callback_id][id] then callbacks[callback_id][id] = func end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)