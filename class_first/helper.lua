-- Helper

Helper = Proxy.new()

local packet_syncCrate



-- ========== Static Methods ==========

Helper.log_hook = function(self, other, result, args)
    log.info("----------")

    local obj_ind = function(val)
        if val.object_index then val = gm.object_get_name(val.object_index) end
        return val
    end

    local value = tostring(self)
    if not gm.is_struct(self) then
        local bool, val = pcall(obj_ind, self)
        if bool then value = val end
        log.info("[self]  "..value)
    else
        log.info("[self]  struct")
        Helper.log_struct(self, "    ", true)
    end

    local value = tostring(other)
    if not gm.is_struct(other) then
        local bool, val = pcall(obj_ind, other)
        if bool then value = val end
        log.info("[other]  "..value)
    else
        log.info("[other]  struct")
        Helper.log_struct(other, "    ", true)
    end

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
        Helper.log_struct(result.value, "    ", true)
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
            Helper.log_struct(a.value, "    ", true)
        end
    end

    log.info("----------")
end


Helper.log_struct = function(struct, indent, no_borders)
    struct = Wrap.unwrap(struct)
    
    if not no_borders then log.info("----------") end
    indent = indent or ""
    local names = GM.struct_get_names(struct)
    for _, name in ipairs(names) do
        log.info(indent..name.." = "..tostring(gm.variable_struct_get(struct, name)))
    end
    if not no_borders then log.info("----------") end
end


Helper.is_true = function(value)
    return value == true or value == 1.0
end


Helper.is_false = function(value)
    return (not value) or value == 0.0
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


Helper.table_has = function(t, value)
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end


Helper.table_remove = function(t, value)
    for i, v in pairs(t) do
        if v == value then
            table.remove(t, i)
            return
        end
    end
end


Helper.table_get_keys = function(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
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
    for i = 1, #table_ do
        local v = table_[i]
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


Helper.read_json = function(filepath)
    -- Read file content
    local str = ""
    local file = gm.file_text_open_read(filepath)
    while gm.file_text_eof(file) == 0.0 do
        str = str..gm.file_text_readln(file)
    end
    gm.file_text_close(file)

    -- Parse string
    local gm_parse = gm.json_parse(str)
    local keys = GM.variable_struct_get_names(gm_parse)

    -- Format parsed table (recursive)
    local function parse_struct(t, struct, keys)
        for _, key in ipairs(keys) do
            local val = struct[key]
            if gm.is_struct(val) then
                t[key] = {}
                parse_struct(t[key], val, GM.variable_struct_get_names(val))
            elseif gm.is_array(val) then
                t[key] = {}
                local array = Array.wrap(val)
                for _, val in ipairs(array) do
                    table.insert(t[key], val)
                end
            else t[key] = val
            end
        end
        return t
    end

    return parse_struct({}, gm_parse, keys)
end


Helper.sync_crate_contents = function(crate)
    if Net.is_single() then return end
    crate = Instance.wrap(crate)

    local array = crate.contents
    local contents = {}
    for _, obj_id in ipairs(array) do
        table.insert(contents, obj_id)
    end

    local message = packet_syncCrate:message_begin()
    message:write_instance(crate)
    message:write_string(Helper.table_to_string(contents))

    if Net.is_host() then message:send_to_all()
    else message:send_to_host()
    end
end



-- ========== Initialize ==========

function initialize_helper()
    packet_syncCrate = Packet.new()
    packet_syncCrate:onReceived(function(message, player)
        local crate = message:read_instance()
        local contents_raw = message:read_string()
        local contents = Helper.string_to_table(contents_raw)

        crate.contents = Array.new()
        for _, obj_id in ipairs(contents) do
            crate.contents:insert(0, obj_id)
        end

        -- [Host]  Send to other players
        if Net.is_host() then
            local message = packet_syncCrate:message_begin()
            message:write_instance(crate)
            message:write_string(contents_raw)
            message:send_exclude(player)
        end
    end)
end



return Helper