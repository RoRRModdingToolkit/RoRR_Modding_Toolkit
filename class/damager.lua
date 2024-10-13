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



-- ========== Static Methods ==========

Damager.wrap = function(value)
    local wrapper = Proxy.new()
    wrapper.RMT_object = "Damager"
    wrapper.value = value
    wrapper:setmetatable(metatable_damager)
    wrapper:lock(methods_damager_lock)
    return wrapper
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

}



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