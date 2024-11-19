-- Actor

return

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


    fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer, no_proc)
        -- Set whether or not the bullet damager can pierce
        local can_pierce = false
        if pierce_multiplier then can_pierce = true end

        local inst = GM._mod_attack_fire_bullet(self.value, x, y, range, direction, damage, hit_sprite or -1, can_pierce, not no_proc)
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST

        -- Set pierce multiplier
        -- and tracer_kind
        if pierce_multiplier then attack_info.damage_degrade = (1.0 - pierce_multiplier) end
        if tracer then attack_info.tracer_kind = tracer end

        return inst
    end,


    fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, no_proc)
        local inst = GM._mod_attack_fire_explosion(self.value, x, y, width, height, damage, explosion_sprite or -1, sparks_sprite or -1, not no_proc)
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST

        return inst
    end,


    fire_explosion_local = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, no_proc)
        local mask = gm.constants.sBite1Mask
        self.value:fire_explosion_local(0, x, y, damage, sparks_sprite or -1, 2, width / GM.sprite_get_width(mask), height / GM.sprite_get_height(mask))
        local inst = GM.variable_global_get("attack_bullet")
        local attack_info = inst.attack_info
        attack_info.damage_color = Color.WHITE_ALMOST

        -- Create explosion sprite manually
        if explosion_sprite then
            GM.instance_create(x, y, gm.constants.oEfExplosion).sprite_index = explosion_sprite
        end

        return inst
    end,


    fire_direct = function(self, target, damage, direction, x, y, hit_sprite, no_proc)
        target = Wrap.unwrap(target)

        local inst = GM._mod_attack_fire_direct(self.value, target, x or target.x, y or target.y, direction or 0, damage, hit_sprite or -1, not no_proc)
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
        if kind > Damager.KNOCKBACK_KIND.standard then
            gm.actor_knockback_inflict(self.value, Damager.KNOCKBACK_KIND.standard, direction, 1)
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


    item_give = function(self, item, count, temp)
        item = Wrap.unwrap(item)
        if not temp then temp = false end
        gm.item_give(self.value, item, count or 1, temp)
    end,


    item_remove = function(self, item, count, temp)
        item = Wrap.unwrap(item)
        if not temp then temp = false end
        gm.item_take(self.value, item, count or 1, temp)
    end,


    item_stack_count = function(self, item, item_type)
        item = Wrap.unwrap(item)
        if item_type == Item.TYPE.real then return gm.item_count(self.value, item, false) end
        if item_type == Item.TYPE.temporary then return gm.item_count(self.value, item, true) end
        return gm.item_count(self.value, item, false) + gm.item_count(self.value, item, true)
    end,


    buff_apply = function(self, buff, duration, count)
        buff = Wrap.unwrap(buff)
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

        gm.apply_buff(self.value, buff, duration, count or 1)

        -- Clamp to max stack or under
        -- Funny stuff happens if this is exceeded
        local buff_array = Buff.wrap(buff)
        self.buff_stack:set(buff, math.min(self:buff_stack_count(buff), buff_array.max_stack))
    end,


    buff_remove = function(self, buff, count)
        buff = Wrap.unwrap(buff)
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

        local stack_count = self:buff_stack_count(buff)
        if (not count) or count >= stack_count then gm.remove_buff(self.value, buff)
        else self.buff_stack:set(buff, stack_count - count)
        end
    end,


    buff_stack_count = function(self, buff)
        buff = Wrap.unwrap(buff)
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

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


    -- reduce_skill_cooldown = function(self, slot, amount)
    --     if type(slot) ~= "number" or slot < 0 or slot > 3 then log.error("Skill slot must be between 0 and 3 (inclusive)", 2) end
    --     local struct = self.skills:get(slot).active_skill
    --     -- struct.cooldown_reset_frame = struct.cooldown_reset_frame - amount
    -- end,


    enter_state = function(self, state)
        GM.actor_set_state(self.value, state)
    end

}


methods_actor_callbacks = {}

for c, _ in pairs(valid_callbacks) do
    methods_actor_callbacks[c] = function(self, id, func)
        Actor.add_callback(c, id, func)
    end
end

methods_actor_callbacks["onSkillUse"] = function(self, id, func, skill)
    Actor.add_callback("onSkillUse", id, func, skill)
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


    __metatable = "actor"
}


metatable_actor_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_actor_callbacks[key] then
            return methods_actor_callbacks[key]
        end
    end,

    __metatable = "actor_callbacks"
}
Actor:setmetatable(metatable_actor_callbacks)



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- There was a reason for this existing but I forgot why
    -- Nevertheless it seems important so do not remove
    local actor = Instance.wrap(self)
    local actorData = actor:get_data()
    actorData.current_shield = actor.shield
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    local actorData = actor:get_data()
    actor.shield = actorData.current_shield
    actorData.post_stat_recalc = true

    if not callbacks["onStatRecalc"] then return end

    for _, fn in pairs(callbacks["onStatRecalc"]) do
        fn(actor)
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
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

    for _, fn in pairs(callbacks[callback]) do
        fn(actor, active_skill)
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


gm.post_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if not callbacks["onHeal"] then return end

    local actor = Instance.wrap(args[1].value)
    local heal_amount = args[2].value

    for _, fn in pairs(callbacks["onHeal"]) do
        fn(actor, heal_amount)
    end
end)



-- ========== Callbacks ==========

function actor_onPostStatRecalc(actor)
    if not callbacks["onPostStatRecalc"] then return end

    for _, fn in pairs(callbacks["onPostStatRecalc"]) do
        fn(actor)
    end
end



-- ========== Initialize ==========

-- Actor:onDamaged("RMT-actorAllowStun", function(actor, damager)
--     -- Allow stun application even if damager.proc is false
--     if damager.stun > 0 and (damager.proc == 0.0 or damager.proc == false) and damager.RMT_allow_stun then
--         actor:apply_stun(damager.knockback_kind, damager.knockback_direction, damager.stun * 1.5)
--     end
-- end)



return Actor