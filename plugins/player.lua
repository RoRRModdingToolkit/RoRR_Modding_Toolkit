-- Player

Player = {}



-- ========== Enums ==========





-- ========== Functions ==========

Player.get_client = function()
    -- Get oInit m_id
    local m_id = -1.0
    local oInit = Instance.find(gm.constants.oInit)
    if oInit then m_id = oInit.m_id end

    local players = Instance.find_all(gm.constants.oP)

    -- Return the first player if there is only one player
    if #players == 1 then return players[1] end

    -- Loop through players and return the one with the same m_id
    for _, p in ipairs(players) do
        if p.m_id == oInit.m_id then return p end
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