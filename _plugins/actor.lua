-- Actor

Actor = {}

local callbacks = {}
local other_callbacks = {
    "onStatRecalc",
    "onPostStatRecalc",
    "onBasicUse",
    "onAttack",
    "onAttackAll",
    "onPostAttack",
    "onPostAttackAll",
    "onHit",
    "onHitAll",
    "onKill",
    "onDamaged",
    "onDamageBlocked",
    "onHeal",
    "onShieldBreak",
    "onInteract",
    "onEquipmentUse",
    "onPreStep",
    "onPostStep",
    "onDraw"
}



-- ========== Static Methods ==========

Actor.add_callback = function(callback, id, func, skill, all_damage)
    if all_damage then callback = callback.."All" end

    if callback == "onSkillUse" then
        skill = Wrap.unwrap(skill)
        if not callbacks["onSkillUse"] then callbacks["onSkillUse"] = {} end
        if not callbacks["onSkillUse"][skill] then callbacks["onSkillUse"][skill] = {} end
        callbacks["onSkillUse"][skill][id] = func

    elseif Helper.table_has(other_callbacks, callback) then
        if not callbacks[callback] then callbacks[callback] = {} end
        callbacks[callback][id] = func

    else log.error("Invalid callback name", 2)

    end
end


Actor.remove_callback = function(id)
    local c_table = callbacks["onSkillUse"]
    if c_table then
        for s, id_table in pairs(c_table) do
            for i, __ in pairs(id_table) do
                if i == id then
                    id_table[i] = nil
                end
            end
        end
    end

    for _, c in ipairs(other_callbacks) do
        local c_table = callbacks[c]        -- callbacks["onAttack"]
        if c_table then
            for i, __ in pairs(c_table) do  -- callbacks["onAttack"][i (key)]
                if i == id then
                    c_table[i] = nil
                end
            end
        end
    end
end


Actor.callback_exists = function(id)
    local c_table = callbacks["onSkillUse"]
    if c_table then
        for s, id_table in pairs(c_table) do
            for i, __ in pairs(id_table) do
                if i == id then return true end
            end
        end
    end

    for _, c in ipairs(other_callbacks) do
        local c_table = callbacks[c]        -- callbacks["onAttack"]
        if c_table then
            for i, __ in pairs(c_table) do  -- callbacks["onAttack"][i (key)]
                if i == id then return true end
            end
        end
    end

    return false
end



-- ========== Instance Methods ==========

methods_actor = {

    is_grounded = function(self)
        return self.value:place_meeting(self.x, self.y + 1, gm.constants.oB) == 1.0 and self.activity_type ~= 2.0
    end,


    fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer)
        -- Set whether or not the bullet damager can pierce
        local can_pierce = false
        if pierce_multiplier then can_pierce = true end

        local damager = gm._mod_attack_fire_bullet(self.value, x, y, range, direction, damage, hit_sprite or -1, can_pierce, true).attack_info
        damager.damage_color = Color.WHITE_ALMOST

        -- Set pierce multiplier
        if pierce_multiplier then
            damager.damage_degrade = (1.0 - pierce_multiplier)
        end

        -- Set tracer_kind
        if tracer then
            damager.tracer_kind = tracer
        end

        return Damager.wrap(damager)
    end,


    fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite)
        local damager = gm._mod_attack_fire_explosion(self.value, x, y, width, height, damage, explosion_sprite or -1, sparks_sprite or -1, true).attack_info
        damager.damage_color = Color.WHITE_ALMOST

        return Damager.wrap(damager)
    end,


    fire_direct = function(self, target, damage, direction, x, y, hit_sprite)
        target = Wrap.unwrap(target)

        local damager = gm._mod_attack_fire_direct(self.value, target, x or target.x, y or target.y, direction or 0, damage, hit_sprite or -1, true).attack_info
        damager.damage_color = Color.WHITE_ALMOST
        
        return Damager.wrap(damager)
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
        return Skill.wrap(self.skills:get(slot).active_skill.skill_id)
    end,


    get_active_skill = function(self, slot)
        return self.skills:get(slot).active_skill
    end,


    get_default_skill = function(self, slot)
        return self.skills:get(slot).default_skill
    end,


    enter_state = function(self, state)
        gm.actor_set_state(self.value, Wrap.unwrap(state))
    end

}


