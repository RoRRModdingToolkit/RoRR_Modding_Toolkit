-- Instance

Instance = Proxy.new()

local callbacks = {}
instance_valid_callbacks = {
    onDraw                  = true,     -- For non-actors

    onPreStep               = true,
    onPostStep              = true,
    onPreDraw               = true,
    onPostDraw              = true,
    onStatRecalc            = true,
    onPostStatRecalc        = true,
    onAttackCreate          = true,
    onAttackCreateProc      = true,
    onAttackHit             = true,
    onAttackHandleEnd       = true,
    onAttackHandleEndProc   = true,
    onHitProc               = true,
    onKillProc              = true,
    onDamagedProc           = true,
    onDamageBlocked         = true,
    onHeal                  = true,
    onShieldBreak           = true,
    onInteractableActivate  = true,
    onPickupCollected       = true,
    onPrimaryUse            = true,
    onSecondaryUse          = true,
    onUtilityUse            = true,
    onSpecialUse            = true,
    onSkillUse              = true,
    onEquipmentUse          = true,
    onStageStart            = true
}

local instance_data = {}



-- ========== Tables ==========

Instance.chests = Proxy.new({
    gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5,
    gm.constants.oChestHealing1, gm.constants.oChestDamage1, gm.constants.oChestUtility1,
    gm.constants.oChestHealing2, gm.constants.oChestDamage2, gm.constants.oChestUtility2,
    gm.constants.oGunchest
}):lock()


Instance.shops = Proxy.new({
    gm.constants.oShop1, gm.constants.oShop2
}):lock()


Instance.teleporters = Proxy.new({
    gm.constants.oTeleporter, gm.constants.oTeleporterEpic
}):lock()


Instance.projectiles = Proxy.new({
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
}):lock()


Instance.worm_bodies = Proxy.new({
    gm.constants.oWormBody,
    gm.constants.oWurmBody
}):lock()



-- ========== Static Methods ==========

Instance.exists = function(value)
    value = Wrap.unwrap(value)
    if type(value) == "string" then return false end
    return gm.instance_exists(value) == 1.0
end


Instance.is = function(value)
    value = Wrap.unwrap(value)
    return gm.typeof(value) == "struct"
       and gm.instance_exists(value) == 1.0
       and gm.object_exists(value) == 0.0
end


Instance.find = function(...)
    local t = {...}
    if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

    for _, obj in ipairs(t) do
        obj = Wrap.unwrap(obj)

        local inst = gm.instance_find(obj, 0)
        if obj >= 800.0 then
            local customs = {
                gm.constants.oCustomObject,
                gm.constants.oCustomObject_pPickupItem,
                gm.constants.oCustomObject_pPickupEquipment,
                gm.constants.oCustomObject_pEnemyClassic,
                gm.constants.oCustomObject_pEnemyFlying,
                gm.constants.oCustomObject_pBossClassic,
                gm.constants.oCustomObject_pBoss,
                gm.constants.oCustomObject_pInteractable,
                gm.constants.oCustomObject_pInteractableChest,
                gm.constants.oCustomObject_pInteractableDrone,
                gm.constants.oCustomObject_pInteractableCrate,
                gm.constants.oCustomObject_pMapObjects,
                gm.constants.oCustomObject_pNPC,
                gm.constants.oCustomObject_pDrone
            }
            local _exit = false
            for _, custom in ipairs(customs) do
                local count = Instance.count(custom)
                for i = 0, count - 1 do
                    local ins = gm.instance_find(custom, i)
                    if ins.__object_index == obj then
                        inst = ins
                        _exit = true
                        break
                    end
                end
                if _exit then break end
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
            local customs = {
                gm.constants.oCustomObject,
                gm.constants.oCustomObject_pPickupItem,
                gm.constants.oCustomObject_pPickupEquipment,
                gm.constants.oCustomObject_pEnemyClassic,
                gm.constants.oCustomObject_pEnemyFlying,
                gm.constants.oCustomObject_pBossClassic,
                gm.constants.oCustomObject_pBoss,
                gm.constants.oCustomObject_pInteractable,
                gm.constants.oCustomObject_pInteractableChest,
                gm.constants.oCustomObject_pInteractableDrone,
                gm.constants.oCustomObject_pInteractableCrate,
                gm.constants.oCustomObject_pMapObjects,
                gm.constants.oCustomObject_pNPC,
                gm.constants.oCustomObject_pDrone
            }
            for _, custom in ipairs(customs) do
                local count = Instance.count(custom)
                for n = 0, count - 1 do
                    local inst = gm.instance_find(custom, n)
                    if inst.__object_index == obj then
                        table.insert(insts, Instance.wrap(inst))
                    end
                end
            end

        end
    end

    return insts, #insts > 0
