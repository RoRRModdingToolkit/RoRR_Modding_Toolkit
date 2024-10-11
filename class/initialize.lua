-- Initialize

Initialize = Proxy.new()

local init = false
local funcs = {}
local post_funcs = {}



-- ========== Metatable ==========

metatable_initialize = {
    __call = function(table, func, post)
        if not post then
            funcs[envy.getfenv(2)["!guid"]] = func
            return
        end
        post_funcs[envy.getfenv(2)["!guid"]] = func
    end
}
Initialize:setmetatable(metatable_initialize)



-- ========== Initialize ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Initialize RMT first
        __initialize()

        -- Run initialize functions in load order
        for _, m_id in ipairs(mods.loading_order) do
            if funcs[m_id] then
                funcs[m_id]()
            end
        end

        -- Run post_initialize functions in load order
        for _, m_id in ipairs(mods.loading_order) do
            if post_funcs[m_id] then
                post_funcs[m_id]()
            end
        end
    end
end)



return Initialize