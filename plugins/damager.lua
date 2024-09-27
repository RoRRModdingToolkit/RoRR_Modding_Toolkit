-- Damager

Damager = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

Damager.wrap = function(damager)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Damager",
        value = damager
    }
    setmetatable(abstraction, metatable_damager)
    return abstraction
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


    allow_stun = function(self, bool)
        if bool == nil then
            log.error("allow_stun needs a boolean value", 2)
            return
        end

        self.value.allow_stun = bool
    end,


    get_stun = function(self)
        return self.value.stun * 1.5
    end,


    set_stun = function(self, seconds)
        if not seconds then
            log.error("No stun duration provided", 2)
            return
        end

        self:allow_stun(true)
        self.value.stun = seconds / 1.5
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
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_damager[key] then
            return methods_damager[key]
        end

        -- Pass to next metatable
        return metatable_damager_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_damager_gs.__newindex(table, key, value)
    end
}