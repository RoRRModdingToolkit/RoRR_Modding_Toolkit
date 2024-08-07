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



-- ========== General Functions ==========

Object.find = function(namespace, identifier)
    return Item.find(namespace, PREFIX..identifier)
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

    return object
end


Object.spawn = function(object, x, y)
    local drop = Item.spawn_drop(object, x, y, -4)
    drop.RMT_Object = object

    -- Run all Init callbacks on the object
    for _, fn in ipairs(callbacks["Init"][object]) do
        fn(drop)
    end

    return drop
end


Object.add_callback = function(object, callback, func)
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