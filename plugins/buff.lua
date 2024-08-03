-- Buff

Buff = {}

local callbacks = {}



-- ========== General Functions ==========

Buff.PROPERTY = {
    show_icon               = 2,    -- Whether or not to show the buff icon. <br>`true` by default.
    icon_sprite             = 3,    -- The GameMaker sprite_index. <br>add descriotinp
    icon_subimage           = 4,    -- The image_index of the sprite to show. <br>`0` by default.
    icon_frame_speed        = 5,    -- The speed at which to animate the icon. <br>`0` by default.
    icon_stack_subimage     = 6,    -- Whether or not to increase the image_index per stack. <br>`true` by default.
    draw_stack_number       = 7,    -- Whether or not to display the stack number on the icon.
    stack_number_col        = 8,    -- description here (array) <br>`nil` by default
    max_stack               = 9,    -- The maximum stack count. <br>`1` by default.
    is_timed                = 13,   -- If `false`, the buff will persist until manually removed. <br>`true` by default.
    is_debuff               = 14,   -- If `true`, the buff is considered a debuff. <br>`false` by default.
    client_handles_removal  = 15    -- If `true`, the client handles removal instead of the server. <br>`false` by default.
}



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
    gm.array_set(actor.buff_stack, buff, math.min(Buff.get_stack_count(actor, buff), max_stack))
end


Buff.remove = function(actor, buff)
    gm.remove_buff(actor, buff)
end


Buff.get_stack_count = function(actor, buff)
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


Buff.set_property = function(buff, property, value)
    local array = gm.variable_global_get("class_buff")[buff + 1]
    gm.array_set(array, property, value)
end


Buff.get_property = function(buff, property, value)
    local array = gm.variable_global_get("class_buff")[buff + 1]
    return gm.array_get(array, property)
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
            local stack = Buff.get_stack_count(args[2].value, fn[1])
            fn[2](args[2].value, stack)   -- Actor, Buff stack
        end
    end
end)
