-- Proxy

Proxy = setmetatable({}, {__mode = "k"})

local metatable_proxy = {
    __index = function(table, key)
        if key == "lock" then
            return function(proxy, ...)
                if proxy and (not proxy.proxy_locked) then
                    if not ... then proxy.proxy_locked = true
                    else
                        local keys = {...}
                        if type(keys[1]) == "table" then keys = keys[1] end
                        for _, k in ipairs(keys) do
                            proxy.keys_locked[k] = true
                        end
                    end
                end
            end
        elseif key == "setmetatable" then
            return function(proxy, metatable)
                if proxy and metatable then
                    setmetatable(Proxy[proxy], metatable)
                end
            end
        end

        return Proxy[table][key]
    end,
    
    __newindex = function(table, key, value)
        if table.proxy_locked then log.error("Cannot modify table", 2) end
        if key == "keys_locked" then log.error("Cannot modify keys_locked", 2) end
        if table.keys_locked[key] then log.error("Cannot modify key", 2) end
        Proxy[table][key] = value
    end
}

local metatable_proxy_keys_locked = {
    __index = function(table, key)
        return Proxy[table][key]
    end,
    
    __newindex = function(table, key, value)
        if value ~= true then log.error("Cannot unlock key", 2) end
        Proxy[table][key] = value
    end
}

Proxy.new = function()
    local proxy = {}
    Proxy[proxy] = {}
    setmetatable(proxy, metatable_proxy)

    local keys_locked = {}
    Proxy[keys_locked] = {}
    setmetatable(keys_locked, metatable_proxy_keys_locked)
    Proxy[proxy].keys_locked = keys_locked

    return proxy
end