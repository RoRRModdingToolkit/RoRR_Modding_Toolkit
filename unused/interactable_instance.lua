-- Interactable Instance

Interactable_Instance = Proxy.new()



-- ========== Instance Methods ==========

methods_interactable_instance = {

    -- This will proc onInteractableActive again actually
    -- Perhaps it is not needed then
    set_active = function(self, active, activator, is_hack, hack_double)
        GM.interactable_set_active(self, activator or self.activator, active or 0, is_hack or false, hack_double or false)
    end

}



-- ========== Metatables ==========

metatable_interactable_instance = {
    __index = function(table, key)
        -- Methods
        if methods_interactable_instance[key] then
            return methods_interactable_instance[key]
        end

        -- Pass to next metatable
        return metatable_instance.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end,


    __metatable = "Interactable_Instance"
}



return Interactable_Instance