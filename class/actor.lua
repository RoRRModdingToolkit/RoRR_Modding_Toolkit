-- Actor

Actor = Proxy.new()

local callbacks = {}
local valid_callbacks = {
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
    -- onDamageCalculate       = true,
    -- onDamageCalculateProc   = true,
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
    onSkillUse              = true,
    onEquipmentUse          = true,
    onStageStart            = true
}



-- ========== Static Methods ==========

Actor.add_callback = function(callback, id, func, skill)
    if callback == "onSkillUse" then
        skill = Wrap.unwrap(skill)
        if not callbacks[callback] then callbacks[callback] = {} end
        if not callbacks[callback][skill] then callbacks[callback][skill] = {} end
        if not callbacks[callback][skill][id] then callbacks[callback][skill][id] = func
        else log.error("Callback ID already exists", 2)
        end

    elseif valid_callbacks[callback] then
        if not callbacks[callback] then callbacks[callback] = {} end
        if not callbacks[callback][id] then callbacks[callback][id] = func
        else log.error("Callback ID already exists", 2)
        end

    else log.error("Invalid callback name", 2)
    end
end


Actor.remove_callback = function(id)
    local c_table = callbacks["onSkillUse"]
    if c_table then
        for _, skill_table in pairs(c_table) do
            skill_table[id] = nil
        end
    end

    for callback, _ in pairs(valid_callbacks) do
        local c_table = callbacks[callback]
        if c_table then c_table[id] = nil end
    end
end


Actor.callback_exists = function(id)
    local c_table = callbacks["onSkillUse"]
    if c_table then
        for _, skill_table in pairs(c_table) do
            if skill_table[id] then return true end
        end
    end

    for callback, _ in pairs(valid_callbacks) do
        local c_table = callbacks[callback]
        if c_table and c_table[id] then return true end
    end

    return false
end



-- ========== Instance Methods ==========

