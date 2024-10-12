-- Ending

Ending = class_refs["Ending"]



-- ========== Static Methods ==========

Ending.new = function(namespace, identifier)
    local ending = Ending.find(namespace, identifier)
    if ending then return ending end

    return Ending.wrap(gm.ending_create(namespace, identifier))
end



-- ========== Instance Methods ==========

methods_ending = {
    set_primary_color = function(self, R, G, B)
        self.primary_color = Color.from_rgb(R, G, B)
    end,


    is_victory = function(self, is_victory)
        if type(is_victory) ~= "boolean" then log.error("Victory is not a boolean, got a "..type(is_victory), 2) return end
        
        self.is_victory = is_victory
    end,
}
methods_class_lock["Ending"] = Helper.table_get_keys(methods_ending)



-- ========== Metatables ==========

metatable_class["Ending"] = {
    __index = function(table, key)
        -- Methods
        if methods_ending[key] then
            return methods_ending[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Ending"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Ending"].__newindex(table, key, value)
    end,


    __metatable = "ending"
}



return Ending