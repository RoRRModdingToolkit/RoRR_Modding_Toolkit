-- Interactable

Interactable = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

Interactable.new = function(namespace, identifier)
    if Object.find(namespace, identifier) then return nil end

    local obj = gm.object_add_w(namespace, identifier, gm.constants.pInteractable)
    return Interactable.wrap(obj)
end


Interactable.wrap = function(object_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Interactable",
        value = object_id
    }
    setmetatable(abstraction, metatable_interactable)
    return abstraction
end



-- ========== Instance Methods ==========

methods_interactable = {

    

}



-- ========== Metatables ==========

metatable_interactable = {
    __index = function(table, key)
        -- Methods
        if methods_interactable[key] then
            return methods_interactable[key]
        end

        -- Pass to next metatable
        return metatable_object.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_object_gs.__newindex(table, key, value)
    end
}