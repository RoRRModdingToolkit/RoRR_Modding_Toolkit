-- Initialize

local init = false



-- ========== Functions ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Loop through all mods and call their __initialize functions
        for _, m in pairs(mods) do
            if type(m) == "table" and m.__initialize then
                m.__initialize()
            end
        end
    end
end)