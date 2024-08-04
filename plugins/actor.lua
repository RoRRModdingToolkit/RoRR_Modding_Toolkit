-- Actor

Actor = {}



-- ========== Functions ==========

Actor.fire_bullet = function(actor, x, y, direction, range, damage, pierce_multiplier, hit_sprite)
    local damager = actor:fire_bullet(0, x, y, (pierce_multiplier and 1) or 0, damage, range, hit_sprite or -1, direction, 1.0, 1.0, -1.0)
    if pierce_multiplier then damager.damage_degrade = (1.0 - pierce_multiplier) end
    return damager
end


Actor.fire_explosion = function()
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