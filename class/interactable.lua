-- Interactable

Interactable = Proxy.new()



-- ========== Instance Methods ==========

methods_interactable = {

    set_active = function(self, active, activator, arg3, arg4)  -- check what those args are again
        GM.interactable_set_active(self, activator or self.activator, active or 0, arg3 or false, arg4 or false)
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