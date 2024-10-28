-- Packet

Packet = Proxy.new()

callbacks = {
    onReceived = {}
}



-- ========== Enums ==========





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
        return Message.wrap(GM._mod_net_message_begin())
    end,


    -- Callbacks
    onReceived = function(self, func)
        if not callbacks["onReceived"][self.value] then callbacks["onReceived"][self.value] = {}
        table.insert(callbacks["onReceived"][self.value], func)
    end

}
lock_table_packet = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_packet))})



-- ========== Metatables ==========

metatable_packet_gs = {
    -- Getter
    __index = function(table, key)
        
    end,


    -- Setter
    __newindex = function(table, key, value)            
        
    end
}


metatable_packet = {
    __index = function(table, key)
        -- Methods
        if methods_packet[key] then
            return methods_packet[key]
        end

        -- Pass to next metatable
        return metatable_packet_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        metatable_packet_gs.__newindex(table, key, value)
    end,

    
    __metatable = "packet"
}



-- ========== Callbacks ==========

local function packet_onReceived(self, other, result, args)
    
end



-- ========== Initialize ==========

initialize_packet = function()
    Callback.add("net_message_onReceived", "RMT-packetReceived", packet_onReceived)
end



return Packet