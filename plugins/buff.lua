-- Buff

Buff = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}
local other_callbacks = {
    "onStatRecalc",
    "onPostStatRecalc",
    "onDraw",
    "onChange"
}

local has_custom_buff = {}



-- ========== Enums ==========

Buff.ARRAY = {
    namespace               = 0,
    identifier              = 1,
    show_icon               = 2,
    icon_sprite             = 3,
    icon_subimage           = 4,
    icon_frame_speed        = 5,
    icon_stack_subimage     = 6,
    draw_stack_number       = 7,
    stack_number_col        = 8,
    max_stack               = 9,
    on_apply                = 10,
    on_remove               = 11,
    on_step                 = 12,
    is_timed                = 13,
    is_debuff               = 14,
    client_handles_removal  = 15,
    effect_display          = 16
}



-- ========== Static Methods ==========

Buff.new = function(namespace, identifier)
    local buff = Buff.find(namespace, identifier)
    if buff then return buff end

    -- Create buff
    local buff = gm.buff_create(
        namespace,
        identifier
    )

    -- Make buff abstraction
    local abstraction = Buff.wrap(buff)

    -- Set default stack_number_col to pure white
    abstraction.stack_number_col = Array.new(1, Color.WHITE)

    -- Add onApply callback to add actor to has_custom_buff table
    abstraction:add_callback("onApply", function(actor, stack)
        if not Helper.table_has(has_custom_buff, actor.value) then
            table.insert(has_custom_buff, actor.value)
        end
    end)

    return abstraction
end


Buff.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end

    for i, buff in ipairs(Class.BUFF) do
        local _namespace = buff:get(0)
        local _identifier = buff:get(1)
        if namespace == _namespace.."-".._identifier then
            return Buff.wrap(i - 1)
        end
    end

    return nil
end


Buff.wrap = function(buff_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Buff",
        value = buff_id
    }
    setmetatable(abstraction, metatable_buff)
    return abstraction
end


Buff.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end



-- ========== Instance Methods ==========

methods_buff = {

    add_callback = function(self, callback, func)

        if callback == "onApply" then
            local callback_id = self.on_apply
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], {self.value, func})
    
        elseif callback == "onRemove" then
            local callback_id = self.on_remove
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], {self.value, func})

        elseif callback == "onStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], {self.value, func})

        elseif Helper.table_has(other_callbacks, callback) then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {self.value, func})

        else log.error("Invalid callback name", 2)

        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_apply] = nil
        callbacks[self.on_remove] = nil
        callbacks[self.on_step] = nil

        for _, c in ipairs(other_callbacks) do
            local c_table = callbacks[c]
            if c_table then
                for i, v in ipairs(c_table) do
                    if v[1] == self.value then
                        table.remove(c_table, i)
                    end
                end
            end
        end

        -- Add onApply callback to add actor to has_custom_buff table
        self:add_callback("onApply", function(actor, stack)
            if not Helper.table_has(has_custom_buff, actor.value) then
                table.insert(has_custom_buff, actor.value)
            end
        end)
    end,

}


methods_buff_callbacks = {

    onApply             = function(self, func) self:add_callback("onApply", func) end,
    onRemove            = function(self, func) self:add_callback("onRemove", func) end,
    onStatRecalc        = function(self, func) self:add_callback("onStatRecalc", func) end,
    onPostStatRecalc    = function(self, func) self:add_callback("onPostStatRecalc", func) end,
    onStep              = function(self, func) self:add_callback("onStep", func) end,
    onDraw              = function(self, func) self:add_callback("onDraw", func) end,
    onChange            = function(self, func) self:add_callback("onChange", func) end

}



-- ========== Metatables ==========

metatable_buff_gs = {
    -- Getter
    __index = function(table, key)
        local index = Buff.ARRAY[key]
        if index then
            local buff_array = Class.BUFF:get(table.value)
            return buff_array:get(index)
        end
        log.error("Non-existent buff property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Buff.ARRAY[key]
        if index then
            local buff_array = Class.BUFF:get(table.value)
            buff_array:set(index, value)
            return
        end
        log.error("Non-existent buff property", 2)
    end
}


metatable_buff_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_buff_callbacks[key] then
            return methods_buff_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_buff_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_buff_gs.__newindex(table, key, value)
    end
}


metatable_buff = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_buff[key] then
            return methods_buff[key]
        end

        -- Pass to next metatable
        return metatable_buff_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_buff_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onApply and onRemove
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            local actor = Instance.wrap(args[2].value)
            local stack = actor:buff_stack_count(fn[1])
            fn[2](actor, stack)     -- Actor, Buff stack
        end
    end
end)


gm.pre_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    -- Extend buff_stack if necessary
    if gm.array_length(args[1].value.buff_stack) <= args[2].value then gm.array_resize(args[1].value.buff_stack, args[2].value + 1) end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    if callbacks["onStatRecalc"] then
        for _, fn in ipairs(callbacks["onStatRecalc"]) do
            local count = actor:buff_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, count)   -- Actor, Stack count
            end
        end
    end
    actor:get_data().post_stat_recalc = true
end)


gm.pre_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    if callbacks["onChange"] then
        for _, fn in pairs(callbacks["onChange"]) do
            local actor = Instance.wrap(args[1].value)
            local count = actor:buff_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, Instance.wrap(args[2].value), count)   -- Actor, To, Buff stack
            end
        end
    end
end)



-- ========== Callbacks ==========

function buff_onPostStatRecalc(actor)
    if callbacks["onPostStatRecalc"] then
        for _, fn in ipairs(callbacks["onPostStatRecalc"]) do
            local count = actor:buff_stack_count(fn[1])
            if count > 0 then
                fn[2](actor, count)   -- Actor, Stack count
            end
        end
    end
end


local function buff_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    if callbacks["onDraw"] then
        for n, a in ipairs(has_custom_buff) do
            if Instance.exists(a) then
                for _, c in ipairs(callbacks["onDraw"]) do
                    local actor = Instance.wrap(a)
                    local count = actor:buff_stack_count(c[1])
                    if count > 0 then
                        c[2](actor, count)  -- Actor, Stack count
                    end
                end
            else table.remove(has_custom_buff, n)
            end
        end
    end
end



-- ========== Initialize ==========

Buff.__initialize = function()
    Callback.add("postHUDDraw", "RMT.buff_onDraw", buff_onDraw, true)
end