-- Mod

Mod = {}



-- ========== Static Methods ==========

Mod.find = function(mod_id)
    if not mod_id then
        log.error("No mod_id specified", 2)
        return nil
    end

    for id, m in pairs(mods) do
        if id == mod_id then
            return m
        end
    end

    return nil
end