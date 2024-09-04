-- Actor

Actor = {}



-- ========== Instance Methods ==========

methods_actor = {

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


    damage = function(self, source, damage, x, y, color, crit_sfx)
        local source_inst = nil
        if source then
            if type(source) == "table" then source = source.value end
            source_inst = source
        end
        if not crit_sfx then crit_sfx = false end
        gm.damage_inflict(self.value, damage, 0.0, source_inst, x, y, damage, 1.0, color or 16777215.0, crit_sfx)
    end,


    heal = function(self, amount)
        gm.actor_heal_networked(self.value, amount, false)
    
        -- Health bar flash (if this client's player is healed)
        if self:same(Player.get_client()) then
            local hud = Instance.find(gm.constants.oHUD)
            if hud:exists() then
                gm.array_get(hud.player_hud_display_info, 0).heal_flash = 0.5
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


    kill = function(self)
        if self.hp then self.hp = -1000000.0 end
    end,


    activate_equipment = function(self)

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


    item_stack = function(self, item, item_type)
        if type_ == Item.TYPE.real then return gm.item_count(self.value, item, false) end
        if type_ == Item.TYPE.temporary then return gm.item_count(self.value, item, true) end
        return gm.item_count(self.value, item, false) + gm.item_count(self.value, item, true)
    end,


    buff_apply = function(self, buff, duration, count)

    end,


    buff_remove = function(self, buff, count)
        
    end,


    buff_stack = function(self, buff)
        
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