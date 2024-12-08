-- Monster Card

Monster_Card = class_refs["Monster_Card"]



-- ========== Enums ==========

Monster_Card.SPAWN_TYPE = Proxy.new({
    classic     = 0,
    nearby      = 1,
    offscreen   = 2,
    origin      = 3
}):lock()



-- ========== Static Methods ==========

Monster_Card.new = function(namespace, identifier)
    local card = Monster_Card.find(namespace, identifier)
    if card then return card end

    local mc = Monster_Card.wrap(
        gm.monster_card_create(namespace, identifier)
    )

    return mc
end



-- ========== Instance Methods ==========

methods_monster_card = {

    

}



-- ========== Metatables ==========

metatable_class["Monster_Card"] = {
    __index = function(table, key)
        -- Methods
        if methods_monster_card[key] then
            return methods_monster_card[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Monster_Card"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Monster_Card"].__newindex(table, key, value)
    end,


    __metatable = "Monster_Card"
}



return Monster_Card
