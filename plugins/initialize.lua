-- Initialize

local init = false



-- ========== Functions ==========

local rmt_class_init = function(m)
    if not pcall(function()
        if not m.RMT_Class_Init then
            m.RMT_Class_Init = true
            for _, c in ipairs(Classes) do
                if _G[c] then m._G[c] = _G[c] end
            end
        end
    end) then
        log.warning(m["!guid"].." : Failed to add RMT class references.")
    end
end


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Initialize RMT first
        __initialize()

        -- Loop through all mods and call their __initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__initialize and (not m.RoRR_Modding_Toolkit) then
                rmt_class_init(m)

                if not pcall(m.__initialize) then
                    log.warning(m["!guid"].." : __initialize failed to run.")
                end
            end
        end

        -- Loop through all mods and call their __post_initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__post_initialize and (not m.RoRR_Modding_Toolkit) then
                rmt_class_init(m)

                if not pcall(m.__post_initialize) then
                    log.warning(m["!guid"].." : __post_initialize failed to run.")
                end
            end
        end
    end
end)