-- Proxy

Proxy = setmetatable({}, {__mode = "k"})

local metatable_proxy = {
    __index = function(table, key)
        if key == "lock" then
            return function(proxy)
                if proxy then proxy.proxy_locked = true end
            end
        end

        return Proxy[table][key]
    end,
    
    __newindex = function(table, key, value)
        if table.proxy_locked then log.error("Cannot modify table", 2) end
        Proxy[table][key] = value
    end
}

Proxy.new = function()
    local proxy = {}
    Proxy[proxy] = {}
    setmetatable(proxy, metatable_proxy)
    return proxy
end