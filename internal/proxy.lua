-- Proxy

local _proxy = setmetatable({}, {__mode = "k"})

local setmt = setmetatable

local methods_proxy = {
    lock = function(proxy, lock_table)
        if not proxy then log.error("No proxy reference provided", 2) end
        if lock_table then
            proxy.keys_locked = lock_table
        else
            if not proxy.proxy_locked then proxy.proxy_locked = true end
        end
        return proxy
    end,

    setmetatable = function(proxy, metatable)
        if not proxy then log.error("No proxy reference provided", 2) end
        if not metatable then log.error("No metatable provided", 2) end
        setmt(_proxy[proxy], metatable)
    end
}

local metatable_proxy = {
    __index = function(t, key)
        if methods_proxy[key] then return methods_proxy[key] end
        return _proxy[t][key]
    end,
    
    __newindex = function(t, key, value)
        if t.proxy_locked then log.error("Table is read-only", 2) end
        if t.keys_locked and t.keys_locked[key] then log.error("Key is read-only", 2) end
        _proxy[t][key] = value
    end,

    __len = function(t)
        return #_proxy[t]
    end,

    __call = function(t, ...)
        return _proxy[t](...)
    end,

    __pairs = function(t)
        return next, _proxy[t], nil
    end,

    __metatable = "Proxy"
}

local new = function(t)
    local proxy = {}
    _proxy[proxy] = t or {}
    _proxy[proxy].proxy_locked = false
    _proxy[proxy].keys_locked = false
    setmetatable(proxy, metatable_proxy)
    return proxy
end

Proxy = new()
Proxy.new = new
Proxy.make_lock_table = function(t)
    local lt = {keys_locked = true}
    for i = 1, #t do lt[t[i]] = true end
    return new(lt):lock()
end
Proxy:lock()