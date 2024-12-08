-- Hit_Info

Hit_Info = Proxy.new()



-- ========== Static Methods ==========

Hit_Info.wrap = function(value)
    if not value then return nil end
    return make_wrapper(value, metatable_hit_info, lock_table_hit_info)
end



-- ========== Instance Methods ==========

methods_hit_info = {

    use_raw_damage = function(self)
        if not self.inflictor:exists() then
            log.error("hit_info does not have an inflictor", 2)
            return
        end

        self:set_damage(self.value.damage / self.value.inflictor.damage)
    end,


    set_damage = function(self, damage)
        if not damage then log.error("No damage argument provided", 2) end

        -- set_damage before critical calculation
        local temp_crit_removal = false
        if Helper.is_true(self.critical) then
            temp_crit_removal = true
            self:set_critical(false)
        end

        local scale = damage / self.value.damage
        self.value.damage = self.value.damage * scale
        self.value.damage_true = self.value.damage_true * scale
        self.value.damage_fake = self.value.damage_fake * scale
        self.value.attack_info.damage = self.value.damage

        if temp_crit_removal then self:set_critical(true) end
    end,


    set_critical = function(self, bool)
        if bool == nil then log.error("No bool argument provided", 2) end
        
        if Helper.is_false(self.critical) and bool then
            self.value.critical = true
            self.value.damage = self.value.damage * 2.0
            self.value.damage_true = self.value.damage_true * 2.0
            self.value.damage_fake = self.value.damage_fake * 2.0
            self.value.attack_info.critical = true
            self.value.attack_info.damage = self.value.damage

        elseif Helper.is_true(self.critical) and (not bool) then
            self.value.critical = false
            self.value.damage = self.value.damage / 2.0
            self.value.damage_true = self.value.damage_true / 2.0
            self.value.damage_fake = self.value.damage_fake / 2.0
            self.value.attack_info.critical = false
            self.value.attack_info.damage = self.value.damage
        end
    end

}
lock_table_hit_info = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_hit_info))})



-- ========== Metatables ==========

metatable_hit_info = {
    __index = function(table, key)
        -- Methods
        if methods_hit_info[key] then
            return methods_hit_info[key]
        end

        -- Getter
        if gm.variable_struct_exists(table.value, key) then
            local val = gm.variable_struct_get(table.value, key)
            if key == "attack_info" then return Attack_Info.wrap(val) end
            return Wrap.wrap(val)
        end

        -- Pass to next metatable
        local ai = table.attack_info
        if not ai then return nil end
        return metatable_attack_info.__index(ai, key)
    end,


    __newindex = function(table, key, value)
        -- Setter
        gm.variable_struct_set(table.value, key, Wrap.unwrap(value))
    end,


    __metatable = "Hit_Info"
}



return Hit_Info