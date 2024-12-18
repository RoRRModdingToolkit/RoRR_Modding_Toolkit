-- Net

Net = Proxy.new()



-- ========== Enums ==========

Net.TYPE = Proxy.new({
    -- Only one may be true at a time
    single      = 0,
    host        = 1,
    client      = 2
}):lock()



-- ========== Static Methods ==========

Net.get_type = function()
    if not gm._mod_net_isOnline()   then return Net.TYPE.single end
    if gm._mod_net_isHost()         then return Net.TYPE.host   end
    return Net.TYPE.client
end

Net.is_single   = function() return Net.get_type() == Net.TYPE.single   end
Net.is_host     = function() return Net.get_type() == Net.TYPE.host     end
Net.is_client   = function() return Net.get_type() == Net.TYPE.client   end



return Net