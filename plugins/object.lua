-- Object

-- This is not a true implementation using a oCustomObject, but rather
-- creates a custom item and pretends that it is a new object via overrides.

Object = {}

local PREFIX = "[RMT_OBJ]"
local callbacks = {
    Init = {},
    Step = {},
    Draw = {}
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
    local object = object - Object.ID_encoding

    local drop = Item.spawn_drop(object, x, y, -4)
    drop.RMT_Object = object

    -- Run all Init callbacks on the object
    for _, fn in ipairs(callbacks["Init"][object]) do
        fn(drop)
    end

    return drop
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

    -- Return object ID, with an encoding of +10000
    -- so that they remain separate from GM object_indexes
    return object + Object.ID_encoding
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
        for _, fn in ipairs(callbacks["Step"][self.RMT_Object]) do
            fn(self)
        end
        return false
    end
end)


gm.pre_code_execute(function(self, other, code, result, flags)
    if code.name:match("oCustomObject_pPickupItem_Draw_0") and self.RMT_Object then
        for _, fn in ipairs(callbacks["Draw"][self.RMT_Object]) do
            fn(self)
        end
        return false
    end
end)