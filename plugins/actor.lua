-- Actor

Actor = {}

local callbacks = {}



-- ========== Functions ==========

-- TODO: Check if all of the below are net synced by the game already

Actor.fire_bullet = function(actor, x, y, direction, range, damage, pierce_multiplier, hit_sprite)
    local damager = actor:fire_bullet(0, x, y, (pierce_multiplier and 1) or 0, damage, range, hit_sprite or -1, direction, 1.0, 1.0, -1.0)
    if pierce_multiplier then damager.damage_degrade = (1.0 - pierce_multiplier) end
    return damager
end


Actor.fire_explosion = function(actor, x, y, x_radius, y_radius, damage, stun, hit_sprite)
    local damager = actor:fire_explosion(0, x, y, damage, hit_sprite or -1, 2, -1, x_radius / 32.0, y_radius / 8.0)
    if stun then damager.stun = stun end
    return damager
end


Actor.damage = function(actor, source, damage, x, y, color, crit_sfx)
    if not crit_sfx then crit_sfx = false end
    gm.damage_inflict(actor, damage, 0.0, source, x, y, 0.0, 1.0, color or 16777215.0, crit_sfx)
end


Actor.heal = function(actor, amount)
    gm.actor_heal_networked(actor, amount, false)

    -- Health bar flash (if this client's player is healed)
    if actor == Player.get_client() then
        local hud = Instance.find(gm.constants.oHUD)
        if hud then
            for i, v in ipairs(hud.player_hud_display_info) do
                if gm.is_struct(v) then v.heal_flash = 0.5 end
            end
        end
    end
end


Actor.add_barrier = function(actor, amount)
    gm.actor_heal_barrier(actor, amount)
end


Actor.set_barrier = function(actor, amount)
    if actor.barrier <= 0 then Actor.add_barrier(actor, 1) end
    actor.barrier = amount
end


Actor.find_skill_id = function(namespace, identifier)
    local class_skill = gm.variable_global_get("class_skill")

    if identifier then namespace = namespace.."-"..identifier end

    for i, s in ipairs(class_skill) do
        if namespace == s[1].."-"..s[2] then return i - 1 end
    end

    return nil
end


Actor.add_callback = function(callback, func, skill_id)
    if callback == "onSkillUse" then
        if not callbacks["onSkillUse"] then callbacks["onSkillUse"] = {} end
        if not callbacks["onSkillUse"][skill_id] then callbacks["onSkillUse"][skill_id] = {} end
        table.insert(callbacks["onSkillUse"][skill_id], func)

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



-- ========== Internal ==========

function actor_onAttack(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks["onAttack"] then
        for _, fn in ipairs(callbacks["onAttack"]) do
            fn(self, args[2].value)    -- Actor, Damager attack_info
        end
    end
end


function actor_onPostAttack(self, other, result, args)
    if not args[2].value.proc or not args[2].value.parent then return end
    if callbacks["onPostAttack"] then
        for _, fn in ipairs(callbacks["onPostAttack"]) do
            fn(args[2].value.parent, args[2].value)    -- Actor, Damager attack_info
        end
    end
end


function actor_onHit(self, other, result, args)
    if not self.attack_info.proc then return end
    if callbacks["onHit"] then
        for _, fn in ipairs(callbacks["onHit"]) do
            fn(args[2].value, args[3].value, self.attack_info) -- Attacker, Victim, Damager attack_info
        end
    end
end


function actor_onKill(self, other, result, args)
    if callbacks["onKill"] then
        for _, fn in ipairs(callbacks["onKill"]) do
            fn(args[3].value, args[2].value)   -- Attacker, Victim
        end
    end
end


function actor_onDamaged(self, other, result, args)
    if callbacks["onDamaged"] then
        for _, fn in ipairs(callbacks["onDamaged"]) do
            fn(args[2].value, args[3].value.attack_info)   -- Actor, Damager attack_info
        end
    end
end


function actor_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for _, fn in ipairs(callbacks["onDamageBlocked"]) do
            fn(self, other.attack_info)   -- Actor, Damager attack_info
        end
    end
end


function actor_onInteract(self, other, result, args)
    if callbacks["onInteract"] then
        for _, fn in ipairs(callbacks["onInteract"]) do
            fn(args[3].value, args[2].value)   -- Actor, Interactable
        end
    end
end


function actor_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for _, fn in ipairs(callbacks["onEquipmentUse"]) do
            fn(args[2].value, args[3].value)   -- Actor, Equipment ID
        end
    end
end


Actor.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if callbacks["onSkillUse"] then
        for id, skill in pairs(callbacks["onSkillUse"]) do
            if self.skills[args[1].value + 1].active_skill.skill_id == id then
                for _, fn in pairs(skill) do
                    fn(self)   -- Actor
                end
            end
        end
    end

    if args[1].value ~= 0.0 or self.skills[1].active_skill.skill_id == 70.0 then return true end
    if callbacks["onBasicUse"] then
        for _, fn in pairs(callbacks["onBasicUse"]) do
            fn(self)   -- Actor
        end
    end
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    if callbacks["onHeal"] then
        for _, fn in pairs(callbacks["onHeal"]) do
            fn(args[1].value, args[2].value)   -- Actor, Heal amount
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPreStep"] then
        for _, fn in pairs(callbacks["onPreStep"]) do
            fn(self)   -- Actor
        end
    end

    if self.shield and self.shield > 0.0 then self.RMT_has_shield_actor = true end
    if self.RMT_has_shield_actor and self.shield <= 0.0 then
        self.RMT_has_shield_actor = nil
        if callbacks["onShieldBreak"] then
            for _, fn in pairs(callbacks["onShieldBreak"]) do
                fn(self)   -- Actor
            end
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if callbacks["onPostStep"] then
        for _, fn in pairs(callbacks["onPostStep"]) do
            fn(self)   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if callbacks["onDraw"] then
        for _, fn in pairs(callbacks["onDraw"]) do
            fn(self)   -- Actor
        end
    end
end)



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