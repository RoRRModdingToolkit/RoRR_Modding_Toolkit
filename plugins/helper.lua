-- Helper
-- Originally in HelperFunctions by Klehrik

Helper = {}



-- ========== Functions ==========

Helper.log_toolkit_stats = function()
    log.info("----------")

    log.info("Callback callbacks: "..Callback.get_callback_count())
    -- log.info("Actor callbacks: "..Actor.get_callback_count())
    -- log.info("Buff callbacks: "..Buff.get_callback_count())
    log.info("Item callbacks: "..Item.get_callback_count())

    log.info("----------")
end


Helper.log_hook = function(self, other, result, args)
    log.info("----------")

    local obj_ind = function(val)
        if val.object_index then val = gm.object_get_name(val.object_index) end
        return val
    end

    local value = tostring(self)
    local bool, val = pcall(obj_ind, self)
    if bool then value = val end
    log.info("[self]  "..value)

    local value = tostring(other)
    local bool, val = pcall(obj_ind, other)
    if bool then value = val end
    log.info("[other]  "..value)

    -- TODO: Tidy up the below at some point

    log.info("")
    log.info("[result]")
    local value = tostring(result.value)

    -- If value is CInstance, print object name
    local bool, val = pcall(obj_ind, result.value)
    if bool then value = val end

    log.info(value)

    -- If value is Array, print all values
    if gm.is_array(result.value) then
        local size = gm.array_length(result.value)
        for i = 0, size - 1 do
            local val = gm.array_get(result.value, i)
            log.info("    ["..i.."]  "..tostring(val))
        end
    end

    -- If value is Struct, print all variables
    if gm.is_struct(result.value) then
        local names = gm.struct_get_names(result.value)
        for j, name in ipairs(names) do
            log.info("    "..name.." = "..tostring(gm.variable_struct_get(result.value, name)))
        end
    end

    log.info("")
    log.info("[args]")
    for i, a in ipairs(args) do
        local value = tostring(a.value)

        -- If value is CInstance, print object name
        local bool, val = pcall(obj_ind, a.value)
        if bool then value = val end

        log.info(value)

        -- If value is Array, print all values
        if gm.is_array(a.value) then
            local size = gm.array_length(a.value)
            for i = 0, size - 1 do
                local val = gm.array_get(a.value, i)
                log.info("    ["..i.."]  "..tostring(val))
            end
        end

        -- If value is Struct, print all variables
        if gm.is_struct(a.value) then
            local names = gm.struct_get_names(a.value)
            for j, name in ipairs(names) do
                log.info("    "..name.." = "..tostring(gm.variable_struct_get(a.value, name)))
            end
        end
    end

    log.info("----------")
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


Helper.table_has = function(table_, value)
    for k, v in pairs(table_) do
        if v == value then return true end
    end
    return false
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


Helper.mixed_hyperbolic = function(stack_count, chance, base_chance)
    local base_chance = base_chance or chance
    local diff = base_chance - chance
    local stacks_chance = chance * stack_count
    return math.max(stacks_chance / (stacks_chance + 1), chance) + diff
end