-- Actor

Actor = {}

local callbacks = {}



-- ========== Enums ==========

Actor.KNOCKBACK_KIND = {
    none        = 0,
    standard    = 1,
    freeze      = 2,
    deepfreeze  = 3,
    pull        = 4
}


Actor.KNOCKBACK_DIR = {
    left    = -1,
    right   = 1
}



-- ========== Static Methods ==========

Actor.add_callback = function(callback, func, skill, all_damage)
    if all_damage then callback = callback.."All" end

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

    if callback == "onSkillUse" then
        if type(skill) == "table" then skill = skill.value end
        if not callbacks["onSkillUse"] then callbacks["onSkillUse"] = {} end
        if not callbacks["onSkillUse"][skill] then callbacks["onSkillUse"][skill] = {} end
        table.insert(callbacks["onSkillUse"][skill], func)

    elseif Helper.table_has(other_callbacks, callback) then
        if not callbacks[callback] then callbacks[callback] = {} end
        table.insert(callbacks[callback], func)

    else log.error("Invalid callback name", 2)

    end
end



-- ========== Instance Methods ==========

methods_actor = {

    is_grounded = function(self)
        return self.value:place_meeting(self.x, self.y + 1, gm.constants.oB) == 1.0 and self.activity_type ~= 2.0
    end,


    recalculate_stats = function(self)
        self.value:recalculate_stats()
    end,


    fire_bullet = function(self, x, y, direction, range, damage, pierce_multiplier, hit_sprite)
        local damager = self.value:fire_bullet(0, x, y, (pierce_multiplier and 1) or 0, damage, range, hit_sprite or -1, direction, 1.0, 1.0, -1.0)
        if pierce_multiplier then damager.damage_degrade = (1.0 - pierce_multiplier) end
        return damager
    end,


    fire_explosion = function(self, x, y, x_radius, y_radius, damage, stun, hit_sprite)
        local damager = self.value:fire_explosion(0, x, y, damage, hit_sprite or -1, 2, -1, x_radius / 32.0, y_radius / 8.0)
        if stun then damager.stun = stun end
        return damager
    end,


    take_damage = function(self, damage, source, x, y, color, crit_sfx)
        local source_inst = nil
        if source then
            if type(source) == "table" then source = source.value end
            source_inst = source
        end
        if not crit_sfx then crit_sfx = false end
        gm.damage_inflict(self.value, damage, 0.0, source_inst, x or self.x, y or self.y - 28, damage, 1.0, color or Color.WHITE, crit_sfx)
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


    apply_knockback = function(self, kind, direction, duration)
        -- Other types don't completely stun
        if kind > Actor.KNOCKBACK_KIND.standard then
            gm.actor_knockback_inflict(self.value, Actor.KNOCKBACK_KIND.standard, direction, duration *60)
        end
        
        gm.actor_knockback_inflict(self.value, kind, direction, duration *60)
    end,


    kill = function(self)
        if self.hp then self.hp = -1000000.0 end
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
    end

}


