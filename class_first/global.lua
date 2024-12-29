-- Global

Global = {}



-- ========== Metatable ==========

metatable_global = {
    -- Getter
    __index = function(table, key)
        return GM.variable_global_get(key)
    end,


    -- Setter
    __newindex = function(table, key, value)
        GM.variable_global_set(key, value)
    end,


    __metatable = "Global"
}
setmetatable(Global, metatable_global)



return Global