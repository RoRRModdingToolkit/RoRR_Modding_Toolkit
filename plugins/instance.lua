-- Instance

Instance = {}



-- ========== Tables ==========

Instance.chests = {
    gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5,
    gm.constants.oChestHealing1, gm.constants.oChestDamage1, gm.constants.oChestUtility1,
    gm.constants.oChestHealing2, gm.constants.oChestDamage2, gm.constants.oChestUtility2,
    gm.constants.oGunchest
}


Instance.shops = {
    gm.constants.oShop1, gm.constants.oShop2
}


Instance.teleporters = {
    gm.constants.oTeleporter, gm.constants.oTeleporterEpic
}


Instance.projectiles = {
    gm.constants.oJellyMissile,
    gm.constants.oWurmMissile,
    gm.constants.oShamBMissile,
    gm.constants.oTurtleMissile,
    gm.constants.oBrambleBullet,
    gm.constants.oLizardRSpear,
    gm.constants.oEfMissileEnemy,
    gm.constants.oSpiderBulletNoSync, gm.constants.oSpiderBullet,
    gm.constants.oGuardBulletNoSync, gm.constants.oGuardBullet,
    gm.constants.oBugBulletNoSync, gm.constants.oBugBullet,
    gm.constants.oScavengerBulletNoSync, gm.constants.oScavengerBullet
}



-- ========== Static Methods ==========

Instance.exists = function(inst)
    if type(inst) == "table" then inst = inst.value end
    return gm.instance_exists(inst) == 1.0
end


Instance.destroy = function(inst)
    if type(inst) == "table" then inst = inst.value end
    gm.instance_destroy(inst)
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
            return Instance.wrap(inst)
        end
    end

    -- None
    return Instance.wrap_invalid()
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
                table.insert(insts, Instance.wrap(inst))
            end

        else
            local count = Object.count(gm.constants.oCustomObject)
            for n = 0, count - 1 do
                local inst = gm.instance_find(gm.constants.oCustomObject, n)
                if inst.__object_index == obj then
                    table.insert(insts, Instance.wrap(inst))
                end
            end

        end
    end

    return insts, #insts > 0
end


Instance.wrap = function(inst)
    local abstraction = {
        value = inst
    }
    if inst.object_index == gm.constants.oP then
        setmetatable(abstraction, metatable_player)
    elseif gm.object_is_ancestor(inst.object_index, gm.constants.pActor) == 1.0 then
        setmetatable(abstraction, metatable_actor)
    else setmetatable(abstraction, metatable_instance)
    end
    return abstraction
end


Instance.wrap_invalid = function()
    local abstraction = {
        value = nil
    }
    setmetatable(abstraction, metatable_instance)
    return abstraction
end



-- ========== Instance Methods ==========

methods_instance = {

    -- Return true if instance exists
    exists = function(self)
        return gm.instance_exists(self.value) == 1.0
    end,


    destroy = function(self)
        gm.instance_destroy(self.value)
    end,


    -- Return true if the other instance is the same one
    same = function(self, other)
        if not self:exists() then return false end
        if type(other) == "table" then other = other.value end
        return self.value == other
    end,


    is_colliding = function(self, obj, x, y)
        if type(obj) == "table" then obj = obj.value end
        return self.value:place_meeting(x or self.x, y or self.y, obj) == 1.0
    end,


    get_collisions = function(self, obj)
        if type(obj) == "table" then obj = obj.value end

        local list = gm.ds_list_create()
        self.value:collision_rectangle_list(self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom, obj, false, true, list, false)

        local insts = {}
        local size = gm.ds_list_size(list)
        for i = 0, size - 1 do
            table.insert(insts, Instance.wrap(gm.ds_list_find_value(list, i)))
        end
        gm.ds_list_destroy(list)

        return insts, #insts
    end,


    draw_collision = function(self)
        local c = Color.WHITE
        gm.draw_rectangle_color(self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom, c, c, c, c, true)
    end

}



-- ========== Metatables ==========

metatable_instance_gs = {
    -- Getter
    __index = function(table, key)
        local var = rawget(table, "value")
        if var then return gm.variable_instance_get(var, key) end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local var = rawget(table, "value")
        if var then gm.variable_instance_set(var, key, value) end
    end
}


metatable_instance = {
    __index = function(table, key)
        -- Methods
        if methods_instance[key] then
            return methods_instance[key]
        end

        -- Pass to next metatable
        return metatable_instance_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end
}