methods_actor = {

    is_grounded = function(self)
        return self.value:place_meeting(self.x, self.y + 1, gm.constants.oB) == 1.0 and self.activity_type ~= 2.0
    end,


    fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer, can_proc)
        -- Set whether or not the bullet attack can pierce
        local can_pierce = false
        if pierce_multiplier then can_pierce = true end

        if can_proc == nil then can_proc = true end

        local inst = GM._mod_attack_fire_bullet(self.value, x, y, range, direction, damage, hit_sprite or gm.constants.sNone, can_pierce, can_proc)
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST

        -- Set pierce multiplier
        -- and tracer_kind
        if pierce_multiplier then attack_info.damage_degrade = (1.0 - pierce_multiplier) end
        if tracer then attack_info.tracer_kind = tracer end

        return inst
    end,


    fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        if can_proc == nil then can_proc = true end

        local inst = GM._mod_attack_fire_explosion(self.value, x, y, width, height, damage, explosion_sprite or gm.constants.sNone, sparks_sprite or gm.constants.sNone, can_proc)
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST

        return inst
    end,


    fire_explosion_local = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        if can_proc == nil then can_proc = true end

        local mask = gm.constants.sBite1Mask
        self.value:fire_explosion_local(0, x, y, damage, sparks_sprite or gm.constants.sNone, 2, width / GM.sprite_get_width(mask), height / GM.sprite_get_height(mask))
        local inst = GM.variable_global_get("attack_bullet")
        local attack_info = inst.attack_info
        attack_info.proc = can_proc
        attack_info.damage_color = Color.WHITE_ALMOST

        -- Create explosion sprite manually
        if explosion_sprite then
            GM.instance_create(x, y, gm.constants.oEfExplosion).sprite_index = explosion_sprite
        end

        return inst
    end,


    fire_direct = function(self, target, damage, direction, x, y, hit_sprite, can_proc)
        target = Wrap.unwrap(target)

        if can_proc == nil then can_proc = true end

        local inst = GM._mod_attack_fire_direct(self.value, target, x or target.x, y or target.y, direction or 0, damage, hit_sprite or gm.constants.sNone, can_proc)
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST
        
        return inst
    end,
    

    kill = function(self)
        if self.hp then self.hp = -1000000.0 end
    end,


    heal = function(self, amount)
        gm.actor_heal_networked(self.value, amount, false)
    
        -- Health bar flash (if this client's player is healed)
        if self:same(Player.get_client()) then
            local hud = Instance.find(gm.constants.oHUD)
            if hud:exists() then
                hud.player_hud_display_info:get(0).heal_flash = 0.5
            end
        end
    end,


    add_barrier = function(self, amount)
        gm.actor_heal_barrier(self.value, amount)
    end,


    set_barrier = function(self, amount)
        if self.barrier <= 0 then self:add_barrier(1) end
        self.barrier = amount
    end,


    is_immune = function(self)
        if self.invincible == false then self.invincible = 0 end
        return self.invincible > 0
    end,


    set_immune = function(self, amount)
        if self.invincible == false then self.invincible = 0 end
        self.invincible = math.max(self.invincible, amount)
    end,


    remove_immune = function(self)
        self.invincible = 0
    end,


    apply_stun = function(self, kind, direction, duration)
        -- Other types don't completely stun
        if kind > Attack_Info.KNOCKBACK_KIND.standard then
            gm.actor_knockback_inflict(self.value, Attack_Info.KNOCKBACK_KIND.standard, direction, 1)
        end
        gm.actor_knockback_inflict(self.value, kind, direction, duration *60)
    end,


    apply_dot = function(self, damage, source, ticks, rate, color, use_raw_damage)
        local dot = GM.instance_create(0, 0, gm.constants.oDot)
        dot.target = self
        dot.damage = damage
        if source then
            dot.parent = source
            if not use_raw_damage then dot.damage = damage * source.damage end
        end
        dot.ticks = ticks
        dot.rate = rate
        dot.textColor = Color.WHITE
        if color then dot.textColor = color end
        return dot
    end,


    item_give = function(self, item, count, kind)
        item = Wrap.unwrap(item)
        if not kind then kind = Item.STACK_KIND.normal end
        gm.item_give(self.value, item, count or 1, kind)
    end,


    item_remove = function(self, item, count, kind)
        item = Wrap.unwrap(item)
        if not kind then kind = Item.STACK_KIND.normal end
        gm.item_take(self.value, item, count or 1, kind)
    end,


    item_stack_count = function(self, item, kind)
        item = Wrap.unwrap(item)
        if not kind then kind = Item.STACK_KIND.any end
        return gm.item_count(self.value, item, kind)
    end,


    buff_apply = function(self, buff, duration, count)
        buff = Wrap.unwrap(buff)
        -- if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end  -- No longer needed

        gm.apply_buff(self.value, buff, duration, count or 1)

        -- Clamp to max stack or under
        -- Funny stuff happens if this is exceeded
        local buff_array = Buff.wrap(buff)
        self.buff_stack:set(buff, math.min(self:buff_stack_count(buff), buff_array.max_stack))
    end,


    buff_remove = function(self, buff, count)
        buff = Wrap.unwrap(buff)
        -- if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end  -- No longer needed

        local stack_count = self:buff_stack_count(buff)
        if (not count) or count >= stack_count then gm.remove_buff(self.value, buff)
        else
            self.buff_stack:set(buff, stack_count - count)
            self:recalculate_stats()
        end
    end,


    buff_stack_count = function(self, buff)
        buff = Wrap.unwrap(buff)
        -- if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end  -- No longer needed

        local count = self.buff_stack:get(buff)
        if count == nil then return 0 end
        return count
    end,


    get_skill = function(self, slot)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        return Skill.wrap(self.skills:get(slot).active_skill.skill_id)
    end,


    get_default_skill = function(self, slot)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        return self.skills:get(slot).default_skill
    end,


    get_active_skill = function(self, slot)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        return self.skills:get(slot).active_skill
    end,


    set_default_skill = function(self, slot, skill)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        GM.actor_skill_set(self, slot, skill)
    end,


    add_skill_override = function(self, slot, skill, priority)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        local struct = self.skills:get(slot)
        struct.add_override(struct, struct.active_skill, Wrap.unwrap(skill), priority or 0)
    end,


    remove_skill_override = function(self, slot, skill, priority)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        local struct = self.skills:get(slot)
        struct.remove_override(struct, struct.active_skill, Wrap.unwrap(skill), priority or 0)
    end,


    refresh_skill = function(self, slot)
        if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
        local struct = self.skills:get(slot).active_skill
        struct.reset_cooldown(struct, struct)
    end,


    freeze_default_skill = function(self, slot)
        local struct = self:get_default_skill(slot)
        struct.freeze_cooldown(struct, self.value)
    end,


    freeze_active_skill = function(self, slot)
        local struct = self:get_active_skill(slot)
        struct.freeze_cooldown(struct, self.value)
    end,


    freeze_other_overrides = function(self, slot)
        local skills_slot = self.skills:get(slot)
        local overrides = skills_slot.overrides
        local size = gm.array_length(overrides)
        if size > 0 then
            -- Freeze other override cds
            local struct = skills_slot.active_skill
            for i = 0, size - 1 do
                local override_skill = gm.array_get(overrides, i).skill
                if struct ~= override_skill then
                    override_skill.freeze_cooldown(override_skill, self.value)
                end
            end
        end
    end,


    override_default_skill_cooldown = function(self, slot, value)
        local struct = self:get_default_skill(slot)
        struct.override_cooldown(struct, self.value, value)
    end,


    override_active_skill_cooldown = function(self, slot, value)
        local struct = self:get_active_skill(slot)
        struct.override_cooldown(struct, self.value, value)
    end,


    enter_state = function(self, state)
        GM.actor_set_state(self.value, state)
    end

}


