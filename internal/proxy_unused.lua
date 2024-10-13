-- -- Proxy

-- local _proxy = setmetatable({}, {__mode = "k"})

-- local setmt = setmetatable

-- local methods_proxy = {
--     lock = function(proxy, lock_table)
--         if not proxy then log.error("No proxy reference provided", 2) end
--         if proxy.proxy_locked then return end
--         if lock_table then
--             proxy.keys_locked = lock_table
--             return proxy
--         end
--         proxy.proxy_locked = true
--         return proxy
--     end,

--     setmetatable = function(proxy, metatable)
--         if not proxy then log.error("No proxy reference provided", 2) end
--         if not metatable then log.error("No metatable provided", 2) end
--         setmt(_proxy[proxy], metatable)
--     end
-- }

-- local metatable_proxy = {
--     __index = function(t, key)
--         if methods_proxy[key] then return methods_proxy[key] end
--         return _proxy[t][key]
--     end,
    
--     __newindex = function(t, key, value)
--         if t.proxy_locked then log.error("Table is read-only", 2) end
--         if t.keys_locked[key] then log.error("Key is read-only", 2) end
--         _proxy[t][key] = value
--     end,

--     __len = function(t)
--         return #_proxy[t]
--     end,

--     __call = function(t, ...)
--         return _proxy[t](...)
--     end,

--     __metatable = "proxy"
-- }

-- -- local metatable_proxy_keys_locked = {
-- --     __index = function(t, key)
-- --         return _proxy[t][key]
-- --     end,
    
-- --     __newindex = function(t, key, value)
-- --         if t[key] and value ~= true then log.error("Key cannot be unlocked", 2) end
-- --         _proxy[t][key] = value
-- --     end,

-- --     __metatable = "proxy keys_locked"
-- -- }

-- local new = function(t)
--     local proxy = {}
--     _proxy[proxy] = t or {}
--     _proxy[proxy].proxy_locked = false
--     _proxy[proxy].keys_locked = {}
--     setmetatable(proxy, metatable_proxy)

--     -- local keys_locked = {}
--     -- _proxy[keys_locked] = {
--     --     keys_locked = true,
--     --     lock = true,
--     --     setmetatable = true
--     -- }
--     -- setmetatable(keys_locked, metatable_proxy_keys_locked)
--     -- _proxy[proxy].keys_locked = keys_locked

--     return proxy
-- end

-- Proxy = new()
-- Proxy.new = new
-- Proxy.make_lock_table = function(t)
--     local lt = {keys_locked = true}
--     for i = 1, #t do lt[t[i]] = true end
--     local proxy = new(lt)
--     proxy:lock()
--     return proxy
-- end
-- Proxy:lock()