methods_actor_callbacks = {
    
    onStatRecalc        = function(self, id, func) Actor.add_callback("onStatRecalc", id, func) end,
    onPostStatRecalc    = function(self, id, func) Actor.add_callback("onPostStatRecalc", id, func) end,
    onSkillUse          = function(self, id, func, skill) Actor.add_callback("onSkillUse", id, func, skill) end,
    onBasicUse          = function(self, id, func) Actor.add_callback("onBasicUse", id, func) end,
    onAttack            = function(self, id, func, all_damage) Actor.add_callback("onAttack", id, func, nil, all_damage) end,
    onPostAttack        = function(self, id, func, all_damage) Actor.add_callback("onPostAttack", id, func, nil, all_damage) end,
    onHit               = function(self, id, func, all_damage) Actor.add_callback("onHit", id, func, nil, all_damage) end,
    onKill              = function(self, id, func) Actor.add_callback("onKill", id, func) end,
    onDamaged           = function(self, id, func) Actor.add_callback("onDamaged", id, func) end,
    onDamageBlocked     = function(self, id, func) Actor.add_callback("onDamageBlocked", id, func) end,
    onHeal              = function(self, id, func) Actor.add_callback("onHeal", id, func) end,
    onShieldBreak       = function(self, id, func) Actor.add_callback("onShieldBreak", id, func) end,
    onInteract          = function(self, id, func) Actor.add_callback("onInteract", id, func) end,
    onEquipmentUse      = function(self, id, func) Actor.add_callback("onEquipmentUse", id, func) end,
    onPreStep           = function(self, id, func) Actor.add_callback("onPreStep", id, func) end,
    onPostStep          = function(self, id, func) Actor.add_callback("onPostStep", id, func) end,
    onDraw              = function(self, id, func) Actor.add_callback("onDraw", id, func) end

}



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
    end
}


