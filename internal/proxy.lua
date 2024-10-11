-- Proxy

Proxy = setmetatable({}, {__mode = "k"})

local metatable_proxy = {
    __index = function(table, key)
        if key == "lock" then
            return function(proxy, ...)
                if proxy then
                    if not ... then proxy.proxy_locked = true
                    else
                        local keys = {...}
                        if type(keys[1]) == "table" then keys = keys[1] end
                        for _, k in ipairs(keys) do
                            proxy.keys_locked:insert(k)
                        end
                    end
                end
            end
        elseif key == "unlock" then     -- May not be needed
            return function(proxy)
                if proxy then proxy.proxy_locked = nil end
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
        if table.keys_locked[key] then log.error("Cannot modify key", 2) end
        Proxy[table][key] = value
    end
}

Proxy.new = function()
    local proxy = {}
    Proxy[proxy] = {
        keys_locked = {}
    }
    proxy.proxy = Proxy[proxy]
    setmetatable(proxy, metatable_proxy)
    return proxy
end