end


Instance.count = function(obj)
    return GM._mod_instance_number(obj)
end


Instance.get_CInstance = function(id)
    local inst = gm.CInstance.instance_id_to_CInstance[id]
    if inst then return Instance.wrap(inst) end
    return Instance.wrap_invalid()
end


Instance.wrap = function(value)
    value = Wrap.unwrap(value)
    if type(value) == "number" then value = Instance.get_CInstance(value).value end
    if not Instance.exists(value) then return Instance.wrap_invalid() end

    local RMT_object = "Instance"
    local mt = metatable_instance
    local lt = lock_table_instance

    if value.object_index == gm.constants.oCustomObject_pInteractable then
        RMT_object = "Interactable Instance"
        mt = metatable_interactable_instance
        lt = lock_table_interactable_instance
    elseif value.object_index == gm.constants.oP then
        RMT_object = "Player"
        mt = metatable_player
        lt = lock_table_player
    elseif gm.object_is_ancestor(value.object_index, gm.constants.pActor) == 1.0 then
        RMT_object = "Actor"
        mt = metatable_actor
        lt = lock_table_actor
    end

    return make_wrapper(value, RMT_object, mt, lt)
end


Instance.wrap_invalid = function()
    return make_wrapper(-4, "Instance", metatable_instance, lock_table_instance)
end



-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
        return Instance.exists(self.value)
    end,


    destroy = function(self)
        if not self:exists() then return end

        instance_data[self.value.id] = nil
        gm.instance_destroy(self.value)
    end,


    same = function(self, other)
        if not self:exists() then return false end
        return self.value == Wrap.unwrap(other)
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
    end,


    add_callback = function(self, callback, id, func, skill)   
        if callback == "onSkillUse" then
            skill = Wrap.unwrap(skill)
            if not callbacks[self.value.id] then
                callbacks[self.value.id] = {}
                callbacks[self.value.id]["CInstance"] = self.value
            end
            if not callbacks[self.value.id][callback] then callbacks[self.value.id][callback] = {} end
            if not callbacks[self.value.id][callback][skill] then callbacks[self.value.id][callback][skill] = {} end
            if not callbacks[self.value.id][callback][skill][id] then callbacks[self.value.id][callback][skill][id] = func
            else log.error("Callback ID already exists", 2)
            end
    
        elseif instance_valid_callbacks[callback] then
            if not callbacks[self.value.id] then
                callbacks[self.value.id] = {}
                callbacks[self.value.id]["CInstance"] = self.value
            end
            if not callbacks[self.value.id][callback] then callbacks[self.value.id][callback] = {} end
            if not callbacks[self.value.id][callback][id] then callbacks[self.value.id][callback][id] = func
            else log.error("Callback ID already exists", 2)
            end
    
        else log.error("Invalid callback name", 2)
        end
    end,
    
    
    remove_callback = function(self, id)
        if not callbacks[self.value.id] then return end

        local c_table = callbacks[self.value.id]["onSkillUse"]
        if c_table then
            for _, skill_table in pairs(c_table) do
                skill_table[id] = nil
            end
        end

        for callback, _ in pairs(instance_valid_callbacks) do
            local c_table = callbacks[self.value.id][callback]
            if c_table then c_table[id] = nil end
        end
    end,
    
    
    callback_exists = function(self, id)
        if not callbacks[self.value.id] then return false end

        local c_table = callbacks[self.value.id]["onSkillUse"]
        if c_table then
            for _, skill_table in pairs(c_table) do
                if skill_table[id] then return true end
            end
        end

        for callback, _ in pairs(instance_valid_callbacks) do
            local c_table = callbacks[self.value.id][callback]
            if c_table and c_table[id] then return true end
        end
    
        return false
    end

}

