-- Initialize

Initialize = Proxy.new()

local init = false
local funcs = {}
local post_funcs = {}



-- ========== Metatable ==========

metatable_initialize = {
    __call = function(t, func, post)
        if not post then
            if not funcs[envy.getfenv(2)["!guid"]] then funcs[envy.getfenv(2)["!guid"]] = {} end
            table.insert(funcs[envy.getfenv(2)["!guid"]], func)
            return
        end

        if not post_funcs[envy.getfenv(2)["!guid"]] then post_funcs[envy.getfenv(2)["!guid"]] = {} end
        table.insert(post_funcs[envy.getfenv(2)["!guid"]], func)
    end,
    
    __metatable = "initialize"
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
                for _, fn in ipairs(funcs[m_id]) do
                    fn()
                end
            end
        end

        -- Run legacy __initialize
        for _, m_id in ipairs(mods.loading_order) do
            local m = mods[m_id]

            -- Check if mod has RMT as a dependency
            if Helper.table_has(
                m._PLUGIN.dependencies_no_version_number,
                "RoRRModdingToolkit-RoRR_Modding_Toolkit"
            ) then

                if m.__initialize then
                    -- Add RMT class references
                    local status, err = pcall(function()
                        for _, c in ipairs(class_refs) do
                            m._G[c] = c
                        end
                    end)
                    if not status then
                        log.warning(m.id.." : Failed to add RMT class references.\n"..err)
                    end

                    -- Call __initialize
                    local status, err = pcall(m.__initialize)
                    if not status then
                        log.warning(m.id.." : __initialize failed to execute fully.\n"..err)
                    end
                end

            end
        end

        -- Run post_initialize functions in load order
        for _, m_id in ipairs(mods.loading_order) do
            if post_funcs[m_id] then
                for _, fn in ipairs(post_funcs[m_id]) do
                    fn()
                end
            end
        end

        -- Run legacy __post_initialize
        for _, m_id in ipairs(mods.loading_order) do
            local m = mods[m_id]

            -- Check if mod has RMT as a dependency
            if Helper.table_has(
                m._PLUGIN.dependencies_no_version_number,
                "RoRRModdingToolkit-RoRR_Modding_Toolkit"
            ) then

                if m.__post_initialize then
                    -- Call __post_initialize
                    local status, err = pcall(m.__post_initialize)
                    if not status then
                        log.warning(m.id.." : __post_initialize failed to execute fully.\n"..err)
                    end
                end

            end
        end
    end
end)



return Initialize