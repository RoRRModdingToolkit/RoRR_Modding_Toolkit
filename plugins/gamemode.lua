-- Gamemode

Gamemode = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Enums ==========

Gamemode.ARRAY = {
    namespace                       = 0,
    identifier                      = 1,
    count_normal_unlocks            = 2,
    count_towards_games_played      = 3
}



-- ========== Static Methods ==========

Gamemode.new = function(namespace, identifier, count_normal_unlocks, count_towards_games_played)
    local gamemode = Gamemode.find(namespace, identifier)
    if gamemode then return gamemode end

    if type(count_normal_unlocks) ~= "boolean" or type(count_normal_unlocks) ~= "nil" then log.error("Count Normal Unlocks toggle is not a boolean, got a "..type(count_normal_unlocks), 2) return end
    if type(count_towards_games_played) ~= "boolean" or type(count_towards_games_played) ~= "nil" then log.error("Count Towards Games Played toggle is not a boolean, got a "..type(count_towards_games_played), 2) return end

    return Gamemode.wrap(gm.gamemode_create(namespace, identifier, count_normal_unlocks or true, count_towards_games_played or true))
end


Gamemode.find = function(namespace, identifier)
    local id_string = namespace
    
    if identifier then id_string = namespace.."-"..identifier end
    
    local gamemode_id = gm.gamemode_find(id_string)

    if not gamemode_id then return nil end

    return Gamemode.wrap(gamemode_id)
end


Gamemode.wrap = function(gamemode_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Gamemode",
        value = gamemode_id
    }
    setmetatable(abstraction, metatable_gamemode)
    return abstraction
end


-- ========== Instance Methods ==========

methods_gamemode = {

}

-- ========== Metatables ==========

metatable_gamemode_gs = {
    -- Getter
    __index = function(table, key)
        local index = Gamemode.ARRAY[key]
        if index then
            local array = Class.GAMEMODE:get(table.value)
            return array:get(index)
        end
        log.error("Non-existent gamemode property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Gamemode.ARRAY[key]
        if index then
            local array = Class.GAMEMODE:get(table.value)
            array:set(index, value)
            return
        end
        log.error("Non-existent gamemode property", 2)
    end
}


metatable_gamemode = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        -- if methods_gamemode[key] then
        --     return methods_gamemode[key]
        -- end

        -- Pass to next metatable
        return metatable_gamemode_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_gamemode_gs.__newindex(table, key, value)
    end
}