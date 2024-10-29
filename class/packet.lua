-- Packet

Packet = Proxy.new()

local callbacks_onReceived = {}



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
        return Message.new()
    end,


    -- Callbacks
    onReceived = function(self, func)
        callbacks_onReceived[self.value] = func
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

        log.warning("No properties to get in Packet", 2)
        return nil
    end,


    __newindex = function(table, key, value)
        log.warning("No properties to set in Packet", 2)
    end,

    
    __metatable = "packet"
}



-- ========== Callbacks ==========

local function packet_onReceived(self, other, result, args)
    local id = args[2].value
    local fn = callbacks_onReceived[id]
    if fn then fn(Message.new(args[3].value, true), Instance.wrap(args[5].value)) end     -- buffer, Player instance (host only)
end



-- ========== Initialize ==========

Callback.add("net_message_onReceived", "RMT-packetReceived", packet_onReceived)



return Packet