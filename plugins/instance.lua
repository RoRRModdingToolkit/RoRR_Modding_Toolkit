-- Instance

Instance = {}



-- ========== Static Methods ==========

Instance.exists = function(inst)
    return gm.instance_exists(inst) == 1.0
end


Instance.find = function(...)
    local t = {...}
    if type(t[1]) == "table" and (not t[1].value) then t = t[1] end

    for _, obj in ipairs(t) do
        if type(obj) == "table" then obj = obj.value end

        local inst = gm.instance_find(obj, 0)
        if obj >= 800.0 then
            local count = Object.count(gm.constants.oCustomObject)
            for i = 0, count - 1 do
                local ins = gm.instance_find(gm.constants.oCustomObject, i)
                if ins.__object_index == obj then
                    inst = ins
                    break
                end
            end
        end

        if inst ~= nil and inst ~= -4.0 then
            return Instance.make_instance(inst)
        end
    end

    -- None
    return Instance.make_invalid()
end


Instance.find_all = function(...)
    local t = {...}
    if type(t[1]) == "table" and (not t[1].value) then t = t[1] end

    local insts = {}

    for _, obj in ipairs(t) do
        if type(obj) == "table" then obj = obj.value end

        if obj < 800.0 then
            local count = Object.count(obj)
            for n = 0, count - 1 do
                local inst = gm.instance_find(obj, n)
                table.insert(insts, Instance.make_instance(inst))
            end

        else
            local count = Object.count(gm.constants.oCustomObject)
            for n = 0, count - 1 do
                local inst = gm.instance_find(gm.constants.oCustomObject, n)
                if inst.__object_index == obj then
                    table.insert(insts, Instance.make_instance(inst))
                end
            end

        end
    end

    return insts, #insts > 0
end


Instance.make_instance = function(inst)
    local abstraction = {
        value = inst
    }
    if gm.object_is_ancestor(inst.object_index, gm.constants.pActor) == 1.0 then
        setmetatable(abstraction, Actor.make_metatable(inst))
    else setmetatable(abstraction, Instance.make_metatable(inst))
    end
    return abstraction
end


Instance.make_invalid = function()
    local abstraction = {
        value = nil
    }
    setmetatable(abstraction, Instance.make_metatable(nil))
    return abstraction
end



-- ========== Instance Methods ==========

Instance.make_metatable = function(inst)
    return {
        __index = setmetatable({

            value = inst,


            -- Return true if instance exists
            exists = function(self)
                return gm.instance_exists(self.value) == 1.0
            end,


            -- Return true if the other instance is the same one
            same = function(self, other)
                if not self:exists() then return false end
                if type(other) == "table" then other = other.value end
                return self.value == other
            end

        },
        {
            -- Getter
            __index = function(table, key)
                local var = rawget(table, "value")
                if var then return gm.variable_instance_get(var, key) end
                return nil
            end
        }),


        -- Setter
        __newindex = function(table, key, value)
            local var = rawget(table, "value")
            if var then gm.variable_instance_set(var, key, value) end
        end
    }
end


-- metatable_instance = {
--     __index = setmetatable({

--         -- Return true if instance exists
--         exists = function(self)
--             return gm.instance_exists(self.value) == 1.0
--         end

--     },
--     {
--         -- Getter
--         __index = function(table, key)
--             return rawget(table, "value")
--             --return gm.variable_instance_get(rawget(table, "value"), key)
--         end,


--         -- Setter
--         __newindex = function(table, key, value)
--             --return gm.variable_instance_set(rawget(table, "value"), key, value)
--         end
--     })
-- }