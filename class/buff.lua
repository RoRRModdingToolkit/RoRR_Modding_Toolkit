-- Buff

Buff = class_refs["Buff"]

local callbacks = {}
local valid_callbacks = {
    onApply                 = true,
    onRemove                = true,
    onPreStep               = true,
    onPostStep              = true,
    onPreDraw               = true,
    onPostDraw              = true,
    onStatRecalc            = true,
    onPostStatRecalc        = true,
    onAttackCreate          = true,
    onAttackCreateProc      = true,
    onAttackHit             = true,
    onAttackHandleEnd       = true,
    onAttackHandleEndProc   = true,
    onDamageCalculate       = true,
    onDamageCalculateProc   = true,
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
    onTransform             = true
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
        -- Add onApply callback to add actor to has_custom_buff
        local function add_onApply()
            if has_callbacks[self.value] then return end
            has_callbacks[self.value] = true

            local callback_id = self.on_apply
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            callbacks[callback_id]["id"] = self.value
            table.insert(callbacks[callback_id], function(actor, stack)
                has_custom_buff[actor.id] = true
            end)
        end

        local callback_id = nil
        if      callback == "onApply"       then callback_id = self.on_apply
        elseif  callback == "onRemove"      then callback_id = self.on_remove
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
    -- onApply and onRemove
    if callbacks[args[1].value] then
        local id = callbacks[args[1].value]["id"]
        local actor = Instance.wrap(args[2].value)
        local stack = actor:buff_stack_count(id)
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(actor, stack)
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_buff[self.id] then return end

    local actor = Instance.wrap(self)
    local actorData = actor:get_data("buff")

    if callbacks["onPreStep"] then
        for buff_id, c_table in pairs(callbacks["onPreStep"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end

    if not callbacks["onShieldBreak"] then return end

    if self.shield and self.shield > 0.0 then actorData.has_shield = true end
    if actorData.has_shield and self.shield <= 0.0 then
        actorData.has_shield = nil

        for buff_id, c_table in pairs(callbacks["onShieldBreak"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_buff[self.id] then return end
    if not callbacks["onPostStep"] then return end

    local actor = Instance.wrap(self)

    for buff_id, c_table in pairs(callbacks["onPostStep"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not has_custom_buff[self.id] then return end
    if not callbacks["onPreDraw"] then return end

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
    if not has_custom_buff[self.id] then return end
    if not callbacks["onPostDraw"] then return end

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


gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    if not callbacks["onDamageCalculate"] then return end

    local actor = Instance.wrap(args[6].value)
    if not Instance.exists(actor) then return end
    if not has_custom_buff[actor.id] then return end

    local victim = Instance.wrap(args[2].value)
    local damage = args[4].value
    local hit_info = Hit_Info.wrap(args[1].value)

    if callbacks["onDamageCalculate"] then
        for buff_id, c_table in pairs(callbacks["onDamageCalculate"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    local new = fn(actor, victim, stack, damage, hit_info)
                    if type(new) == "number" then damage = new end   -- Replace damage
                end
            end
        end
        args[4].value = damage
    end

    if Helper.is_false(hit_info.proc) then return end

    if callbacks["onDamageCalculateProc"] then
        for buff_id, c_table in pairs(callbacks["onDamageCalculateProc"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    local new = fn(actor, victim, stack, damage, hit_info)
                    if type(new) == "number" then damage = new end   -- Replace damage
                end
            end
        end
        args[4].value = damage
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if not has_custom_buff[self.id] then return end
    
    local callback = {
        "onPrimaryUse",
        "onSecondaryUse",
        "onUtilityUse",
        "onSpecialUse"
    }
    callback = callback[args[1].value + 1]
    if not callbacks[callback] then return end

    local actor = Instance.wrap(self)
    local active_skill = actor:get_active_skill(args[1].value)

    for buff_id, c_table in pairs(callbacks[callback]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, active_skill)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if not callbacks["onHeal"] then return end

    local actor = args[1].value
    if not has_custom_buff[actor.id] then return end

    actor = Instance.wrap(actor)
    local heal_amount = args[2].value

    for buff_id, c_table in pairs(callbacks["onHeal"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                local new = fn(actor, stack, heal_amount)
                if type(new) == "number" then heal_amount = new end   -- Replace heal_amount
            end
        end
    end
    args[2].value = heal_amount
end)


gm.pre_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    if not callbacks["onTransform"] then return end

    local actor = args[1].value
    if not has_custom_buff[actor.id] then return end

    actor = Instance.wrap(actor)
    local to = Instance.wrap(args[2].value)

    for buff_id, c_table in pairs(callbacks["onTransform"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, to, stack)
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
    if not has_custom_buff[actor.id] then return end

    for buff_id, c_table in pairs(callbacks["onPostStatRecalc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack)
            end
        end
    end
end


Callback.add("onAttackCreate", "RMT-Buff.onAttackCreate", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end
    if not has_custom_buff[actor.id] then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackCreate"] then
        for buff_id, c_table in pairs(callbacks["onAttackCreate"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackCreateProc"] then
        for buff_id, c_table in pairs(callbacks["onAttackCreateProc"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end
end)


Callback.add("onAttackHit", "RMT-Buff.onAttackHit", function(self, other, result, args)
    if not callbacks["onAttackHit"] then return end

    local hit_info = Hit_Info.wrap(args[2].value)
    local actor = hit_info.inflictor

    if not Instance.exists(actor) then return end
    if not has_custom_buff[actor.id] then return end

    actor = Instance.wrap(actor)
    local victim = Instance.wrap(hit_info.target_true)

    for buff_id, c_table in pairs(callbacks["onAttackHit"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack, hit_info)
            end
        end
    end
end)


Callback.add("onAttackHandleEnd", "RMT-Buff.onAttackHandleEnd", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end
    if not has_custom_buff[actor.id] then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackHandleEnd"] then
        for buff_id, c_table in pairs(callbacks["onAttackHandleEnd"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackHandleEndProc"] then
        for buff_id, c_table in pairs(callbacks["onAttackHandleEndProc"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack, attack_info)
                end
            end
        end
    end
end)


Callback.add("onHitProc", "RMT-Buff.onHitProc", function(self, other, result, args)     -- Runs before onAttackHit
    if not callbacks["onHitProc"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_buff[actor.id] then return end

    local victim = Instance.wrap(args[3].value)
    local hit_info = Hit_Info.wrap(args[4].value)

    for buff_id, c_table in pairs(callbacks["onHitProc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack, hit_info)
            end
        end
    end
end)


Callback.add("onKillProc", "RMT-Buff.onKillProc", function(self, other, result, args)
    if not callbacks["onKillProc"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_buff[actor.id] then return end

    local victim = Instance.wrap(args[2].value)

    for buff_id, c_table in pairs(callbacks["onKillProc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, victim, stack)
            end
        end
    end
end)


Callback.add("onDamagedProc", "RMT-Buff.onDamagedProc", function(self, other, result, args)
    if not callbacks["onDamagedProc"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_buff[actor.id] then return end

    local hit_info = Hit_Info.wrap(args[3].value)
    local attacker = Instance.wrap(hit_info.inflictor)

    for buff_id, c_table in pairs(callbacks["onDamagedProc"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, attacker, stack, hit_info)
            end
        end
    end
end)


Callback.add("onDamageBlocked", "RMT-Buff.onDamageBlocked", function(self, other, result, args)
    if not callbacks["onDamageBlocked"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_buff[actor.id] then return end

    local damage = args[4].value
    -- local source = Instance.wrap(other)

    for buff_id, c_table in pairs(callbacks["onDamageBlocked"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, damage)
            end
        end
    end
end)


Callback.add("onInteractableActivate", "RMT-Buff.onInteractableActivate", function(self, other, result, args)
    if not callbacks["onInteractableActivate"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_buff[actor.id] then return end

    local interactable = Instance.wrap(args[2].value)

    for buff_id, c_table in pairs(callbacks["onInteractableActivate"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, interactable)
            end
        end
    end
end)


Callback.add("onPickupCollected", "RMT-Buff.onPickupCollected", function(self, other, result, args)
    if not callbacks["onPickupCollected"] then return end

    local actor = Instance.wrap(args[3].value)
    if not has_custom_buff[actor.id] then return end

    local pickup_object = Instance.wrap(args[2].value)  -- Will be oCustomObject_pPickupbuff/Equipment for all custom buffs/equipment

    for buff_id, c_table in pairs(callbacks["onPickupCollected"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, pickup_object)
            end
        end
    end
end)


Callback.add("onEquipmentUse", "RMT-Buff.onEquipmentUse", function(self, other, result, args)
    if not callbacks["onEquipmentUse"] then return end

    local actor = Instance.wrap(args[2].value)
    if not has_custom_buff[actor.id] then return end

    local equipment = Equipment.wrap(args[3].value)
    local direction = args[5].value

    for buff_id, c_table in pairs(callbacks["onEquipmentUse"]) do
        local stack = actor:buff_stack_count(buff_id)
        if stack > 0 then
            for _, fn in ipairs(c_table) do
                fn(actor, stack, equipment, direction)
            end
        end
    end
end)


Callback.add("onStageStart", "RMT-Buff.onStageStart", function(self, other, result, args)
    for actor_id, _ in pairs(has_custom_buff) do
        if not Instance.exists(actor_id) then
            has_custom_buff[actor_id] = nil
        end
    end

    if not callbacks["onStageStart"] then return end

    for actor_id, _ in pairs(has_custom_buff) do
        local actor = Instance.wrap(actor_id)

        for buff_id, c_table in pairs(callbacks["onStageStart"]) do
            local stack = actor:buff_stack_count(buff_id)
            if stack > 0 then
                for _, fn in ipairs(c_table) do
                    fn(actor, stack)
                end
            end
        end
    end
end)



return Buff
