-- Message

Message = Proxy.new()



-- ========== Enums ==========





-- ========== Static Methods ==========

Message.wrap = function(value)
    return make_wrapper(value, "Message", metatable_message, lock_table_message)
end



-- ========== Instance Methods ==========

methods_message = {

    write_int = function(self, value)
        GM.writebyte_direct(self.value, value)
    end,


    write_string = function(self, value)
        GM.writestring_direct(self.value, value)
    end,


    send_to_all = function(self)

    end,


    send_to_host = function(self)

    end,


    send_direct = function(self)
        
    end,


    send_exclude = function(self)

    end

}
lock_table_message = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_message))})



-- ========== Metatables ==========

metatable_message_gs = {
    -- Getter
    __index = function(table, key)
        
    end,


    -- Setter
    __newindex = function(table, key, value)            
        
    end
}


metatable_message = {
    __index = function(table, key)
        -- Methods
        if methods_message[key] then
            return methods_message[key]
        end

        -- Pass to next metatable
        return metatable_messaget_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        metatable_message_gs.__newindex(table, key, value)
    end,

    
    __metatable = "message"
}



-- ========== Hooks ==========





return Message