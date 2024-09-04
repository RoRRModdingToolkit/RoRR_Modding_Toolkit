-- Object

Object = {}



-- ========== Static Methods ==========

Object.find = function(namespace, identifier)
    -- Vanilla object_index
    if type(namespace) == "number" then
        local abstraction = {
            value = namespace
        }
        setmetatable(abstraction, metatable_object)
        return abstraction
    end

    if identifier then namespace = namespace.."-"..identifier end

    -- Vanilla namespaced objects
    if string.sub(namespace, 1, 3) == "ror" then
        local obj = gm.constants["o"..string.upper(string.sub(namespace, 5, 5))..string.sub(namespace, 6, #namespace)]
        if obj then
            local abstraction = {
                value = obj
            }
            setmetatable(abstraction, metatable_object)
            return abstraction
        end
        return nil
    end

    -- Custom objects
    local ind = gm.object_find(namespace)
    if ind then
        local abstraction = {
            value = ind
        }
        setmetatable(abstraction, metatable_object)
        return abstraction
    end

    return nil
end


Object.count = function(obj)
    return gm._mod_instance_number(obj)
end



-- ========== Instance Methods ==========

metatable_object = {
    __index = {

        create = function(self, x, y)
            local inst = gm.instance_create(x, y, self.value)

            -- Instance
            return Instance.make_instance(inst)
        end

    }
}