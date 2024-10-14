-- Gamemode

Gamemode = class_refs["Gamemode"]



-- ========== Static Methods ==========

Gamemode.new = function(namespace, identifier, count_normal_unlocks, count_towards_games_played)
    local gamemode = Gamemode.find(namespace, identifier)
    if gamemode then return gamemode end

    if type(count_normal_unlocks) ~= "boolean" or type(count_normal_unlocks) ~= "nil" then log.error("Count Normal Unlocks toggle is not a boolean, got a "..type(count_normal_unlocks), 2) return end
    if type(count_towards_games_played) ~= "boolean" or type(count_towards_games_played) ~= "nil" then log.error("Count Towards Games Played toggle is not a boolean, got a "..type(count_towards_games_played), 2) return end

    local gamemode = Gamemode.wrap(
        gm.gamemode_create(
            namespace,                              -- Namespace
            identifier,                             -- Identifier
            count_normal_unlocks or true,           -- Count Normal Unlocks
            count_towards_games_played or true      -- Count Towards Games Played
        )
    )

    class_find_repopulate("Gamemode")
    return gamemode
end



-- ========== Instance Methods ==========

methods_gamemode = {



}
class_lock_tables["Gamemode"] = Proxy.make_lock_table({"value", "RMT_object", table.unpack(methods_gamemode)})



-- ========== Metatables ==========

metatable_class["Gamemode"] = {
    __index = function(table, key)
        -- Methods
        if methods_gamemode[key] then
            return methods_gamemode[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Gamemode"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Gamemode"].__newindex(table, key, value)
    end,


    __metatable = "gamemode"
}



return Gamemode