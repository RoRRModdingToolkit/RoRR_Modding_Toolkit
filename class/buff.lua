-- Buff

Buff = class_refs["Buff"]

local callbacks = {}
local other_callbacks = {
    "onStatRecalc",
    "onPostStatRecalc",
    "onDraw",
    "onChange"
}

local has_custom_buff = {}



-- ========== Static Methods ==========

Buff.new = function(namespace, identifier)
    local buff = Buff.find(namespace, identifier)
    if buff then return buff end

    -- Create buff
    local buff = Buff.wrap(
        gm.buff_create(
            namespace,
            identifier
        )
    )

    -- Set default stack_number_col to pure white
    buff.stack_number_col = Array.new(1, Color.WHITE)

    -- Add onApply callback to add actor to has_custom_buff table
    buff:onApply(function(actor, stack)
        if not Helper.table_has(has_custom_buff, actor.value) then
            table.insert(has_custom_buff, actor.value)
        end
    end)

    return buff
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
        self:onApply(function(actor, stack)
            if not Helper.table_has(has_custom_buff, actor.value) then
                table.insert(has_custom_buff, actor.value)
            end
        end)
    end,


    -- Callbacks
    onApply             = function(self, func) self:add_callback("onApply", func) end,
    onRemove            = function(self, func) self:add_callback("onRemove", func) end,
    onStatRecalc        = function(self, func) self:add_callback("onStatRecalc", func) end,
    onPostStatRecalc    = function(self, func) self:add_callback("onPostStatRecalc", func) end,
    onStep              = function(self, func) self:add_callback("onStep", func) end,
    onDraw              = function(self, func) self:add_callback("onDraw", func) end,
    onChange            = function(self, func) self:add_callback("onChange", func) end

}



-- ========== Metatables ==========

metatable_class["Buff"] = {
    __index = function(table, key)
        -- Methods
        if methods_buff[key] then
            return methods_buff[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Buff"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Buff"].__newindex(table, key, value)
    end,


    __metatable = "buff"
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

initialize_buff = function()
    Callback.add("postHUDDraw", "RMT-buff_onDraw", buff_onDraw)
end



return Buff