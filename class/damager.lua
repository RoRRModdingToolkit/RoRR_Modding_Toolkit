-- Damager

Damager = Proxy.new()



-- ========== Enums ==========

Damager.KNOCKBACK_KIND = Proxy.new({
    none        = 0,
    standard    = 1,
    freeze      = 2,
    deepfreeze  = 3,
    pull        = 4
}):lock()


Damager.KNOCKBACK_DIR = Proxy.new({
    left    = -1,
    right   = 1
}):lock()


Damager.TRACER = Proxy.new({
    none                    = 0,
    wispg                   = 1,
    wispg2                  = 2,
    pilot_raid              = 3,
    pilot_raid_boosted      = 4,
    pilot_primary           = 5,
    pilot_primary_strong    = 6,
    pilot_primary_alt       = 7,
    commando1               = 8,
    commando2               = 9,
    commando3               = 10,
    commando3_r             = 11,
    sniper1                 = 12,
    sniper2                 = 13,
    engi_turret             = 14,
    enforcer1               = 15,
    robomando1              = 16,
    robomando2              = 17,
    bandit1                 = 18,
    bandit2                 = 19,
    bandit2_r               = 20,
    bandit3                 = 21,
    bandit3_r               = 22,
    acrid                   = 23,
    no_sparks_on_miss       = 24,
    end_sparks_on_pierce    = 25,
    drill                   = 26,
    player_drone            = 27
}):lock()


Damager.ATTACK_FLAG = Proxy.new({
    cd_reset_on_kill            = (1 << 0),
    inflict_poison_dot          = (1 << 1),
    chef_ignite                 = (1 << 2),
    stun_proc_ef                = (1 << 3),
    knockback_proc_ef           = (1 << 4), 
    spawn_lightning             = (1 << 5),
    sniper_bonus_60             = (1 << 6),
    sniper_bonus_30             = (1 << 7),
    hand_steam_1                = (1 << 8),
    hand_steam_5                = (1 << 9),
    drifter_scrap_bit1          = (1 << 10),
    drifter_scrap_bit2          = (1 << 11),
    drifter_execute             = (1 << 12),
    miner_heat                  = (1 << 13),
    commando_wound              = (1 << 14),
    commando_wound_damage       = (1 << 15),
    gain_skull_on_kill          = (1 << 16),
    gain_skull_boosted          = (1 << 17),
    chef_freeze                 = (1 << 18),
    chef_bigfreeze              = (1 << 19),
    chef_food                   = (1 << 20),
    inflict_armor_strip         = (1 << 21),
    inflict_flame_dot           = (1 << 22),
    merc_afterimage_nodamage    = (1 << 23),
    pilot_raid                  = (1 << 24),
    pilot_raid_boosted          = (1 << 25),
    pilot_mine                  = (1 << 26),
    inflict_arti_flame_dot      = (1 << 27),
    sawmerang                   = (1 << 28),
    force_proc                  = (1 << 29)
}):lock()



-- ========== Static Methods ==========

Damager.wrap = function(value)
    return make_wrapper(value, "Damager", metatable_damager, lock_table_damager)
end



-- ========== Instance Methods ==========

methods_damager = {

    use_raw_damage = function(self)
        if not self.parent:exists() then
            log.error("damager does not have a parent", 2)
            return
        end

        self.value.damage = self.value.damage / self.value.parent.damage
    end,


    add_offset = function(self, damager, offset)
        damager = Wrap.unwrap(damager)

        -- Overload 1
        if type(damager) == "number" then
            self.value.climb = self.value.climb + damager
            return
        end

        -- Overload 2
        if not gm.is_struct(damager) then log.error("Argument 1 is not a struct", 2) end
        self.value.climb = damager.climb + (offset or 10.0)
    end,


    set_color = function(self, col)
        self.value.damage_color = col
    end,
    set_colour = function(self, col) self:set_color(col) end,


    set_critical = function(self, bool)
        if bool == nil then
            log.error("set_critical needs a boolean value", 2)
            return
        end
        
        if (not self.critical) and bool then
            self.value.critical = true
            self.value.damage = self.value.damage * 2.0
        elseif self.critical and (not bool) then
            self.value.critical = false
            self.value.damage = self.value.damage / 2.0
        end
    end,


    set_proc = function(self, bool)
        if bool == nil then
            log.error("set_proc needs a boolean value", 2)
            return
        end

        self.value.proc = bool
    end,


    allow_stun = function(self)
        self.value.RMT_allow_stun = true
    end,


    get_stun = function(self)
        return self.value.stun * 1.5
    end,


    set_stun = function(self, seconds, knockback_dir, knockback_kind)
        if not seconds then
            log.error("No stun duration provided", 2)
            return
        end

        self:allow_stun()
        self.value.stun = seconds / 1.5

        if knockback_dir then self.knockback_direction = knockback_dir end
        if knockback_kind then self.knockback_kind = knockback_kind end
    end,


    set_attack_flags = function(self, flags, state)
        if type(flags) ~= "table" then flags = table.pack(flags) end
        if state == nil then log.error("state argument not provided", 2) end

        for _, flag in ipairs(flags) do
            if (self.value.attack_flags & flag) <= 0 and state then
                self.value.attack_flags = self.value.attack_flags + flag
            end
            if (self.value.attack_flags & flag) > 0 and (not state) then
                self.value.attack_flags = self.value.attack_flags - flag
            end
        end
    end

}
lock_table_damager = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_damager))})



-- ========== Metatables ==========

metatable_damager_gs = {
    -- Getter
    __index = function(table, key)
        if gm.variable_struct_exists(table.value, key) then
            return Wrap.wrap(gm.variable_struct_get(table.value, key))
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        gm.variable_struct_set(table.value, key, Wrap.unwrap(value))
    end
}


metatable_damager = {
    __index = function(table, key)
        -- Methods
        if methods_damager[key] then
            return methods_damager[key]
        end

        -- Pass to next metatable
        return metatable_damager_gs.__index(table, key)
    end,


    __newindex = function(table, key, value) 
        metatable_damager_gs.__newindex(table, key, value)
    end,


    __metatable = "damager"
}



return Damager