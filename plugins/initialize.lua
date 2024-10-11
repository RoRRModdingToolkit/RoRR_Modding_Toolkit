-- Initialize

local init = false



-- ========== Functions ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Initialize RMT first
        __initialize()

        -- Loop through all mods and add RMT class references if they have a dependency
        for _, m in pairs(mods) do
            if type(m) == "table" and Helper.table_has(m._PLUGIN.dependencies_no_version_number, "RoRRModdingToolkit-RoRR_Modding_Toolkit") then
                local status, err = pcall(function()
                    for _, c in ipairs(Classes) do
                        if _G[c] then m._G[c] = _G[c] end
                    end
                end)
                if not status then
                    log.warning(m["!guid"].." : Failed to add RMT class references.\n"..err)
                end
            end
        end

        -- Loop through all mods and call their __initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__initialize and (not m.RoRR_Modding_Toolkit) then
                local status, err = pcall(m.__initialize)
                if not status then
                    log.warning(m["!guid"].." : __initialize failed to execute fully.\n"..err)
                end
            end
        end

        -- Loop through all mods and call their __post_initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__post_initialize and (not m.RoRR_Modding_Toolkit) then
                local status, err = pcall(m.__post_initialize)
                if not status then
                    log.warning(m["!guid"].." : __post_initialize failed to execute fully.\n"..err)
                end
            end
        end
    end
end)