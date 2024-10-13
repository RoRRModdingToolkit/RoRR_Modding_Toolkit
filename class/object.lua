-- Object

Object = Proxy.new()

local callbacks = {}
local other_callbacks = {
    "onCreate",
    "onDestroy",
    "onStep",
    "onDraw"
}



-- ========== Enums ==========

Object.ARRAY = Proxy.new({
    base        = 0,
    obj_depth   = 1,
    obj_sprite  = 2,
    identifier  = 3,
    namespace   = 4,
    on_create   = 5,
    on_destroy  = 6,
    on_step     = 7,
    on_draw     = 8
}):lock()


Object.PARENT = Proxy.new({
    actor               = gm.constants.pActor,
    enemyClassic        = gm.constants.pEnemyClassic,
    enemyFlying         = gm.constants.pEnemyFlying,
    boss                = gm.constants.pBoss,
    bossClassic         = gm.constants.pBossClassic,
    pickupItem          = gm.constants.pPickupItem,
    pickupEquipment     = gm.constants.pPickupEquipment,
    drone               = gm.constants.pDrone,
    mapObjects          = gm.constants.pMapObjects,
    interactable        = gm.constants.pInteractable,
    interactableChest   = gm.constants.pInteractableChest,
    interactableCrate   = gm.constants.pInteractableCrate,
    interactableDrone   = gm.constants.pInteractableDrone
}):lock()


Object.CUSTOM_START = 800



-- ========== Static Methods ==========

Object.new = function(namespace, identifier, parent)
    local obj = Object.find(namespace, identifier)
    if obj then return obj end

    local obj = gm.object_add_w(namespace, identifier, Wrap.unwrap(parent))
    return Object.wrap(obj)
end


Object.find = function(namespace, identifier)
    -- Vanilla object_index
    if type(namespace) == "number" then
        return Object.wrap(namespace)
    end

    if identifier then namespace = namespace.."-"..identifier end

    -- Custom objects
    local ind = gm.object_find(namespace)
    if ind then
        return Object.wrap(ind)
    end

    -- Vanilla namespaced objects
    if string.sub(namespace, 1, 3) == "ror" then
        local obj = gm.constants["o"..string.upper(string.sub(namespace, 5, 5))..string.sub(namespace, 6, #namespace)]
        if obj then
            return Object.wrap(obj)
        end
        return nil
    end

    return nil
end


Object.wrap = function(value)
    local wrapper = Proxy.new()
    wrapper.RMT_object = "Object"
    wrapper.value = value
    wrapper:setmetatable(metatable_object)
    wrapper:lock(methods_object_lock)
    return wrapper
end



-- ========== Instance Methods ==========

methods_object = {

    create = function(self, x, y)
        local inst = gm.instance_create(x or 0, y or 0, self.value)
        return Instance.wrap(inst)
    end,


    add_callback = function(self, callback, func)
        self:add_callback_obj_actual(callback, func)
    end,


    add_callback_obj_actual = function(self, callback, func)
        if self.value < Object.CUSTOM_START then return end

        if Helper.table_has(other_callbacks, callback) then 
            local callback_id = self["on_"..string.lower(string.sub(callback, 3, 3))..string.sub(callback, 4, #callback)]
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        else log.error("Invalid callback name", 2)

        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_create] = nil
        callbacks[self.on_destroy] = nil
        callbacks[self.on_step] = nil
        callbacks[self.on_draw] = nil
    end,


    get_sprite = function(self)
        return gm.object_get_sprite_w(self.value)
    end,


    set_sprite = function(self, sprite)
        gm.object_set_sprite_w(self.value, sprite)
    end,


    get_depth = function(self)
        local depths = Array.wrap(gm.variable_global_get("object_depths"))
        return depths:get(self.value)
    end,


    set_depth = function(self, depth)
        -- Does not apply retroactively to existing instances
        local depths = Array.wrap(gm.variable_global_get("object_depths"))
        depths:set(self.value, depth)
    end,


    -- Callbacks
    onCreate        = function(self, func) self:add_callback("onCreate", func) end,
    onDestroy       = function(self, func) self:add_callback("onDestroy", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    onDraw          = function(self, func) self:add_callback("onDraw", func) end

}



-- ========== Metatables ==========

metatable_object_gs = {
    -- Getter
    __index = function(table, key)
        if table.value >= Object.CUSTOM_START then
            local index = Object.ARRAY[key]
            if index then
                local custom_object = Array.wrap(gm.variable_global_get("custom_object"))
                local obj_array = custom_object:get(table.value - Object.CUSTOM_START)
                return obj_array:get(index)
            end
            log.error("Non-existent object property", 2)
            return nil
        end
        log.error("No object properties for vanilla objects", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        if table.value >= Object.CUSTOM_START then
            local index = Object.ARRAY[key]
            if index then
                local custom_object = Array.wrap(gm.variable_global_get("custom_object"))
                local obj_array = custom_object:get(table.value - Object.CUSTOM_START)
                obj_array:set(index, value)
                return
            end
            log.error("Non-existent object property", 2)
            return
        end
        log.error("No object properties for vanilla objects", 2)
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
    end,


    __metatable = "object"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- Custom object callbacks
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value))   -- Instance
        end
    end
end)



return Object