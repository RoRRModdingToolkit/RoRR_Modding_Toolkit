-- Interactable Object

Interactable_Object = Proxy.new()

local callbacks = {}



-- ========== Enums ==========

Interactable_Object.COST_TYPE = Proxy.new({
    gold        = 0,
    hp          = 1,
    percent_hp  = 2
}):lock()



-- ========== Instance Methods ==========

methods_interactable_object = {

    clear_callbacks = function(self)
        self:clear_callbacks_obj_actual()
        callbacks["onCheckCost"][self.value] = nil
    end,


    -- Callbacks
    onCheckCost = function(self, func)
        local callback = "onCheckCost"
        if not callbacks[callback] then callbacks[callback] = {} end
        if not callbacks[callback][self.value] then callbacks[callback][self.value] = {} end
        table.insert(callbacks[callback][self.value], func)
    end

}
lock_table_interactable_object = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_interactable_object))})



-- ========== Metatables ==========

metatable_interactable_object = {
    __index = function(table, key)
        -- Methods
        if methods_interactable_object[key] then
            return methods_interactable_object[key]
        end

        -- Pass to next metatable
        return metatable_object.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_object_gs.__newindex(table, key, value)
    end,


    __metatable = "Interactable_Object"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.interactable_check_cost, function(self, other, result, args)
    if callbacks["onCheckCost"] and callbacks["onCheckCost"][self.__object_index] then
        for _, fn in pairs(callbacks["onCheckCost"][self.__object_index]) do
            local new = fn(Instance.wrap(self), Instance.wrap(args[3].value), args[2].value, args[1].value, result.value)   -- 3, 4 : cost, cost_type
            if type(new) == "boolean" then result.value = new end
        end
    end
end)



return Interactable_Object