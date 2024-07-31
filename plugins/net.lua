-- Net

Net = {}



-- ========== Enums ==========

Net.TYPE = {
    single      = 0,
    host        = 1,
    client      = 2
}



-- ========== Functions ==========

Net.get_type = function()
    local oInit = Helper.instance_find(gm.constants.oInit)
    if oInit then
        if oInit.m_id == 1.0 then return Net.TYPE.host
        elseif oInit.m_id > 1.0 then return Net.TYPE.client
        end
    end
    return Net.TYPE.single
end