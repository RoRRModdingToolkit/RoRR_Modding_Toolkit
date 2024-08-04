-- Actor

Actor = {}



-- ========== Functions ==========

Actor.fire_bullet = function(actor, x, y, direction, range, damage, pierce_multiplier, hit_sprite)
    local damager = actor:fire_bullet(0, x, y, (pierce_multiplier and 1) or 0, damage, range, hit_sprite or -1, direction, 1.0, 1.0, -1.0)
    damager.damage_degrade = (1.0 - pierce_multiplier)
    return damager
end


Actor.fire_explosion = function()
end


Actor.heal = function()
end