methods_actor_callbacks = {}

for c, _ in pairs(valid_callbacks) do
    methods_actor_callbacks[c] = function(self, id, func, skill)
        Actor.add_callback(c, id, func, skill)
    end
end



-- ========== Metatables ==========

metatable_actor = {
    __index = function(table, key)
        -- Methods
        if methods_actor[key] then
            return methods_actor[key]
        end

        -- Pass to next metatable
        return metatable_instance.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end,


    __metatable = "Actor"
}


metatable_actor_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_actor_callbacks[key] then
            return methods_actor_callbacks[key]
        end
    end,

    __metatable = "Actor Callbacks"
}
Actor:setmetatable(metatable_actor_callbacks)



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not callbacks["onPreStep"] and not callbacks["onShieldBreak"] then return end

    local actor = Instance.wrap(self)
    local actorData = actor:get_data("actor")

    if callbacks["onPreStep"] then
        for _, fn in pairs(callbacks["onPreStep"]) do
            fn(actor)
        end
    end

    if not callbacks["onShieldBreak"] then return end

    if self.shield and self.shield > 0.0 then actorData.has_shield = true end
    if actorData.has_shield and self.shield <= 0.0 then
        actorData.has_shield = nil

        for _, fn in pairs(callbacks["onShieldBreak"]) do
            fn(actor)
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not callbacks["onPostStep"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks["onPostStep"]) do
        fn(actor)
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks["onPreDraw"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks["onPreDraw"]) do
        fn(actor)
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks["onPostDraw"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks["onPostDraw"]) do
        fn(actor)
    end
end)


gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- Without this, if any shield damage is taken while
    -- NOT in possession of a vanilla shield item,
    -- running recalculate_stats will remove the
    -- remaining amount of shield

    -- This is probably related to the fact that the
    -- recalculate_stats hook below is post_script, and thus
    -- runs after some important code in recalculate_stats

    local actor = Instance.wrap(self)
    local actorData = actor:get_data(nil, _ENV["!guid"])
    actorData.current_shield = actor.shield
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    local actorData = actor:get_data(nil, _ENV["!guid"])
    actor.shield = actorData.current_shield
    actorData.post_stat_recalc = true

    if not callbacks["onStatRecalc"] then return end

    for _, fn in pairs(callbacks["onStatRecalc"]) do
        fn(actor)
    end
end)


-- gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
--     if not callbacks["onDamageCalculate"] then return end

