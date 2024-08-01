-- Player
-- Originally in HelperFunctions by Klehrik, with edits by SmoothSpatula

Player = {}



-- ========== Functions ==========

Player.get_client = function()
    local players = Instance.find_all(gm.constants.oP)

    -- Return the first player if there is only one player
    if #players == 1 then return players[1] end

    -- Loop through players and return the one that "is_local"
    for _, p in ipairs(players) do
        if p.is_local then return p end
    end

    return nil
end


Player.get_host = function()
    -- Return the player that has an m_id of 1.0
    local players = Instance.find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.m_id == 1.0 then return p end
    end
    return nil
end


Player.get_from_name = function(name)
    local players = Instance.find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.user_name == name then return p end
    end
    return nil
end