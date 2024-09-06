-- Actor

Actor = {}

local callbacks = {}



-- ========== Static Methods ==========

Actor.add_callback = function(callback, func, skill)
    if callback == "onSkillUse" then
        if type(skill) == "table" then skill = skill.value end
        if not callbacks["onSkillUse"] then callbacks["onSkillUse"] = {} end
        if not callbacks["onSkillUse"][skill] then callbacks["onSkillUse"][skill] = {} end
        table.insert(callbacks["onSkillUse"][skill], func)

    elseif callback == "onBasicUse"
        or callback == "onAttack"
        or callback == "onPostAttack"
        or callback == "onHit"
        or callback == "onKill"
        or callback == "onDamaged"
        or callback == "onDamageBlocked"
        or callback == "onHeal"
        or callback == "onShieldBreak"
        or callback == "onInteract"
        or callback == "onEquipmentUse"
        or callback == "onPreStep"
        or callback == "onPostStep"
        or callback == "onDraw"
        then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], func)

    end
end



-- ========== Instance Methods ==========

methods_actor = {

    is_grounded = function(self)
        return self.value:place_meeting(self.x, self.y + 1, gm.constants.oB) == 1.0 and self.activity_type ~= 2.0
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
        if actor.invincible == false then actor.invincible = 0 end
        return actor.invincible > 0
    end,


    set_immune = function(self, amount)
        if actor.invincible == false then actor.invincible = 0 end
        self.invincible = math.max(self.invincible, amount)
    end,


    remove_immune = function(self)
        self.invincible = 0
    end,


    kill = function(self)
        if self.hp then self.hp = -1000000.0 end
    end,


    item_give = function(self, item, count, temp)
        if type(item) == "table" then item = item.value end
        if not temp then temp = false end
        gm.item_give(self.value, item, count or 1, temp)
    end,


    item_remove = function(self, item, count, temp)
        if type(item) == "table" then item = item.value end
        if not temp then temp = false end
        gm.item_take(self.value, item, count or 1, temp)
    end,


    item_stack_count = function(self, item, item_type)
        if type(item) == "table" then item = item.value end
        if item_type == Item.TYPE.real then return gm.item_count(self.value, item, false) end
        if item_type == Item.TYPE.temporary then return gm.item_count(self.value, item, true) end
        return gm.item_count(self.value, item, false) + gm.item_count(self.value, item, true)
    end,


    buff_apply = function(self, buff, duration, count)
        if type(buff) == "table" then buff = buff.value end
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

        gm.apply_buff(self.value, buff, duration, count or 1)

        -- Clamp to max stack or under
        -- Funny stuff happens if this is exceeded
        local buff_array = Buff.wrap(buff)
        self.buff_stack:set(buff, math.min(self:buff_stack_count(buff), buff_array.max_stack))
    end,


    buff_remove = function(self, buff, count)
        if type(buff) == "table" then buff = buff.value end
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

        local stack_count = self:buff_stack_count(buff)
        if (not count) or count >= stack_count then gm.remove_buff(self.value, buff)
        else self.buff_stack:set(buff, stack_count - count)
        end
    end,


    buff_stack_count = function(self, buff)
        if type(buff) == "table" then buff = buff.value end
        if self.buff_stack:size() <= buff then self.buff_stack:resize(buff + 1) end

        local count = self.buff_stack:get(buff)
        if count == nil then return 0 end
        return count
    end,


    get_skill = function(self, slot)
        return Skill.wrap(self.skills:get(slot).active_skill.skill_id)
    end

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



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local actor = Instance.wrap(self)

    if callbacks["onSkillUse"] then
        for id, skill in pairs(callbacks["onSkillUse"]) do
            if gm.array_get(self.skills, args[1].value).active_skill.skill_id == id then
                for _, fn in pairs(skill) do
                    fn(actor)   -- Actor
                end
            end
        end
    end

    if args[1].value ~= 0.0 or gm.array_get(self.skills, 0).active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for _, fn in pairs(callbacks["onBasicUse"]) do
            fn(actor)   -- Actor
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for _, fn in pairs(callbacks["onHeal"]) do
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
        for _, fn in pairs(callbacks["onDraw"]) do
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


local function actor_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not args[2].value.parent then return end
    if callbacks["onPostAttack"] then
        for _, fn in ipairs(callbacks["onPostAttack"]) do
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
    Callback.add("onAttackHandleEnd", "RMT.actor_onPostAttack", actor_onPostAttack, true)
    Callback.add("onHitProc", "RMT.actor_onHit", actor_onHit, true)
    Callback.add("onKillProc", "RMT.actor_onKill", actor_onKill, true)
    Callback.add("onDamagedProc", "RMT.actor_onDamaged", actor_onDamaged, true)
    Callback.add("onDamageBlocked", "RMT.actor_onDamageBlocked", actor_onDamageBlocked, true)
    Callback.add("onInteractableActivate", "RMT.actor_onInteract", actor_onInteract, true)
    Callback.add("onEquipmentUse", "RMT.actor_onEquipmentUse", actor_onEquipmentUse, true)
end