methods_actor_callbacks = {
    
    onStatRecalc        = function(self, func) Actor.add_callback("onStatRecalc", func) end,
    onPostStatRecalc    = function(self, func) Actor.add_callback("onPostStatRecalc", func) end,
    onSkillUse          = function(self, func, skill) Actor.add_callback("onSkillUse", func, skill) end,
    onBasicUse          = function(self, func) Actor.add_callback("onBasicUse", func) end,
    onAttack            = function(self, func, all_damage) Actor.add_callback("onAttack", func, all_damage) end,
    onPostAttack        = function(self, func, all_damage) Actor.add_callback("onPostAttack", func, all_damage) end,
    onHit               = function(self, func, all_damage) Actor.add_callback("onHit", func, all_damage) end,
    onKill              = function(self, func) Actor.add_callback("onKill", func) end,
    onDamaged           = function(self, func) Actor.add_callback("onDamaged", func) end,
    onDamageBlocked     = function(self, func) Actor.add_callback("onDamageBlocked", func) end,
    onHeal              = function(self, func) Actor.add_callback("onHeal", func) end,
    onShieldBreak       = function(self, func) Actor.add_callback("onShieldBreak", func) end,
    onInteract          = function(self, func) Actor.add_callback("onInteract", func) end,
    onEquipmentUse      = function(self, func) Actor.add_callback("onEquipmentUse", func) end,
    onPreStep           = function(self, func) Actor.add_callback("onPreStep", func) end,
    onPostStep          = function(self, func) Actor.add_callback("onPostStep", func) end,
    onDraw              = function(self, func) Actor.add_callback("onDraw", func) end

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

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if callbacks["onStatRecalc"] then
        for _, fn in ipairs(callbacks["onStatRecalc"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end

    if callbacks["onPostStatRecalc"] then
        for _, fn in ipairs(callbacks["onPostStatRecalc"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)


gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local actor = Instance.wrap(self)

    if callbacks["onSkillUse"] then
        for id, skill in ipairs(callbacks["onSkillUse"]) do
            if gm.array_get(self.skills, args[1].value).active_skill.skill_id == id then
                for _, fn in pairs(skill) do
                    fn(actor)   -- Actor
                end
            end
        end
    end

    if args[1].value ~= 0.0 or gm.array_get(self.skills, 0).active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for _, fn in ipairs(callbacks["onBasicUse"]) do
            fn(actor)   -- Actor
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for _, fn in ipairs(callbacks["onHeal"]) do
            fn(Instance.wrap(args[1].value), args[2].value)   -- Actor, Heal amount
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPreStep"] then
        for _, fn in ipairs(callbacks["onPreStep"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end

    if self.shield and self.shield > 0.0 then self.RMT_has_shield_actor = true end
    if self.RMT_has_shield_actor and self.shield <= 0.0 then
        self.RMT_has_shield_actor = nil
        if callbacks["onShieldBreak"] then
            for _, fn in ipairs(callbacks["onShieldBreak"]) do
                fn(Instance.wrap(self))   -- Actor
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPostStep"] then
        for _, fn in ipairs(callbacks["onPostStep"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if callbacks["onDraw"] then
        for _, fn in ipairs(callbacks["onDraw"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)



-- ========== Callbacks ==========

local function actor_onAttack(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks["onAttack"] then
        for _, fn in ipairs(callbacks["onAttack"]) do
            fn(Instance.wrap(self), args[2].value)    -- Actor, Damager attack_info
        end
    end
end


local function actor_onAttackAll(self, other, result, args)
    if callbacks["onAttackAll"] then
        for _, fn in ipairs(callbacks["onAttackAll"]) do
            fn(Instance.wrap(self), args[2].value)    -- Actor, Damager attack_info
        end
    end
end


local function actor_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not args[2].value.parent then return end
    if callbacks["onPostAttack"] then
        for _, fn in ipairs(callbacks["onPostAttack"]) do
            fn(Instance.wrap(args[2].value.parent), args[2].value)    -- Actor, Damager attack_info
        end
    end
end


local function actor_onPostAttackAll(self, other, result, args)
    if callbacks["onPostAttackAll"] then
        for _, fn in ipairs(callbacks["onPostAttackAll"]) do
            fn(Instance.wrap(args[2].value.parent), args[2].value)    -- Actor, Damager attack_info
        end
    end
end


local function actor_onHit(self, other, result, args)
    if not self.attack_info.proc then return end
    if callbacks["onHit"] then
        for _, fn in ipairs(callbacks["onHit"]) do
            fn(Instance.wrap(args[2].value), Instance.wrap(args[3].value), self.attack_info) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function actor_onHitAll(self, other, result, args)
    if callbacks["onHitAll"] then
        local attack = args[2].value
        for _, fn in ipairs(callbacks["onHitAll"]) do
            fn(Instance.wrap(attack.inflictor), Instance.wrap(attack.target_true), attack.attack_info) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function actor_onKill(self, other, result, args)
    if callbacks["onKill"] then
        for _, fn in ipairs(callbacks["onKill"]) do
            fn(Instance.wrap(args[3].value), Instance.wrap(args[2].value))   -- Attacker, Victim
        end
    end
end


local function actor_onDamaged(self, other, result, args)
    if callbacks["onDamaged"] then
        for _, fn in ipairs(callbacks["onDamaged"]) do
            fn(Instance.wrap(args[2].value), args[3].value.attack_info)   -- Actor, Damager attack_info
        end
    end
end


local function actor_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for _, fn in ipairs(callbacks["onDamageBlocked"]) do
            fn(Instance.wrap(self), other.attack_info)   -- Actor, Damager attack_info
        end
    end
end


local function actor_onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        for _, fn in ipairs(callbacks["onInteract"]) do
            fn(Instance.wrap(args[3].value), Instance.wrap(args[2].value))   -- Actor, Interactable
        end
    end
end


local function actor_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for _, fn in ipairs(callbacks["onEquipmentUse"]) do
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
end