-- Message

Message = Proxy.new()

local message_proxy = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

Message.new = function(buffer, locked)
    local key = {}
    message_proxy[key] = {
        buffer = buffer or GM._mod_net_message_begin(),
        locked = locked
    }
    return Message.wrap(key)
end


Message.wrap = function(value)
    return make_wrapper(value, "Message", metatable_message, lock_table_message)
end



-- ========== Instance Methods ==========

methods_message = {

    write_byte = function(self, value)
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writebyte_direct(m.buffer, value)
    end,
    
    write_short = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writeshort_direct(m.buffer, value)
    end,

    write_ushort = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writeushort_direct(m.buffer, value)
    end,

    write_half = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writehalf_direct(m.buffer, value)
    end,

    write_uhalf = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writeuhalf_direct(m.buffer, value)
    end,

    write_int = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writeint_direct(m.buffer, value)
    end,

    write_uint = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writeuint_direct(m.buffer, value)
    end,

    write_float = function(self, value)
        if type(value) ~= "number" then log.error("Argument is not a number", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writefloat_direct(m.buffer, value)
    end,

    write_string = function(self, value)
        if type(value) ~= "string" then log.error("Argument is not a string", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.writestring_direct(m.buffer, value)
    end,

    write_instance = function(self, value)
        if not GM.instance_exists(value) then log.error("Argument is not an instance", 2) end
        local m = message_proxy[self.value]
        if m.locked then log.error("Cannot modify message", 2) end
        GM.write_instance_direct(m.buffer, value)
    end,


    read_byte = function(self)
        local m = message_proxy[self.value]
        return GM.readbyte_direct(m.buffer)
    end,
    
    read_short = function(self)
        local m = message_proxy[self.value]
        return GM.readshort_direct(m.buffer)
    end,

    read_ushort = function(self)
        local m = message_proxy[self.value]
        return GM.readushort_direct(m.buffer)
    end,

    read_half = function(self)
        local m = message_proxy[self.value]
        return GM.readhalf_direct(m.buffer)
    end,

    read_uhalf = function(self)
        local m = message_proxy[self.value]
        return GM.readuhalf_direct(m.buffer)
    end,

    read_int = function(self)
        local m = message_proxy[self.value]
        return GM.readint_direct(m.buffer)
    end,

    read_uint = function(self)
        local m = message_proxy[self.value]
        return GM.readuint_direct(m.buffer)
    end,

    read_float = function(self)
        local m = message_proxy[self.value]
        return GM.readfloat_direct(m.buffer)
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
        if m.locked then log.error("Message already sent", 2) end
        local m = message_proxy[self.value]
        m.locked = true
        GM._mod_net_message_send(m.packet, 0)
    end,


    send_direct = function(self, specific_player)
        if Net.get_type() ~= Net.TYPE.host then log.error("Must be the host", 2) end
        if m.locked then log.error("Message already sent", 2) end
        local m = message_proxy[self.value]
        m.locked = true
        GM._mod_net_message_send(m.packet, 1, specific_player)
    end,


    send_exclude = function(self, specific_player)
        if Net.get_type() ~= Net.TYPE.host then log.error("Must be the host", 2) end
        if m.locked then log.error("Message already sent", 2) end
        local m = message_proxy[self.value]
        m.locked = true
        GM._mod_net_message_send(m.packet, 2, specific_player)
    end,


    send_to_host = function(self)
        if Net.get_type() ~= Net.TYPE.client then log.error("Must be a client", 2) end
        if m.locked then log.error("Message already sent", 2) end
        local m = message_proxy[self.value]
        m.locked = true
        GM._mod_net_message_send(m.packet, 3)
    end

}
lock_table_message = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_message))})



-- ========== Metatables ==========

metatable_message = {
    __index = function(table, key)
        -- Methods
        if methods_message[key] then
            return methods_message[key]
        end

        return nil
    end,


    __newindex = function(table, key, value)
        
    end,

    
    __metatable = "message"
}



return Message