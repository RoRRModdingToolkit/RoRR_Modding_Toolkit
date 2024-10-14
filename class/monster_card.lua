-- Monster Card

Monster_Card = class_refs["Monster_Card"]



-- ========== Static Methods ==========

Monster_Card.new = function(namespace, identifier)
    local card = Monster_Card.find(namespace, identifier)
    if card then return card end

    local mc = Monster_Card.wrap(
        gm.monster_card_create(namespace, identifier)
    )

    class_find_repopulate("Monster_Card")
    return mc
end



-- ========== Instance Methods ==========

methods_monster_card = {

    

}
class_lock_tables["Monster_Card"] = Proxy.make_lock_table({"value", "RMT_object", table.unpack(methods_monster_card)})



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


    __metatable = "monster_card"
}



return Monster_Card