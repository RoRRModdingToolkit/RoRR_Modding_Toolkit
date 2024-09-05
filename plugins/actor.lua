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


    damage = function(self, damage, source, x, y, color, crit_sfx)
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
        if type(item) == "table" then item = item.value end
        if type_ == Item.TYPE.real then return gm.item_count(self.value, item, false) end
        if type_ == Item.TYPE.temporary then return gm.item_count(self.value, item, true) end
        return gm.item_count(self.value, item, false) + gm.item_count(self.value, item, true)
    end,


    buff_apply = function(self, buff, duration, count)
        if type(buff) == "table" then buff = buff.value end
        if gm.array_length(self.buff_stack) <= buff then gm.array_resize(self.buff_stack, buff + 1) end

        gm.apply_buff(self.value, buff, duration, count or 1)

        -- Clamp to max stack or under
        -- Funny stuff happens if this is exceeded
        local buff_array = gm.array_get(Class.BUFF, buff)
        local max_stack = gm.array_get(buff_array, 9)
        gm.array_set(self.buff_stack, buff, math.min(self:buff_stack(buff), max_stack))
    end,


    buff_remove = function(self, buff, count)
        if type(buff) == "table" then buff = buff.value end
        if gm.array_length(self.buff_stack) <= buff then gm.array_resize(self.buff_stack, buff + 1) end

        local stack_count = self:buff_stack(buff)
        if (not count) or count >= stack_count then gm.remove_buff(self.value, buff)
        else gm.array_set(self.buff_stack, buff, stack_count - count)
        end
    end,


    buff_stack = function(self, buff)
        if type(buff) == "table" then buff = buff.value end
        if gm.array_length(self.buff_stack) <= buff then gm.array_resize(self.buff_stack, buff + 1) end

        local count = gm.array_get(self.buff_stack, buff)
        if count == nil then return 0 end
        return count
    end,


    get_skill = function(self, slot)
        local abstraction = {
            value = gm.array_get(self.skills, slot).active_skill.skill_id
        }
        setmetatable(abstraction, metatable_skill)
        return abstraction
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