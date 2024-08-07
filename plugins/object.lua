-- Object

-- This is not a true implementation using a oCustomObject, but rather
-- creates a custom item and pretends that it is a new object via overrides.

Object = {}

local PREFIX = "[RMT_OBJ]"
local callbacks = {
    Init = {},
    Step = {},
    Draw = {},
    Hitbox = {}
}



-- ========== Internal ==========

Object.ID_encoding = 10000



-- ========== General Functions ==========

Object.find = function(namespace, identifier)
    local id = Item.find(namespace, PREFIX..identifier)
    if id then return id + Object.ID_encoding end
    return nil
end


Object.spawn = function(object, x, y)
    local drop = Item.spawn_drop(object - Object.ID_encoding, x, y, -4)
    drop.RMT_Object = object

    -- Run all Init callbacks on the object
    for _, fn in ipairs(callbacks["Init"][object - Object.ID_encoding]) do
        fn(drop)
    end

    return drop
end


Object.get_collisions = function(instance, index)
    local cols = {}
    local bbox = callbacks["Hitbox"][instance.RMT_Object - Object.ID_encoding]

    for i = 0, gm.instance_number(index) - 1 do
        local inst = gm.instance_find(index, i)
        if Instance.exists(inst) then
            if not (inst.bbox_left > instance.x + bbox.right or inst.bbox_right < instance.x + bbox.left
                or inst.bbox_top > instance.y + bbox.bottom or inst.bbox_bottom < instance.y + bbox.top) then
                table.insert(cols, inst)
            end
        end
    end

    return cols, #cols > 0
end


Object.get_collision_box = function(instance)
    local hitbox = callbacks["Hitbox"][instance.RMT_Object - Object.ID_encoding]
    return {
        left    = hitbox.left   + instance.x,
        top     = hitbox.top    + instance.y,
        right   = hitbox.right  + instance.x,
        bottom  = hitbox.bottom + instance.y
    }
end



-- ========== Custom Object Functions ==========

Object.create = function(namespace, identifier)
    if Object.find(namespace, PREFIX..identifier) then return nil end

    -- Create object
    local object = Item.create(namespace, PREFIX..identifier, true)

    -- Create callback tables
    callbacks["Init"][object] = {}
    callbacks["Step"][object] = {}
    callbacks["Draw"][object] = {}
    callbacks["Hitbox"][object] = {
        left    = 0,
        top     = 0,
        right   = 0,
        bottom  = 0
    }

    -- Return object ID, with an encoding of +10000
    -- so that they remain separate from GM object_indexes
    return object + Object.ID_encoding
end


Object.set_hitbox = function(object, left, top, right, bottom)
    callbacks["Hitbox"][object - Object.ID_encoding] = {
        left    = left,
        top     = top,
        right   = right,
        bottom  = bottom
    }
end


Object.add_callback = function(object, callback, func)
    local object = object - Object.ID_encoding

    local array = gm.variable_global_get("class_item")[object + 1]

    if callback == "Init"
    or callback == "Step"
    or callback == "Draw"
    then
        table.insert(callbacks[callback][object], func)

    end
end



-- ========== Hooks ==========

gm.pre_code_execute(function(self, other, code, result, flags)
    if code.name:match("oCustomObject_pPickupItem_Step_0") and self.RMT_Object then
        for _, fn in ipairs(callbacks["Step"][self.RMT_Object - Object.ID_encoding]) do
            fn(self)
        end
        return false
    end
end)


gm.pre_code_execute(function(self, other, code, result, flags)
    if code.name:match("oCustomObject_pPickupItem_Draw_0") and self.RMT_Object then
        for _, fn in ipairs(callbacks["Draw"][self.RMT_Object - Object.ID_encoding]) do
            fn(self)
        end
        return false
    end
end)