metatable_actor_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_actor_callbacks[key] then
            return methods_actor_callbacks[key]
        end
    end
}
setmetatable(Actor, metatable_actor_callbacks)



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- Internal
    local actor = Instance.wrap(self)
    local actor_data = actor:get_data()
    actor_data.current_shield = actor.shield
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    local actor_data = actor:get_data()
    actor.shield = actor_data.current_shield

    if callbacks["onStatRecalc"] then
        for k, fn in pairs(callbacks["onStatRecalc"]) do
            fn(actor)   -- Actor
        end
    end

    actor_data.post_stat_recalc = true
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local actor = Instance.wrap(self)

    if callbacks["onSkillUse"] then
        for id, skill in pairs(callbacks["onSkillUse"]) do
            if gm.array_get(self.skills, args[1].value).active_skill.skill_id == id then
                for k, fn in pairs(skill) do
                    fn(actor)   -- Actor
                end
            end
        end
    end

    if args[1].value ~= 0.0 or gm.array_get(self.skills, 0).active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for k, fn in pairs(callbacks["onBasicUse"]) do
            fn(actor)   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for k, fn in pairs(callbacks["onHeal"]) do
            fn(Instance.wrap(args[1].value), args[2].value)   -- Actor, Heal amount
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPreStep"] then
        for k, fn in pairs(callbacks["onPreStep"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end

    if self.shield and self.shield > 0.0 then self.RMT_has_shield_actor = true end
    if self.RMT_has_shield_actor and self.shield <= 0.0 then
        self.RMT_has_shield_actor = nil
        if callbacks["onShieldBreak"] then
            for k, fn in pairs(callbacks["onShieldBreak"]) do
                fn(Instance.wrap(self))   -- Actor
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPostStep"] then
        for k, fn in pairs(callbacks["onPostStep"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if callbacks["onDraw"] then
        for k, fn in pairs(callbacks["onDraw"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)



-- ========== Callbacks ==========

function actor_onPostStatRecalc(actor)
    if callbacks["onPostStatRecalc"] then
        for k, fn in pairs(callbacks["onPostStatRecalc"]) do
            fn(actor)   -- Actor
        end
    end
end


local function actor_onAttack(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks["onAttack"] then
        for k, fn in pairs(callbacks["onAttack"]) do
            fn(Instance.wrap(self), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function actor_onAttackAll(self, other, result, args)
    if callbacks["onAttackAll"] then
        for k, fn in pairs(callbacks["onAttackAll"]) do
            fn(Instance.wrap(self), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function actor_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttack"] then
        for k, fn in pairs(callbacks["onPostAttack"]) do
            fn(Instance.wrap(args[2].value.parent), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function actor_onPostAttackAll(self, other, result, args)
    if not Instance.exists(args[2].value.parent) then return end
    if callbacks["onPostAttackAll"] then
        for k, fn in pairs(callbacks["onPostAttackAll"]) do
            fn(Instance.wrap(args[2].value.parent), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function actor_onHit(self, other, result, args)
    if not self.attack_info.proc then return end
    if callbacks["onHit"] then
        for k, fn in pairs(callbacks["onHit"]) do
            fn(Instance.wrap(args[2].value), Instance.wrap(args[3].value), Damager.wrap(self.attack_info)) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function actor_onHitAll(self, other, result, args)
    local attack = args[2].value
    if not Instance.exists(attack.inflictor) then return end
    if callbacks["onHitAll"] then
        for k, fn in pairs(callbacks["onHitAll"]) do
            fn(Instance.wrap(attack.inflictor), Instance.wrap(attack.target_true), Damager.wrap(attack.attack_info)) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function actor_onKill(self, other, result, args)
    if callbacks["onKill"] then
        for k, fn in pairs(callbacks["onKill"]) do
            fn(Instance.wrap(args[3].value), Instance.wrap(args[2].value))   -- Attacker, Victim
        end
    end
end


local function actor_onDamaged(self, other, result, args)
    if not args[3].value.attack_info then return end
    if callbacks["onDamaged"] then
        for k, fn in pairs(callbacks["onDamaged"]) do
            fn(Instance.wrap(args[2].value), Damager.wrap(args[3].value.attack_info))   -- Actor, Damager attack_info
        end
    end
end


local function actor_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for k, fn in pairs(callbacks["onDamageBlocked"]) do
            fn(Instance.wrap(self), Damager.wrap(other.attack_info))   -- Actor, Damager attack_info
        end
    end
end


local function actor_onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        for k, fn in pairs(callbacks["onInteract"]) do
            fn(Instance.wrap(args[3].value), Instance.wrap(args[2].value))   -- Actor, Interactable
        end
    end
end


local function actor_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for k, fn in pairs(callbacks["onEquipmentUse"]) do
            fn(Instance.wrap(args[2].value), Equipment.wrap(args[3].value))   -- Actor, Equipment ID
        end
    end
end



-- ========== Initialize ==========

Actor.__initialize = function()
    Callback.add("onAttackCreate", "RMT.actor_onAttack", actor_onAttack, true)
    Callback.add("onAttackCreate", "RMT.actor_onAttackAll", actor_onAttackAll, true)
    Callback.add("onAttackHandleEnd", "RMT.actor_onPostAttack", actor_onPostAttack, true)
    Callback.add("onAttackHandleEnd", "RMT.actor_onPostAttackAll", actor_onPostAttackAll, true)
    Callback.add("onHitProc", "RMT.actor_onHit", actor_onHit, true)
    Callback.add("onAttackHit", "RMT.actor_onHitAll", actor_onHitAll, true)
    Callback.add("onKillProc", "RMT.actor_onKill", actor_onKill, true)
    Callback.add("onDamagedProc", "RMT.actor_onDamaged", actor_onDamaged, true)
    Callback.add("onDamageBlocked", "RMT.actor_onDamageBlocked", actor_onDamageBlocked, true)
    Callback.add("onInteractableActivate", "RMT.actor_onInteract", actor_onInteract, true)
    Callback.add("onEquipmentUse", "RMT.actor_onEquipmentUse", actor_onEquipmentUse, true)

    Actor:onDamaged("rmt-actorAllowStun", function(actor, damager)
        -- Allow stun application even if damager.proc is false
        if damager.stun > 0 and (damager.proc == 0.0 or damager.proc == false) and damager.RMT_allow_stun then
            actor:apply_stun(damager.knockback_kind, damager.knockback_direction, damager.stun * 1.5)
        end
    end)
end