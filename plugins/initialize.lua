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
                m.__initialize()
            end
        end

        -- Loop through all mods and call their __post_initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__post_initialize and (not m.RoRR_Modding_Toolkit) then
                m.__post_initialize()
            end
        end
    end
end)