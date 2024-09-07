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
    inst = Wrap.unwrap(inst)
    return gm.instance_exists(inst) == 1.0
end


Instance.destroy = function(inst)
    inst = Wrap.unwrap(inst)
    gm.instance_destroy(inst)
end


Instance.find = function(...)
    local t = {...}
    if type(t[1]) == "table" and (not t[1].RMT_wrapper) then t = t[1] end

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
    if type(t[1]) == "table" and (not t[1].RMT_wrapper) then t = t[1] end

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
        RMT_wrapper = "Instance",
        value = inst
    }
    if inst.object_index == gm.constants.oP then
        setmetatable(abstraction, metatable_player)
        abstraction.RMT_wrapper = "Player"
    elseif gm.object_is_ancestor(inst.object_index, gm.constants.pActor) == 1.0 then
        setmetatable(abstraction, metatable_actor)
        abstraction.RMT_wrapper = "Actor"
    else setmetatable(abstraction, metatable_instance)
    end
    return abstraction
end


Instance.wrap_invalid = function()
    local abstraction = {
        value = -4
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
        if not self:exists() then return end

        gm.instance_destroy(self.value)
        self.value = -4
    end,


    -- Return true if the other instance is the same one
    same = function(self, other)
        if not self:exists() then return false end

        other = Wrap.unwrap(other)
        return self.value == other
    end,


    is_colliding = function(self, obj, x, y)
        if not self:exists() then return false end

        obj = Wrap.unwrap(obj)
        return self.value:place_meeting(x or self.x, y or self.y, obj) == 1.0
    end,


    get_collisions = function(self, obj)
        if not self:exists() then return {}, 0 end

        obj = Wrap.unwrap(obj)

        local list = List.new()
        self.value:collision_rectangle_list(self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom, obj, false, true, list.value, false)

        local insts = {}
        for _, inst in ipairs(list) do
            table.insert(insts, inst)
        end
        list:destroy()

        return insts, #insts
    end,


    draw_collision = function(self)
        if not self:exists() then return end

        local c = Color.WHITE
        gm.draw_rectangle_color(self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom, c, c, c, c, true)
    end

}



-- ========== Metatables ==========

metatable_instance_gs = {
    -- Getter
    __index = function(table, key)
        local var = rawget(table, "value")
        if var then
            local v = gm.variable_instance_get(var, key)
            return Wrap.wrap(v)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local var = rawget(table, "value")
        if var then
            gm.variable_instance_set(var, key, Wrap.unwrap(value))
        end
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