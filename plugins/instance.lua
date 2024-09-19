-- Instance

Instance = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local instance_data = {}



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


Instance.worm_bodies = {
    gm.constants.oWormBody,
    gm.constants.oWurmBody
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
    if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

    for _, obj in ipairs(t) do
        obj = Wrap.unwrap(obj)

        local inst = gm.instance_find(obj, 0)
        if obj >= 800.0 then
            local count = Instance.count(gm.constants.oCustomObject)
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
    if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

    local insts = {}

    for _, obj in ipairs(t) do
        obj = Wrap.unwrap(obj)

        if obj < 800.0 then
            local count = Instance.count(obj)
            for n = 0, count - 1 do
                local inst = gm.instance_find(obj, n)
                table.insert(insts, Instance.wrap(inst))
            end

        else
            local count = Instance.count(gm.constants.oCustomObject)
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


Instance.count = function(obj)
    return gm._mod_instance_number(Wrap.unwrap(obj))
end


Instance.wrap = function(inst)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Instance",
        value = inst
    }
    if inst.object_index == gm.constants.oP then
        setmetatable(abstraction, metatable_player)
        abstraction_data[abstraction].RMT_object = "Player"
    elseif gm.object_is_ancestor(inst.object_index, gm.constants.pActor) == 1.0 then
        setmetatable(abstraction, metatable_actor)
        abstraction_data[abstraction].RMT_object = "Actor"
    else setmetatable(abstraction, metatable_instance)
    end
    return abstraction
end


Instance.wrap_invalid = function()
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Instance",
        value = -4
    }
    setmetatable(abstraction, metatable_instance)
    return abstraction
end



-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
        return gm.instance_exists(self.value) == 1.0
    end,


    destroy = function(self)
        if not self:exists() then return end

        gm.instance_destroy(self.value)
        abstraction_data[self].value = -4
    end,


    same = function(self, other)
        if not self:exists() then return false end

        other = Wrap.unwrap(other)
        return self.value == other
    end,


    get_data = function(self, subtable, mod_id)
        subtable = subtable or "main"

        if not mod_id then
            -- Find ID of mod that called this method
            mod_id = "main"
            local src = debug.getinfo(2, "S").source
            local split = Array.wrap(gm.string_split(src, "\\"))
            for i = 1, #split do
                if split[i] == "plugins" and i < #split then
                    mod_id = split[i + 1]
                    break
                end
            end
        end

        -- Create data table if it doesn't already exist and return it
        if not instance_data[self.value.id] then instance_data[self.value.id] = {} end
        if not instance_data[self.value.id][mod_id] then instance_data[self.value.id][mod_id] = {} end
        if not instance_data[self.value.id][mod_id][subtable] then instance_data[self.value.id][mod_id][subtable] = {} end
        return instance_data[self.value.id][mod_id][subtable]
    end,


    is_colliding = function(self, obj, x, y)
        if not self:exists() then return false end

        obj = Wrap.unwrap(obj)
        return self.value:place_meeting(x or self.x, y or self.y, obj) == 1.0
    end,


    get_collisions = function(self, ...)
        if not self:exists() then return {}, 0 end

        local t = {...}
        if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

        local insts = {}

        for i, obj in ipairs(t) do
            obj = Wrap.unwrap(obj)

            local list = List.new()
            self.value:collision_rectangle_list(self.bbox_left, self.bbox_top, self.bbox_right, self.bbox_bottom, obj, false, true, list.value, false)

            for _, inst in ipairs(list) do
                table.insert(insts, inst)
            end
            list:destroy()
        end

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
        return Wrap.wrap(gm.variable_instance_get(table.value, key))
    end,


    -- Setter
    __newindex = function(table, key, value)            
        value = Wrap.unwrap(value)
        gm.variable_instance_set(table.value, key, value)

        -- Automatically set "shield" alongside "maxshield"
        -- to prevent the shield regen sfx from playing
        if key == "maxshield" and (gm.variable_global_get("_current_frame") >= table.in_danger_last_frame) then
            gm.variable_instance_set(table.value, "shield", value)
        end
    end
}


metatable_instance = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_instance[key] then
            return methods_instance[key]
        end

        -- Pass to next metatable
        return metatable_instance_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_instance_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

-- Doesn't work??
-- gm.post_script_hook(gm.constants.instance_destroy, function(self, other, result, args)
--     Helper.log_hook(self, other, result, args)
--     -- instance_data[self.value] = nil
-- end)


-- Find out what is called when an instance is destroyed and hook that instead
-- because this is running every frame
gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    for k, v in pairs(instance_data) do
        if not Instance.exists(k) then
            instance_data[k] = nil
        end
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    if instance_data[args[1].value.id] then
        instance_data[args[2].value.id] = {}
        for k, v in pairs(instance_data[args[1].value.id]) do
            instance_data[args[2].value.id][k] = instance_data[args[1].value.id][k]
        end
        instance_data[args[1].value.id] = nil
    end
end)