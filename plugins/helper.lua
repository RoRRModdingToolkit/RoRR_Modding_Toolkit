-- Helper
-- Originally in HelperFunctions by Klehrik

Helper = {}

local init = false
local init_funcs = {}



-- ========== Functions ==========

Helper.initialize = function(func)
    table.insert(init_funcs, func)
end


Helper.chance = function(n)
    return gm.random_range(0, 1) <= n
end


Helper.ease_in = function(x, n)
    return gm.power(x, n or 2)
end


Helper.ease_out = function(x, n)
    return 1 - gm.power(1 - x, n or 2)
end


Helper.table_merge = function(...)
    local new = {}
    for _, t in ipairs{...} do
        for k, v in pairs(t) do
            if tonumber(k) then
                while new[k] do k = k + 1 end
            end
            new[k] = v
        end
    end
    return new
end


Helper.table_to_string = function(table_)
    local str = ""
    for i, v in ipairs(table_) do
        if type(v) == "table" then str = str.."[[||"..Helper.table_to_string(v).."||]]||"
        else str = str..tostring(v).."||"
        end
    end
    return string.sub(str, 1, -3)
end


Helper.string_to_table = function(string_)
    local raw = gm.string_split(string_, "||")
    local parsed = {}
    local i = 0
    while i < #raw do
        i = i + 1
        if raw[i] == "[[" then  -- table
            local inner = raw[i + 1].."||"
            local j = i + 2
            local open = 1
            while true do
                if raw[j] == "[[" then open = open + 1
                elseif raw[j] == "]]" then open = open - 1
                end
                if open <= 0 then break end
                inner = inner..raw[j].."||"
                j = j + 1
            end
            table.insert(parsed, Helper.string_to_table(string.sub(inner, 1, -3)))
            i = j
        else
            local value = raw[i]
            if tonumber(value) then value = tonumber(value)
            elseif value == "true" then value = true
            elseif value == "false" then value = false
            elseif value == "nil" then value = nil
            end
            table.insert(parsed, value)
        end
    end
    return parsed
end



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if not init then
        init = true
        for _, fn in ipairs(init_funcs) do
            fn()
        end
    end
end)