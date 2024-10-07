-- Monster Card

Monster_Card = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Enums ==========

Monster_Card.ARRAY = {
    namespace                       = 0,
    identifier                      = 1,
    spawn_type                      = 2,
    spawn_cost                      = 3,
    object_id                       = 4,
    is_boss                         = 5,
    is_new_enemy                    = 6,
    elite_list                      = 7,
    can_be_blighted                 = 8
}



-- ========== Static Methods ==========

Monster_Card.new = function(namespace, identifier)
    local card = Monster_Card.find(namespace, identifier)
    if card then return card end

    return Monster_Card.wrap(gm.monster_card_create(namespace, identifier))
end


Monster_Card.find = function(namespace, identifier)
    -- The built-in gm.monster_card_find does not accept a namespace for some reason
    
    if identifier then namespace = namespace.."-"..identifier end
    if not string.find(namespace, "-") then namespace = "ror-"..namespace end
    
    for i, card in ipairs(Class.MONSTER_CARD) do
        local _namespace = card:get(0)
        local _identifier = card:get(1)
        if namespace == _namespace.."-".._identifier then
            return Monster_Card.wrap(i - 1)
        end
    end

    return nil
end


Monster_Card.wrap = function(monster_card_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Monster_Card",
        value = monster_card_id
    }
    setmetatable(abstraction, metatable_monster_card)
    return abstraction
end



-- ========== Metatables ==========

metatable_monster_card_gs = {
    -- Getter
    __index = function(table, key)
        local index = Monster_Card.ARRAY[key]
        if index then
            local array = Class.MONSTER_CARD:get(table.value)
            return array:get(index)
        end
        log.error("Non-existent monster card property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Monster_Card.ARRAY[key]
        if index then
            local array = Class.MONSTER_CARD:get(table.value)
            array:set(index, value)
            return
        end
        log.error("Non-existent monster card property", 2)
    end
}


metatable_monster_card = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        -- if methods_monster_card[key] then
        --     return methods_monster_card[key]
        -- end

        -- Pass to next metatable
        return metatable_monster_card_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_monster_card_gs.__newindex(table, key, value)
    end
}