-- GM

local abstraction_data = setmetatable({}, {__mode = "k"})

GM = {}
abstraction_data[GM] = {}
setmetatable(GM, {
    __index = function(table, key)
        return abstraction_data[table][key]
    end,

    __newindex = function(table, key, value)
        log.error("Cannot overwrite GM functions", 2)
    end
})



-- ========== Functions ==========

for fn, _ in pairs(gm.constants) do
    local type_ = gm.constant_types[fn]
    if type_ == "script" or type_ == "gml_script" then
        abstraction_data[GM][fn] = function(...)
            local t = {...}
            for i, arg in ipairs(t) do
                t[i] = Wrap.unwrap(arg)
            end
            return Wrap.wrap(gm.call(fn, nil, nil, table.unpack(t)))
        end
    end
end



-- ========== Internal ==========

gm_add_instance_methods = function(methods_table)
    for fn, _ in pairs(gm.constants) do
        local type_ = gm.constant_types[fn]
        if type_ == "script" or type_ == "gml_script" then
            if not methods_table[fn] then
                methods_table[fn] = function(self, ...)
                    local t = {...}
                    for i, arg in ipairs(t) do
                        t[i] = Wrap.unwrap(arg)
                    end
                    return Wrap.wrap(gm.call(fn, self.value, self.value, table.unpack(t)))
                end
            end
        end
    end
end