-- Interactable Card

Interactable_Card = class_refs["Interactable_Card"]



-- ========== Static Methods ==========

Interactable_Card.new = function(namespace, identifier)
    local card = Interactable_Card.find(namespace, identifier)
    if card then return card end

    return Interactable_Card.wrap(gm.interactable_card_create(namespace, identifier))
end



-- ========== Instance Methods ==========

methods_interactable_card = {



}



-- ========== Metatables ==========

metatable_class["Interactable_Card"] = {
    __index = function(table, key)
        -- Methods
        if methods_interactable_card[key] then
            return methods_interactable_card[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Interactable_Card"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Interactable_Card"].__newindex(table, key, value)
    end,


    __metatable = "interactable_card"
}



return Interactable_Card