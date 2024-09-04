-- Actor

Actor = {}



-- ========== Instance Methods ==========

Actor.make_metatable = function(inst)
    return {
        __index = setmetatable({

            value = inst,


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
                        for i, v in ipairs(hud.player_hud_display_info) do
                            if gm.is_struct(v) then v.heal_flash = 0.5 end
                        end
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


            item_give = function(self, item, count)

            end,


            item_remove = function(self, item, count)
                
            end,


            item_stack_count = function(self, item, type)
                
            end,


            buff_apply = function(self, buff, duration, count)

            end,


            buff_remove = function(self, buff, count)
                
            end,


            buff_stack_count = function(self, buff)
                
            end

        },
        Instance.make_metatable(inst)),


        -- Setter
        __newindex = function(table, key, value)
            local var = rawget(table, "value")
            if var then gm.variable_instance_set(var, key, value) end
        end
    }
end