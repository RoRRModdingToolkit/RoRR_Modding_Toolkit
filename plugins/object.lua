-- Object

Object = {}

local callbacks = {}



-- ========== Enums ==========

Object.ARRAY = {
    base        = 0,
    obj_depth   = 1,
    obj_sprite  = 2,
    identifier  = 3,
    namespace   = 4,
    on_create   = 5,
    on_destroy  = 6,
    on_step     = 7,
    on_draw     = 8
}


Object.CUSTOM_START = 800



-- ========== Static Methods ==========

Object.find = function(namespace, identifier)
    -- Vanilla object_index
    if type(namespace) == "number" then
        return Object.make_instance(namespace)
    end

    if identifier then namespace = namespace.."-"..identifier end

    -- Vanilla namespaced objects
    if string.sub(namespace, 1, 3) == "ror" then
        local obj = gm.constants["o"..string.upper(string.sub(namespace, 5, 5))..string.sub(namespace, 6, #namespace)]
        if obj then
            return Object.make_instance(obj)
        end
        return nil
    end

    -- Custom objects
    local ind = gm.object_find(namespace)
    if ind then
        return Object.make_instance(ind)
    end

    return nil
end


Object.new = function(namespace, identifier, parent)
    local obj = gm.object_add_w(namespace, identifier, parent)
    return Object.make_instance(obj)
end


Object.count = function(obj)
    return gm._mod_instance_number(obj)
end


Object.make_instance = function(object_id)
    local abstraction = {
        value = object_id
    }
    setmetatable(abstraction, metatable_object)
    return abstraction
end



-- ========== Instance Methods ==========

methods_object = {

    create = function(self, x, y)
        local inst = gm.instance_create(x, y, self.value)
        return Instance.make_instance(inst)
    end,


    add_callback = function(self, callback, func)
        if self.value < Object.CUSTOM_START then return end

        if callback == "onCreate"
        or callback == "onDestroy"
        or callback == "onStep"
        or callback == "onDraw"
        then
            local callback_id = self["on_"..string.lower(string.sub(callback, 3, 3))..string.sub(callback, 4, #callback)]
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        end
    end,


    get_depth = function(self)
        return gm.object_get_depth(self.value)
    end,


    set_depth = function(self, depth)
        -- Does not apply retroactively to existing instances
        local depths = gm.variable_global_get("object_depths")
        gm.array_set(depths, self.value, depth)
    end,


    get_sprite = function(self)
        return gm.object_get_sprite_w(self.value)
    end,


    set_sprite = function(self, sprite)
        gm.object_set_sprite_w(self.value, sprite)
    end,


    set_collision = function(self, left, top, right, bottom)
        -- Collision masks are linked to sprites, not objects
        local spr = self:get_sprite()
        local orig_x = gm.sprite_get_xoffset(spr)
        local orig_y = gm.sprite_get_yoffset(spr)
        gm.sprite_collision_mask(spr, false, 2, left + orig_x, top + orig_y, right + orig_x, bottom + orig_y, 0, 0)
    end

}



-- ========== Metatables ==========

metatable_object_gs = {
    -- Getter
    __index = function(table, key)
        local index = Object.ARRAY[key]
        if index and table.value >= Object.CUSTOM_START then
            local custom_object = gm.variable_global_get("custom_object")
            local obj_array = gm.array_get(custom_object, table.value - Object.CUSTOM_START)
            return gm.array_get(obj_array, index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Object.ARRAY[key]
        if index and table.value >= Object.CUSTOM_START then
            local custom_object = gm.variable_global_get("custom_object")
            local item_array = gm.array_get(custom_object, table.value - Object.CUSTOM_START)
            gm.array_set(obj_array, index, value)
        end
    end
}


metatable_object = {
    __index = function(table, key)
        -- Methods
        if methods_object[key] then
            return methods_object[key]
        end

        -- Pass to next metatable
        return metatable_object_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_object_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- Custom object callbacks
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.make_instance(args[2].value))   -- Instance
        end
    end
end)
