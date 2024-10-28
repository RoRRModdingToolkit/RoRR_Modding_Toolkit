-- Net

Net = Proxy.new()



-- ========== Enums ==========

Net.TYPE = Proxy.new({
    single      = 0,
    host        = 1,
    client      = 2
}):lock()



-- ========== Static Methods ==========

Net.get_type = function()
    local oPrePlayer = Instance.find(gm.constants.oPrePlayer)
    if oPrePlayer:exists() then
        if oPrePlayer.m_id == 1.0 then return Net.TYPE.host
        elseif oPrePlayer.m_id > 1.0 then return Net.TYPE.client
        end
    end

    local p = Player.get_client()
    if p:exists() then
        if p.m_id == 1.0 then return Net.TYPE.host
        elseif p.m_id > 1.0 then return Net.TYPE.client
        end
    end

    return Net.TYPE.single
end



return Net