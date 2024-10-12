-- Proxy

_proxy = setmetatable({}, {__mode = "k"})

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
                    setmetatable(_proxy[proxy], metatable)
                end
            end
        end

        return _proxy[table][key]
    end,
    
    __newindex = function(table, key, value)
        if table.proxy_locked then log.error("Table is read-only", 2) end
        if table.keys_locked[key] then log.error("Key is read-only", 2) end
        _proxy[table][key] = value
    end,

    __len = function(table)
        return #_proxy[table]
    end,

    __call = function(table, ...)
        return _proxy[table](...)
    end,

    __metatable = "proxy"
}

local metatable_proxy_keys_locked = {
    __index = function(table, key)
        return _proxy[table][key]
    end,
    
    __newindex = function(table, key, value)
        if table[key] and value ~= true then log.error("Key cannot be unlocked", 2) end
        _proxy[table][key] = value
    end,

    __metatable = "proxy keys_locked"
}

local new = function()
    local proxy = {}
    _proxy[proxy] = {
        proxy_locked = false
    }
    setmetatable(proxy, metatable_proxy)

    local keys_locked = {}
    _proxy[keys_locked] = {
        keys_locked = true,
        lock = true,
        setmetatable = true
    }
    setmetatable(keys_locked, metatable_proxy_keys_locked)
    _proxy[proxy].keys_locked = keys_locked

    return proxy
end

Proxy = new()
Proxy.new = new
Proxy:lock()