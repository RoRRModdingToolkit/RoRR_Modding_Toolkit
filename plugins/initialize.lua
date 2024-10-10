-- Initialize

local init = false



-- ========== Functions ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Initialize RMT first
        __initialize()

        -- Loop through all mods and call their __initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__initialize and (not m.RoRR_Modding_Toolkit) then
                if not pcall(function()
                    for _, c in ipairs(Classes) do
                        if _G[c] then m._G[c] = _G[c] end
                    end
                end) then
                    log.info("[!] "..m["!guid"].." : Failed to add RMT class references.")
                end

                if not pcall(m.__initialize) then
                    log.info("[!] "..m["!guid"].." : __initialize failed to run.")
                end
            end
        end

        -- Loop through all mods and call their __post_initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__post_initialize and (not m.RoRR_Modding_Toolkit) then
                if not pcall(m.__post_initialize) then
                    log.info("[!] "..m["!guid"].." : __post_initialize failed to run.")
                end
            end
        end
    end
end)