-- Callbacks
for c, _ in pairs(instance_valid_callbacks) do
    methods_instance[c] = function(self, id, func, skill)
        self:add_callback(c, id, func, skill)
    end
end

lock_table_instance = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance))})



-- ========== Metatables ==========

metatable_instance_gs = {
    -- Getter
    __index = function(table, key)
        if key == "id" then return table.value.id end
        local val = gm.variable_instance_get(table.value, key)
        if key == "attack_info" then return Attack_Info.wrap(val) end
        return Wrap.wrap(val)
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
        -- Methods
        if methods_instance[key] then
            return methods_instance[key]
        end

        -- Pass to next metatable
        return metatable_instance_gs.__index(table, key)
    end,


    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end,

    
    __metatable = "instance"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    -- On room change, remove non-existent instances
    -- from instance_data and clear callbacks
    for k, v in pairs(instance_data) do
        if not Instance.exists(k) then
            instance_data[k] = nil
        end
    end
    for k, v in pairs(callbacks) do
        if not Instance.exists(k) then
            callbacks[k] = nil
        end
    end
end)


gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    -- Remove instance_data and callbacks on non-player kill
    if self.object_index ~= gm.constants.oP then
        instance_data[self.id] = nil
        callbacks[self.id] = nil
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    -- Move instance_data and callbacks to new instance
    if instance_data[args[1].value.id] then
        instance_data[args[2].value.id] = instance_data[args[1].value.id]
        instance_data[args[1].value.id] = nil
    end
    if callbacks[args[1].value.id] then
        callbacks[args[2].value.id] = callbacks[args[1].value.id]
        callbacks[args[1].value.id] = nil
    end
end)



-- ========== Callback Hooks ==========

gm.pre_script_hook(gm.constants.draw_hud, function(self, other, result, args)
    -- Non-actor exclusive
    for inst_id, c_tables in pairs(callbacks) do
        if c_tables["onDraw"] then
            local inst = Instance.wrap(inst_id)
            if inst:exists() then
                for _, fn in pairs(c_tables["onDraw"]) do
                    fn(inst)
                end
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not callbacks[self.id] then return end

    local actor = Instance.wrap(self)
    local actorData = actor:get_data("instance")

    if callbacks[self.id]["onPreStep"] then
        for _, fn in pairs(callbacks[self.id]["onPreStep"]) do
            fn(actor)
        end
    end

    if not callbacks[self.id]["onShieldBreak"] then return end

    if self.shield and self.shield > 0.0 then actorData.has_shield = true end
    if actorData.has_shield and self.shield <= 0.0 then
        actorData.has_shield = nil

        for _, fn in pairs(callbacks[self.id]["onShieldBreak"]) do
            fn(actor)
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not callbacks[self.id] or not callbacks[self.id]["onPostStep"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks[self.id]["onPostStep"]) do
        fn(actor)
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks[self.id] or not callbacks[self.id]["onPreDraw"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks[self.id]["onPreDraw"]) do
        fn(actor)
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not callbacks[self.id] or not callbacks[self.id]["onPostDraw"] then return end

    local actor = Instance.wrap(self)

    for _, fn in pairs(callbacks[self.id]["onPostDraw"]) do
        fn(actor)
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    local actorData = actor:get_data()
    actorData.post_stat_recalc = true

    if not callbacks[self.id] or not callbacks[self.id]["onStatRecalc"] then return end

    for _, fn in pairs(callbacks[self.id]["onStatRecalc"]) do
        fn(actor)
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if not callbacks[self.id] then return end

    local callback = {
        "onPrimaryUse",
        "onSecondaryUse",
        "onUtilityUse",
        "onSpecialUse"
    }
    callback = callback[args[1].value + 1]

    local actor = Instance.wrap(self)
    local active_skill = actor:get_active_skill(args[1].value)

    if callbacks[self.id][callback] then
        for _, fn in pairs(callbacks[self.id][callback]) do
            fn(actor, active_skill)
        end
    end
    
    if not callbacks[self.id]["onSkillUse"] then return end

    for skill_id, skill in pairs(callbacks[self.id]["onSkillUse"]) do
        if active_skill.skill_id == skill_id then
            for _, fn in pairs(skill) do
                fn(actor, active_skill)
            end
        end
    end
end)


