-- Initialize

local init = false



-- ========== Functions ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true

        -- Initialize RMT first
        __initialize()

        -- Get list of mods in load order
        local ms = {}
        local skip = {
            "ReturnOfModding-GLOBAL",
            "RoRRModdingToolkit-RoRR_Modding_Toolkit"
        }
        for _, m_id in ipairs(mods.loading_order) do
            if not Helper.table_has(skip, m_id) then
                table.insert(ms, {
                    id      = m_id,
                    tabl    = mods[m_id]
                })
            end
        end

        -- Loop 1
        for _, m in ipairs(ms) do
            -- Add RMT class references if they have a dependency
            local status, err = pcall(function()
                for _, c in ipairs(Classes) do
                    if _G[c] then m.tabl._G[c] = _G[c] end
                end
            end)
            if not status then
                log.warning(m.id.." : Failed to add RMT class references.\n"..err)
            end

            -- Call __initialize
            if m.tabl.__initialize then
                local status, err = pcall(m.tabl.__initialize)
                if not status then
                    log.warning(m.id.." : __initialize failed to execute fully.\n"..err)
                end
            end
        end

        -- Loop 2
        for _, m in ipairs(ms) do
            -- Call __post_initialize
            if m.tabl.__post_initialize then
                local status, err = pcall(m.tabl.__post_initialize)
                if not status then
                    log.warning(m.id.." : __post_initialize failed to execute fully.\n"..err)
                end
            end
        end
    end
end)