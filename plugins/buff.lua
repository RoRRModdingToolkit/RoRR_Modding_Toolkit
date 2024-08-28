-- Buff

Buff = {}

local callbacks = {}
local has_custom_buff = {}
--local buff_table = {}



-- ========== Enums ==========

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

    local size = gm.array_length(class_buff)
    for i = 0, size - 1 do
        local buff = gm.array_get(class_buff, i)
        if namespace == buff[1].."-"..buff[2] then return i - 1 end
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


Buff.remove = function(actor, buff, stack)
    if gm.array_length(actor.buff_stack) <= buff then gm.array_resize(actor.buff_stack, buff + 1) end
    local stack_count = Buff.get_stack_count(actor, buff)
    if (not stack) or stack >= stack_count then gm.remove_buff(actor, buff)
    else gm.array_set(actor.buff_stack, buff, stack_count - stack)
    end
end


Buff.get_stack_count = function(actor, buff)
    if gm.array_length(actor.buff_stack) <= buff then gm.array_resize(actor.buff_stack, buff + 1) end
    local count = actor.buff_stack[buff + 1]
    if count == nil then return 0 end
    return count
end



-- ========== Custom Buff Functions ==========

Buff.create = function(namespace, identifier)
    if Buff.find(namespace, identifier) then return nil end

    -- Create buff
    local buff = gm.buff_create(
        namespace,
        identifier
    )

    -- Insert buff namespace-identifier into buff_table
    --table.insert(buff_table, namespace.."-"..identifier)

    -- Set default stack_number_col to pure white
    Buff.set_property(buff, Buff.PROPERTY.stack_number_col, gm.array_create(1, 16777215))

    -- Add onApply callback to add actor to has_custom_buff table
    Buff.add_callback(buff, "onApply", function(actor, stack)
        if not Helper.table_has(has_custom_buff, actor) then
            table.insert(has_custom_buff, actor)
        end
    end)

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

    elseif callback == "onDraw"
        or callback == "onChange"
        then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {buff, func})

    end
end



-- ========== Internal ==========

function buff_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onDraw"] then
        for n, a in ipairs(has_custom_buff) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onDraw"]) do
                    local count = Buff.get_stack_count(a, c[1])
                    if count > 0 then
                        c[2](a, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_buff, n)
            end
        end
    end
end


Buff.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
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


gm.pre_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    -- Extend buff_stack if necessary
    if gm.array_length(args[1].value.buff_stack) <= args[2].value then gm.array_resize(args[1].value.buff_stack, args[2].value + 1) end
end)


gm.pre_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    if callbacks["onChange"] then
        for _, fn in pairs(callbacks["onChange"]) do
            local stack = Buff.get_stack_count(args[1].value, fn[1])
            if stack > 0 then
                fn[2](args[1].value, args[2].value, stack)   -- Actor, To, Buff stack
            end
        end
    end
end)



-- ========== Initialize ==========

Buff.__initialize = function()
    Callback.add("postHUDDraw", "RMT.buff_onDraw", buff_onDraw, true)

    -- Populate buff_table
    -- local class_buff = gm.variable_global_get("class_buff")
    -- for i, b in ipairs(class_buff) do table.insert(buff_table, b[1].."-"..b[2]) end
end