--     local actor = Instance.wrap(args[6].value)
--     if not Instance.exists(actor) then return end

--     local victim = Instance.wrap(args[2].value)
--     local damage = args[4].value
--     local hit_info = Hit_Info.wrap(args[1].value)

--     if callbacks["onDamageCalculate"] then
--         for _, fn in pairs(callbacks["onDamageCalculate"]) do
--             local new = fn(actor, victim, damage, hit_info)
--             if type(new) == "number" then damage = new end   -- Replace damage
--         end
--         args[4].value = damage
--     end

--     if Helper.is_false(hit_info.proc) then return end

--     if callbacks["onDamageCalculateProc"] then
--         for _, fn in pairs(callbacks["onDamageCalculateProc"]) do
--             local new = fn(actor, victim, damage, hit_info)
--             if type(new) == "number" then damage = new end   -- Replace damage
--         end
--         args[4].value = damage
--     end
-- end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local callback = {
        "onPrimaryUse",
        "onSecondaryUse",
        "onUtilityUse",
        "onSpecialUse"
    }
    callback = callback[args[1].value + 1]

    local actor = Instance.wrap(self)
    local active_skill = actor:get_active_skill(args[1].value)

    if callbacks[callback] then
        for _, fn in pairs(callbacks[callback]) do
            fn(actor, active_skill)
        end
    end
    
    if not callbacks["onSkillUse"] then return end

    for skill_id, skill in pairs(callbacks["onSkillUse"]) do
        if active_skill.skill_id == skill_id then
            for _, fn in pairs(skill) do
                fn(actor, active_skill)
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if not callbacks["onHeal"] then return end

    local actor = Instance.wrap(args[1].value)
    local heal_amount = args[2].value

    for _, fn in pairs(callbacks["onHeal"]) do
        local new = fn(actor, heal_amount)
        if type(new) == "number" then heal_amount = new end   -- Replace heal_amount
    end
    args[2].value = heal_amount
end)



-- ========== Callbacks ==========

function actor_onPostStatRecalc(actor)
    if not callbacks["onPostStatRecalc"] then return end

    for _, fn in pairs(callbacks["onPostStatRecalc"]) do
        fn(actor)
    end
end