gm.post_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    local actor = Instance.wrap(args[1].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onHeal"] then return end

    local heal_amount = args[2].value

    for _, fn in pairs(callbacks[actor.id]["onHeal"]) do
        fn(actor, heal_amount)
    end
end)



-- ========== Callbacks ==========

function inst_onPostStatRecalc(actor)
    if not callbacks[actor.id] or not callbacks[actor.id]["onPostStatRecalc"] then return end
    
    for _, fn in pairs(callbacks[actor.id]["onPostStatRecalc"]) do
        fn(actor)
    end
end


Callback.add("preStep", "RMT-Instance.preStep", function(self, other, result, args)
    -- Non-actor exclusive
    for inst_id, c_tables in pairs(callbacks) do
        if c_tables["onPreStep"] then
            local inst = Instance.wrap(inst_id)
            if inst:exists() and gm.object_is_ancestor(inst.value.object_index, gm.constants.pActor) == 0.0 then
                for _, fn in pairs(c_tables["onPreStep"]) do
                    fn(inst)
                end
            end
        end
    end
end)


Callback.add("postStep", "RMT-Instance.postStep", function(self, other, result, args)
    -- Non-actor exclusive
    for inst_id, c_tables in pairs(callbacks) do
        if c_tables["onPostStep"] then
            local inst = Instance.wrap(inst_id)
            if inst:exists() and gm.object_is_ancestor(inst.value.object_index, gm.constants.pActor) == 0.0 then
                for _, fn in pairs(c_tables["onPostStep"]) do
                    fn(inst)
                end
            end
        end
    end
end)


