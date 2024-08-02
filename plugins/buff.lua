-- Buff

Buff = {}

local callbacks = {}



-- ========== General Functions ==========

Buff.find = function(namespace, identifier)
    local class_buff = gm.variable_global_get("class_buff")

    if identifier then namespace = namespace.."-"..identifier end

    for i, b in ipairs(class_buff) do
        if namespace == b[1].."-"..b[2] then return i - 1 end
    end

    return nil
end


Buff.apply = function(actor, buff, time, stack)
    if gm.array_length(actor.buff_stack) <= buff then gm.array_resize(actor.buff_stack, buff + 1) end
    gm.apply_buff(actor, buff, time, stack or 1)

    -- Clamp to max stack or under
    -- Funny stuff happens if this is exceeded
    local max_stack = gm.variable_global_get("class_buff")[buff + 1][10]
    gm.array_set(actor.buff_stack, buff, math.min(Buff.get_stack(actor, buff), max_stack))
end


Buff.get_stack = function(actor, buff)
    return actor.buff_stack[buff + 1]
end



-- ========== Custom Buff Functions ==========

Buff.create = function(namespace, identifier)
    if Buff.find(namespace, identifier) then return nil end

    -- Create buff
    local buff = gm.buff_create(
        namespace,
        identifier
    )

    return buff
end


Buff.set_max_stack = function(buff, max)
    local array = gm.variable_global_get("class_buff")[buff + 1]
    gm.array_set(array, 9, math.max(max, 1))
end


Buff.add_callback = function(buff, callback, func)
    local array = gm.variable_global_get("class_buff")[buff + 1]

    if callback == "onApply" then
        if not callbacks[array[11]] then callbacks[array[11]] = {} end
        table.insert(callbacks[array[11]], {buff, func})

    elseif callback == "onRemove" then
        if not callbacks[array[12]] then callbacks[array[12]] = {} end
        table.insert(callbacks[array[12]], {buff, func})

    elseif callback == "onStep" then
        if not callbacks[array[13]] then callbacks[array[13]] = {} end
        table.insert(callbacks[array[13]], {buff, func})

    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            local stack = Buff.get_stack(args[2].value, fn[1])
            fn[2](args[2].value, stack)   -- Actor, Buff stack
        end
    end
end)
