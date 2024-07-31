-- Helper

Helper = {}



-- ========== Enums ==========

Helper.NET = {
    single      = 0,
    host        = 1,
    client      = 2
}


Helper.TIER = {
    common      = 0,
    uncommon    = 1,
    rare        = 2,
    equipment   = 3,
    boss        = 4,
    special     = 5,
    food        = 6,
    notier      = 7
}



-- ========== Functions ==========

Helper.instance_exists = function(inst)
    return gm.instance_exists(inst) == 1.0
end


Helper.instance_find = function(index)
    local inst = gm.instance_find(index, 0)
    if not Helper.instance_exists(inst) then return nil end
    return inst
end


Helper.instance_find_all = function(index)
    local insts = {}
    for i = 0, gm.instance_number(index) - 1 do
        table.insert(insts, gm.instance_find(index, i))
    end
    return insts, #insts > 0
end


Helper.get_client_player = function()
    -- Get oInit m_id
    local m_id = -1.0
    local oInit = Helper.instance_find(gm.constants.oInit)
    if oInit then m_id = oInit.m_id end

    local players = Helper.instance_find_all(gm.constants.oP)

    -- Return the first player if there is only one player
    if #players == 1 then return players[1] end

    -- Loop through players and return the one with the same m_id
    for _, p in ipairs(players) do
        if p.m_id == oInit.m_id then return p end
    end

    return nil
end


Helper.get_host_player = function()
    -- Return the player that has an m_id of 1.0
    local players = Helper.instance_find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.m_id == 1.0 then return p end
    end
    return nil
end


Helper.get_net_status = function()
    local oInit = Helper.instance_find(gm.constants.oInit)
    if oInit then
        if oInit.m_id > 1.0 then return Helper.NET.client
        else return oInit.m_id
        end
    end
    return Helper.NET.single
end