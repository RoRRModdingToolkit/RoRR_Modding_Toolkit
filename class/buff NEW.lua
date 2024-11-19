-- Buff

return

Buff = class_refs["Buff"]

local callbacks = {}
local valid_callbacks = {
    onApply                 = true,
    onRemove                = true,
    onStatRecalc            = true,
    onPostStatRecalc        = true,
    onAttackCreate          = true,
    onAttackCreateProc      = true,
    onAttackHit             = true,
    onAttackHandleEnd       = true,
    onAttackHandleEndProc   = true,
    onHitProc               = true,
    onKillProc              = true,
    onDamagedProc           = true,
    onDamageBlocked         = true,
    onHeal                  = true,
    onShieldBreak           = true,
    onInteractableActivate  = true,
    onPickupCollected       = true,
    onPrimaryUse            = true,
    onSecondaryUse          = true,
    onUtilityUse            = true,
    onSpecialUse            = true,
    onEquipmentUse          = true,
    onStageStart            = true,
    onTransform             = true,
    onStep                  = true,
    onPreDraw               = true,
    onPostDraw              = true
}

local has_custom_buff = {}
local has_callbacks = {}



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

    return buff
end



-- ========== Instance Methods ==========

methods_buff = {

    add_callback = function(self, callback, func)
        -- Add onApply callback to add actor to has_custom_item
        local function add_onApply()
            if has_callbacks[self.value] then return end
            has_callbacks[self.value] = true

            local callback_id = self.on_apply
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], function(actor, stack)
                has_custom_buff[actor.id] = true
            end)
        end

        local callback_id = nil
        if      callback == "onApply"       then callback_id = self.on_apply
        elseif  callback == "onRemove"      then callback_id = self.on_remove
        elseif  callback == "onStep"        then callback_id = self.on_step
        end

        if callback_id then
            add_onApply()
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            callbacks[callback_id]["id"] = self.value
            table.insert(callbacks[callback_id], func)

        elseif valid_callbacks[callback] then
            add_onApply()
            if not callbacks[callback] then callbacks[callback] = {} end
            if not callbacks[callback][self.value] then callbacks[callback][self.value] = {} end
            table.insert(callbacks[callback][self.value], func)

        else log.error("Invalid callback name", 2)
        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_apply] = nil
        callbacks[self.on_remove] = nil
        callbacks[self.on_step] = nil

        for callback, _ in pairs(valid_callbacks) do
            local c_table = callbacks[callback]
            if c_table then c_table[self.value] = nil end
        end

        has_callbacks[self.value] = nil
    end

}

-- Callbacks
for c, _ in pairs(valid_callbacks) do
    methods_buff[c] = function(self, func)
        self:add_callback(c, func)
    end
end



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
    -- onApply, onRemove, onStep
    if callbacks[args[1].value] then
        local id = callbacks[args[1].value]["id"]
        local actor = Instance.wrap(args[2].value)
        local stack = actor:buff_stack_count(id)
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(actor, stack)
        end
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    actor:get_data().post_stat_recalc = true

    if not callbacks["onStatRecalc"] then return end
    if not has_custom_buff[actor.id] then return end

    for buff_id, c_table in pairs(callbacks["onStatRecalc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


-- gm.pre_script_hook(gm.constants.actor_transform, function(self, other, result, args)
--     if callbacks["onChange"] then
--         local actor = Instance.wrap(args[1].value)
--         for _, fn in pairs(callbacks["onChange"]) do
--             local count = actor:buff_stack_count(fn[1])
--             if count > 0 then
--                 fn[2](actor, Instance.wrap(args[2].value), count)   -- Actor, To, Buff stack
--             end
--         end
--     end
-- end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks["onPreDraw"] then return end
    if not has_custom_buff[self.id] then return end

    local actor = Instance.wrap(self)

    for buff_id, c_table in pairs(callbacks["onPreDraw"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks["onPostDraw"] then return end
    if not has_custom_buff[self.id] then return end

    local actor = Instance.wrap(self)

    for buff_id, c_table in pairs(callbacks["onPostDraw"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    -- Extend buff_stack if necessary
    if gm.typeof(args[1].value) == "struct" then
        if gm.array_length(args[1].value.buff_stack) <= args[2].value then gm.array_resize(args[1].value.buff_stack, args[2].value + 1) end
    end
end)



-- ========== Callbacks ==========

function buff_onPostStatRecalc(actor)
    if not callbacks["onPostStatRecalc"] then return end

    for buff_id, c_table in pairs(callbacks["onPostStatRecalc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end



return Buff
