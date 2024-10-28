-- Packet

Packet = Proxy.new()

callbacks = {
    onReceived = {}
}



-- ========== Static Methods ==========

Packet.new = function()
    local id = GM._mod_net_message_getUniqueID()
    return Packet.wrap(id)
end


Packet.wrap = function(value)
    return make_wrapper(value, "Packet", metatable_packet, lock_table_packet)
end



-- ========== Instance Methods ==========

methods_packet = {

    message_begin = function(self)
        return Message.new(self.value)
    end,


    -- Callbacks
    onReceived = function(self, func)
        callbacks["onReceived"][self.value] = func
    end

}
lock_table_packet = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_packet))})



-- ========== Metatables ==========

metatable_packet = {
    __index = function(table, key)
        -- Methods
        if methods_packet[key] then
            return methods_packet[key]
        end

        return nil
    end,


    __newindex = function(table, key, value)

    end,

    
    __metatable = "packet"
}



-- ========== Callbacks ==========

local function packet_onReceived(self, other, result, args)
    local id = args[2].value
    local fn = callbacks["onReceived"][id]
    if fn then fn(Message.new(args[3].value, true), args[5].value) end     -- buffer, Player instance (host only)
end



-- ========== Initialize ==========

initialize_packet = function()
    Callback.add("net_message_onReceived", "RMT-packetReceived", packet_onReceived)
end



return Packet