Callback.add("onAttackCreate", "RMT-Instance.onAttackCreate", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent
    
    if not Instance.exists(actor) then return end
    if not callbacks[actor.id] or not callbacks[actor.id]["onAttackCreate"] then return end

    actor = Instance.wrap(actor)

    if callbacks[actor.id]["onAttackCreate"] then
        for _, fn in pairs(callbacks[actor.id]["onAttackCreate"]) do
            fn(actor, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks[actor.id]["onAttackCreateProc"] then
        for _, fn in pairs(callbacks[actor.id]["onAttackCreateProc"]) do
            fn(actor, attack_info)
        end
    end
end)


Callback.add("onAttackHit", "RMT-Instance.onAttackHit", function(self, other, result, args)
    local hit_info = Hit_Info.wrap(args[2].value)
    local actor = hit_info.inflictor
    
    if not Instance.exists(actor) then return end
    if not callbacks[actor.id] or not callbacks[actor.id]["onAttackHit"] then return end

    actor = Instance.wrap(actor)

    for _, fn in pairs(callbacks[actor.id]["onAttackHit"]) do
        fn(actor, hit_info)
    end
end)


Callback.add("onAttackHandleEnd", "RMT-Instance.onAttackHandleEnd", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local actor = attack_info.parent
    
    if not Instance.exists(actor) then return end
    if not callbacks[actor.id] then return end

    actor = Instance.wrap(actor)

    if callbacks[actor.id]["onAttackHandleEnd"] then
        for _, fn in pairs(callbacks[actor.id]["onAttackHandleEnd"]) do
            fn(actor, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks[actor.id]["onAttackHandleEndProc"] then
        for _, fn in pairs(callbacks[actor.id]["onAttackHandleEndProc"]) do
            fn(actor, attack_info)
        end
    end
end)


Callback.add("onHitProc", "RMT-Instance.onHitProc", function(self, other, result, args)     -- Runs before onAttackHit
    local actor = Instance.wrap(args[2].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onHitProc"] then return end

    local victim = Instance.wrap(args[3].value)
    local hit_info = Hit_Info.wrap(args[4].value)

    for _, fn in pairs(callbacks[actor.id]["onHitProc"]) do
        fn(actor, victim, hit_info)
    end
end)


Callback.add("onKillProc", "RMT-Instance.onKillProc", function(self, other, result, args)
    local actor = Instance.wrap(args[3].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onKillProc"] then return end

    local victim = Instance.wrap(args[2].value)

    for _, fn in pairs(callbacks[actor.id]["onKillProc"]) do
        fn(actor, victim)
    end
end)


Callback.add("onDamagedProc", "RMT-Instance.onDamagedProc", function(self, other, result, args)
    local actor = Instance.wrap(args[2].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onDamagedProc"] then return end

    local hit_info = Hit_Info.wrap(args[3].value)
    local attacker = Instance.wrap(hit_info.inflictor)

    for _, fn in pairs(callbacks[actor.id]["onDamagedProc"]) do
        fn(actor, attacker, hit_info)
    end
end)


Callback.add("onDamageBlocked", "RMT-Instance.onDamageBlocked", function(self, other, result, args)
    local actor = Instance.wrap(args[2].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onDamageBlocked"] then return end

    local damage = args[4].value

    for _, fn in pairs(callbacks[actor.id]["onDamageBlocked"]) do
        fn(actor, damage)
    end
end)


Callback.add("onInteractableActivate", "RMT-Instance.onInteractableActivate", function(self, other, result, args)
    local actor = Instance.wrap(args[3].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onInteractableActivate"] then return end

    local interactable = Instance.wrap(args[2].value)

    for _, fn in pairs(callbacks[actor.id]["onInteractableActivate"]) do
        fn(actor, interactable)
    end
end)


Callback.add("onPickupCollected", "RMT-Instance.onPickupCollected", function(self, other, result, args)
    local actor = Instance.wrap(args[3].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onPickupCollected"] then return end

    local pickup_object = Instance.wrap(args[2].value)  -- Will be oCustomObject_pPickupItem/Equipment for all custom items/equipment

    for _, fn in pairs(callbacks[actor.id]["onPickupCollected"]) do
        fn(actor, pickup_object)
    end
end)


Callback.add("onEquipmentUse", "RMT-Instance.onEquipmentUse", function(self, other, result, args)
    local actor = Instance.wrap(args[2].value)
    if not callbacks[actor.id] or not callbacks[actor.id]["onEquipmentUse"] then return end

    local equipment = Equipment.wrap(args[3].value)
    local direction = args[5].value

    for _, fn in pairs(callbacks[actor.id]["onEquipmentUse"]) do
        fn(actor, equipment, direction)
    end
end)


Callback.add("onStageStart", "RMT-Instance.onStageStart", function(self, other, result, args)
    local actors = Instance.find_all(gm.constants.pActor)
    for _, actor in ipairs(actors) do
        if callbacks[actor.id] and callbacks[actor.id]["onStageStart"] then
            for __, fn in pairs(callbacks[actor.id]["onStageStart"]) do
                fn(actor)
            end
        end
    end
end)



-- ========== Initialize ==========

initialize_instance = function()
    lock_table_actor = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_actor))})
    lock_table_player = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_actor)), table.unpack(Helper.table_get_keys(methods_player))})
    lock_table_interactable_instance = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_interactable_instance))})
    gm_add_instance_methods(methods_instance)
end



return Instance