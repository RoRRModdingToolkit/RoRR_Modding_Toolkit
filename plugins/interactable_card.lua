-- Interactable Card

Interactable_Card = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Enums ==========

Interactable_Card.ARRAY = {
    namespace                       = 0,
    identifier                      = 1,
    spawn_cost                      = 2,
    spawn_weight                    = 3,
    object_id                       = 4,
    required_tile_space             = 5,
    spawn_with_sacrifice            = 6,
    is_new_interactable             = 7,
    default_spawn_rarity_override   = 8,
    decrease_weight_on_spawn        = 9
}



-- ========== Static Methods ==========

Interactable_Card.new = function(namespace, identifier)
    local card = Interactable_Card.find(namespace, identifier)
    if card then return card end

    return Interactable_Card.wrap(gm.interactable_card_create(namespace, identifier))
end


Interactable_Card.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    -- The built-in gm.interactable_card_find does not accept a namespace for some reason
    for i, card in ipairs(Class.INTERACTABLE_CARD) do
        local _namespace = card:get(0)
        local _identifier = card:get(1)
        if namespace == _namespace.."-".._identifier then
            return Interactable_Card.wrap(i - 1)
        end
    end

    return nil
end


Interactable_Card.wrap = function(interactable_card_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Interactable_Card",
        value = interactable_card_id
    }
    setmetatable(abstraction, metatable_interactable_card)
    return abstraction
end



-- ========== Metatables ==========

metatable_interactable_card_gs = {
    -- Getter
    __index = function(table, key)
        local index = Interactable_Card.ARRAY[key]
        if index then
            local array = Class.INTERACTABLE_CARD:get(table.value)
            return array:get(index)
        end
        log.error("Non-existent interactable card property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Interactable_Card.ARRAY[key]
        if index then
            local array = Class.INTERACTABLE_CARD:get(table.value)
            array:set(index, value)
            return
        end
        log.error("Non-existent interactable card property", 2)
    end
}


metatable_interactable_card = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        -- if methods_interactable_card[key] then
        --     return methods_interactable_card[key]
        -- end

        -- Pass to next metatable
        return metatable_interactable_card_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_interactable_card_gs.__newindex(table, key, value)
    end
}