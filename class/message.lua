-- Message

Message = Proxy.new()

local message_proxy = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

Message.new = function(packet, buffer, locked)
    local key = {}
    message_proxy[key] = {
        packet = packet,
        buffer = buffer or GM._mod_net_message_begin(),
        locked = locked
    }
    return Message.wrap(key)
end


Message.wrap = function(value)
    return make_wrapper(value, metatable_message, lock_table_message)
end



-- ========== Instance Methods ==========

methods_message = {

    write_byte = function(self, value)
        value = Wrap.unwrap(value)
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writebyte_direct(m.buffer, value)
    end,

    write_string = function(self, value)
        value = Wrap.unwrap(value)
        if type(value) ~= "string" then log.error("Argument is not a string", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writestring_direct(m.buffer, value)
    end,

    write_instance = function(self, value)
        value = Wrap.unwrap(value)
        if not GM.instance_exists(value) then log.error("Argument is not an instance", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.write_instance_direct(m.buffer, value)
    end,


    read_byte = function(self)
        local m = message_proxy[self.value]
        return GM.readbyte_direct(m.buffer)
    end,

    read_string = function(self)
        local m = message_proxy[self.value]
        return GM.readstring_direct(m.buffer)
    end,

    read_instance = function(self)
        local m = message_proxy[self.value]
        return GM.read_instance_direct(m.buffer)
    end,


    send_to_all = function(self)
        if Net.get_type() ~= Net.TYPE.host then log.error("Must be the host", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Message already sent", 2) end
        m.locked = true
        GM._mod_net_message_send(m.packet, 0)
    end,


    send_direct = function(self, specific_player)
        if Net.get_type() ~= Net.TYPE.host then log.error("Must be the host", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Message already sent", 2) end
        m.locked = true
        GM._mod_net_message_send(m.packet, 1, specific_player)
    end,


    send_exclude = function(self, specific_player)
        if Net.get_type() ~= Net.TYPE.host then log.error("Must be the host", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Message already sent", 2) end
        m.locked = true
        GM._mod_net_message_send(m.packet, 2, specific_player)
    end,


    send_to_host = function(self)
        if Net.get_type() ~= Net.TYPE.client then log.error("Must be a client", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Message already sent", 2) end
        m.locked = true
        GM._mod_net_message_send(m.packet, 3)
    end

}

local write_num = {
    write_short     = GM.writeshort_direct,
    write_ushort    = GM.writeushort_direct,
    write_half      = GM.writehalf_direct,
    write_int       = GM.writeint_direct,
    write_uint      = GM.writeuint_direct,
    write_float     = GM.writefloat_direct,
    write_double    = GM.writedouble_direct
}
local read_num = {
    read_short      = GM.readshort_direct,
    read_ushort     = GM.readushort_direct,
    read_half       = GM.readhalf_direct,
    read_int        = GM.readint_direct,
    read_uint       = GM.readuint_direct,
    read_float      = GM.readfloat_direct,
    read_double     = GM.readdouble_direct
}

for k, fn in pairs(write_num) do
    methods_message[k] = function(self, value)
        value = Wrap.unwrap(value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        fn(m.buffer, value)
    end
end

for k, fn in pairs(read_num) do
    methods_message[k] = function(self)
        local m = message_proxy[self.value]
        return fn(m.buffer)
    end
end

lock_table_message = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_message))})



-- ========== Metatables ==========

metatable_message = {
    __index = function(table, key)
        -- Methods
        if methods_message[key] then
            return methods_message[key]
        end

        log.warning("No properties to get in Message", 2)
        return nil
    end,


    __newindex = function(table, key, value)
        log.warning("No properties to set in Message", 2)
    end,

    
    __metatable = "Message"
}



return Message