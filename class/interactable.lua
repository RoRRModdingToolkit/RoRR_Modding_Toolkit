-- Interactable

Interactable = Proxy.new()



-- ========== Instance Methods ==========

methods_interactable = {

    set_active = function(self, active, activator, is_hack, hack_double)
        GM.interactable_set_active(self, activator or self.activator, active or 0, is_hack or false, hack_double or false)
    end

}



-- ========== Metatables ==========

metatable_interactable = {
    __index = function(table, key)
        -- Methods
        if methods_interactable[key] then
            return methods_interactable[key]
        end

        -- Pass to next metatable
        return metatable_instance.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end,


    __metatable = "Interactable"
}



return Interactable