Callback_Raw.add("onAttackCreate", "RMT-Actor.onAttackCreate", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackCreate"] then
        for _, fn in pairs(callbacks["onAttackCreate"]) do
            fn(actor, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackCreateProc"] then
        for _, fn in pairs(callbacks["onAttackCreateProc"]) do
            fn(actor, attack_info)
        end
    end
end)


Callback_Raw.add("onAttackHit", "RMT-Actor.onAttackHit", function(self, other, result, args)
    if not callbacks["onAttackHit"] then return end

    local hit_info = Hit_Info.wrap(args[2].value)
    local actor = hit_info.inflictor

    if not Instance.exists(actor) then return end

    actor = Instance.wrap(actor)
    local victim = Instance.wrap(hit_info.target_true)

    for _, fn in pairs(callbacks["onAttackHit"]) do
        fn(actor, victim, hit_info)
    end
end)


Callback_Raw.add("onAttackHandleEnd", "RMT-Actor.onAttackHandleEnd", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent

    if not Instance.exists(actor) then return end

    actor = Instance.wrap(actor)

    if callbacks["onAttackHandleEnd"] then
        for _, fn in pairs(callbacks["onAttackHandleEnd"]) do
            fn(actor, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks["onAttackHandleEndProc"] then
        for _, fn in pairs(callbacks["onAttackHandleEndProc"]) do
            fn(actor, attack_info)
        end
    end
end)


Callback_Raw.add("onHitProc", "RMT-Actor.onHitProc", function(self, other, result, args)     -- Runs before onAttackHit
    if not callbacks["onHitProc"] then return end

    local actor = Instance.wrap(args[2].value)
    local victim = Instance.wrap(args[3].value)
    local hit_info = Hit_Info.wrap(args[4].value)

    for _, fn in pairs(callbacks["onHitProc"]) do
        fn(actor, victim, hit_info)
    end
end)


Callback_Raw.add("onKillProc", "RMT-Actor.onKillProc", function(self, other, result, args)
    if not callbacks["onKillProc"] then return end

    local actor = Instance.wrap(args[3].value)
    local victim = Instance.wrap(args[2].value)

    for _, fn in pairs(callbacks["onKillProc"]) do
        fn(actor, victim)
    end
end)


Callback_Raw.add("onDamagedProc", "RMT-Actor.onDamagedProc", function(self, other, result, args)
    if not callbacks["onDamagedProc"] then return end

    local actor = Instance.wrap(args[2].value)
    local hit_info = Hit_Info.wrap(args[3].value)
    local attacker = Instance.wrap(hit_info.inflictor)

    for _, fn in pairs(callbacks["onDamagedProc"]) do
        fn(actor, attacker, hit_info)
    end
end)


Callback_Raw.add("onDamageBlocked", "RMT-Actor.onDamageBlocked", function(self, other, result, args)
    if not callbacks["onDamageBlocked"] then return end

    local actor = Instance.wrap(args[2].value)
    local damage = args[4].value
    -- local source = Instance.wrap(other)

    for _, fn in pairs(callbacks["onDamageBlocked"]) do
        fn(actor, damage)
    end
end)


Callback_Raw.add("onInteractableActivate", "RMT-Actor.onInteractableActivate", function(self, other, result, args)
    if not callbacks["onInteractableActivate"] then return end

    local actor = Instance.wrap(args[3].value)
    local interactable = Instance.wrap(args[2].value)

    for _, fn in pairs(callbacks["onInteractableActivate"]) do
        fn(actor, interactable)
    end
end)


Callback_Raw.add("onPickupCollected", "RMT-Actor.onPickupCollected", function(self, other, result, args)
    if not callbacks["onPickupCollected"] then return end

    local actor = Instance.wrap(args[3].value)
    local pickup_object = Instance.wrap(args[2].value)  -- Will be oCustomObject_pPickupItem/Equipment for all custom items/equipment

    for _, fn in pairs(callbacks["onPickupCollected"]) do
        fn(actor, pickup_object)
    end
end)


Callback_Raw.add("onEquipmentUse", "RMT-Actor.onEquipmentUse", function(self, other, result, args)
    if not callbacks["onEquipmentUse"] then return end

    local actor = Instance.wrap(args[2].value)
    local equipment = Equipment.wrap(args[3].value)
    local direction = args[5].value

    for _, fn in pairs(callbacks["onEquipmentUse"]) do
        fn(actor, equipment, direction)
    end
end)


Callback_Raw.add("onStageStart", "RMT-Actor.onStageStart", function(self, other, result, args)
    if not callbacks["onStageStart"] then return end
    
    local actors = Instance.find_all(gm.constants.pActor)
    for _, actor in ipairs(actors) do
        for __, fn in pairs(callbacks["onStageStart"]) do
            fn(actor)
        end
    end
end)



-- ========== Initialize ==========

Actor:onDamagedProc("RMT-actorAllowStun", function(actor, attacker, hit_info)
    -- Allow stun application even if attack_info.proc is false
    if not hit_info.attack_info then return end
    if hit_info.stun > 0 and Helper.is_false(hit_info.proc) and hit_info.RMT_allow_stun then
        actor:apply_stun(hit_info.knockback_kind, hit_info.knockback_direction, hit_info.stun * 1.5)
    end
end)


Callback_Raw.add(Callback.TYPE.onDeath, "RMT-customCognantEliteFix", function(self, other, result, args)
    if args[3].value then return end    -- Do not spawn clone if out of bounds
    local actor = args[2].value

    if  actor.team ~= 1
    and gm._mod_net_isHost()
    and gm.bool(Class.ARTIFACT:get(13):get(8))
    and actor.elite_type ~= 7
    then
        local obj_id = Instance.wrap(actor):get_object_index_self()
        if obj_id >= Object.CUSTOM_START
        and (not object_cognant_blacklist[obj_id])
        then
            local new = gm.instance_create(actor.x, actor.y, obj_id)
            gm.elite_set(new, 7)
        end
    end
end)



return Actor