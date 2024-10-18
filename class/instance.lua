-- Instance

Instance = Proxy.new()

local methods_instance_lock = {}

local instance_data = {}

local callbacks = {}
local other_callbacks = {
    "onPreStep",
    "onPostStep",
    "onDraw",
    
    "onStatRecalc",
    "onPostStatRecalc",
    "onBasicUse",
    "onAttack",
    "onAttackAll",
    "onPostAttack",
    "onPostAttackAll",
    "onHit",
    "onHitAll",
    "onKill",
    "onDamaged",
    "onDamageBlocked",
    "onHeal",
    "onShieldBreak",
    "onInteract",
    "onEquipmentUse"
}



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

Instance.exists = function(inst)
    return GM.instance_exists(inst) == 1.0
end


Instance.is = function(value)
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


Instance.wrap = function(value)
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
        return gm.instance_exists(self.value) == 1.0
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


    add_callback = function(self, callback, id, func, skill, all_damage)
        if all_damage then callback = callback.."All" end
    
        if callback == "onSkillUse" then
            skill = Wrap.unwrap(skill)
            if not callbacks[self.value.id] then
                callbacks[self.value.id] = {}
                callbacks[self.value.id]["CInstance"] = self.value
            end
            if not callbacks[self.value.id][callback] then callbacks[self.value.id][callback] = {} end
            if not callbacks[self.value.id][callback][skill] then callbacks[self.value.id][callback][skill] = {} end
            if not callbacks[self.value.id][callback][skill][id] then
                callbacks[self.value.id][callback][skill][id] = func
            else log.error("Callback ID already exists", 2)
            end
    
        elseif Helper.table_has(other_callbacks, callback) then
            if not callbacks[self.value.id] then
                callbacks[self.value.id] = {}
                callbacks[self.value.id]["CInstance"] = self.value
            end
            if not callbacks[self.value.id][callback] then callbacks[self.value.id][callback] = {} end
            if not callbacks[self.value.id][callback][id] then
                callbacks[self.value.id][callback][id] = func
            else log.error("Callback ID already exists", 2)
            end
    
        else log.error("Invalid callback name", 2)
    
        end
    end,
    
    
    remove_callback = function(self, id)
        if not callbacks[self.value.id] then return end

        local c_table = callbacks[self.value.id]["onSkillUse"]
        if c_table then
            for s, id_table in pairs(c_table) do
                for i, __ in pairs(id_table) do
                    if i == id then
                        id_table[i] = nil
                    end
                end
            end
        end
    
        for _, c in ipairs(other_callbacks) do
            local c_table = callbacks[self.value.id][c]
            if c_table then
                for i, __ in pairs(c_table) do
                    if i == id then
                        c_table[i] = nil
                    end
                end
            end
        end
    end,
    
    
    callback_exists = function(self, id)
        if not callbacks[self.value.id] then return false end

        local c_table = callbacks[self.value.id]["onSkillUse"]
        if c_table then
            for s, id_table in pairs(c_table) do
                for i, __ in pairs(id_table) do
                    if i == id then return true end
                end
            end
        end
    
        for _, c in ipairs(other_callbacks) do
            local c_table = callbacks[self.value.id][c]
            if c_table then
                for i, __ in pairs(c_table) do
                    if i == id then return true end
                end
            end
        end
    
        return false
    end,


    -- Callbacks
    onPreStep           = function(self, id, func) self:add_callback("onPreStep", id, func) end,
    onPostStep          = function(self, id, func) self:add_callback("onPostStep", id, func) end,
    onDraw              = function(self, id, func) self:add_callback("onDraw", id, func) end,
    
    onStatRecalc        = function(self, id, func) self:add_callback("onStatRecalc", id, func) end,
    onPostStatRecalc    = function(self, id, func) self:add_callback("onPostStatRecalc", id, func) end,
    onSkillUse          = function(self, id, func, skill) self:add_callback("onSkillUse", id, func, skill) end,
    onBasicUse          = function(self, id, func) self:add_callback("onBasicUse", id, func) end,
    onAttack            = function(self, id, func, all_damage) self:add_callback("onAttack", id, func, nil, all_damage) end,
    onPostAttack        = function(self, id, func, all_damage) self:add_callback("onPostAttack", id, func, nil, all_damage) end,
    onHit               = function(self, id, func, all_damage) self:add_callback("onHit", id, func, nil, all_damage) end,
    onKill              = function(self, id, func) self:add_callback("onKill", id, func) end,
    onDamaged           = function(self, id, func) self:add_callback("onDamaged", id, func) end,
    onDamageBlocked     = function(self, id, func) self:add_callback("onDamageBlocked", id, func) end,
    onHeal              = function(self, id, func) self:add_callback("onHeal", id, func) end,
    onShieldBreak       = function(self, id, func) self:add_callback("onShieldBreak", id, func) end,
    onInteract          = function(self, id, func) self:add_callback("onInteract", id, func) end,
    onEquipmentUse      = function(self, id, func) self:add_callback("onEquipmentUse", id, func) end

}
lock_table_instance = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance))})



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

-- Remove non-existent instances from instance_data on room change
gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
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
    if self.object_index ~= gm.constants.oP then
        instance_data[self.id] = nil
        callbacks[self.id] = nil
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    -- if instance_data[args[1].value.id] then
    --     instance_data[args[2].value.id] = {}
    --     for k, v in pairs(instance_data[args[1].value.id]) do
    --         instance_data[args[2].value.id][k] = instance_data[args[1].value.id][k]
    --     end
    --     instance_data[args[1].value.id] = nil
    -- end

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

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["onStatRecalc"] then
        for k, fn in pairs(callbacks[self.id]["onStatRecalc"]) do
            fn(Instance.wrap(self))   -- Actor
        end
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if callbacks[self.id] then
        if callbacks[self.id]["onSkillUse"] then
            for id, skill in pairs(callbacks[self.id]["onSkillUse"]) do
                if gm.array_get(self.skills, args[1].value).active_skill.skill_id == id then
                    for k, fn in pairs(skill) do
                        fn(Instance.wrap(self))   -- Actor
                    end
                end
            end
        end

        if args[1].value ~= 0.0 or gm.array_get(self.skills, 0).active_skill.skill_id == 70.0 then return true end
        if callbacks[self.id]["onBasicUse"] then
            for k, fn in pairs(callbacks[self.id]["onBasicUse"]) do
                fn(Instance.wrap(self))   -- Actor
            end
        end
    end
end)


gm.post_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    local actor = args[1].value
    if callbacks[actor.id] and callbacks[actor.id]["onHeal"] then
        for k, fn in pairs(callbacks[actor.id]["onHeal"]) do
            fn(Instance.wrap(actor), args[2].value)   -- Actor, Heal amount
        end
    end
end)



-- ========== Callbacks ==========

function inst_onPostStatRecalc(actor)
    if callbacks[actor.id] and callbacks[actor.id]["onPostStatRecalc"] then
        for k, fn in pairs(callbacks[actor.id]["onPostStatRecalc"]) do
            fn(actor)   -- Actor
        end
    end
end


local function inst_onAttack(self, other, result, args)
    if not args[2].value.proc then return end
    if callbacks[self.id] and callbacks[self.id]["onAttack"] then
        for k, fn in pairs(callbacks[self.id]["onAttack"]) do
            fn(Instance.wrap(self), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function inst_onAttackAll(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["onAttackAll"] then
        for k, fn in pairs(callbacks[self.id]["onAttackAll"]) do
            fn(Instance.wrap(self), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function inst_onPostAttack(self, other, result, args)
    local parent = args[2].value.parent
    if not args[2].value.proc or not Instance.exists(parent) then return end
    if callbacks[parent.id] and callbacks[parent.id]["onPostAttack"] then
        for k, fn in pairs(callbacks[parent.id]["onPostAttack"]) do
            fn(Instance.wrap(parent), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function inst_onPostAttackAll(self, other, result, args)
    local parent = args[2].value.parent
    if not Instance.exists(parent) then return end
    if callbacks[parent.id] and callbacks[parent.id]["onPostAttackAll"] then
        for k, fn in pairs(callbacks[parent.id]["onPostAttackAll"]) do
            fn(Instance.wrap(parent), Damager.wrap(args[2].value))    -- Actor, Damager attack_info
        end
    end
end


local function inst_onHit(self, other, result, args)
    if not self.attack_info then return end
    if not self.attack_info.proc then return end
    local actor = args[2].value
    if callbacks[actor.id] and callbacks[actor.id]["onHit"] then
        for k, fn in pairs(callbacks[actor.id]["onHit"]) do
            fn(Instance.wrap(actor), Instance.wrap(args[3].value), Damager.wrap(self.attack_info)) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function inst_onHitAll(self, other, result, args)
    local attack = args[2].value
    local actor = attack.inflictor
    if not Instance.exists(actor) then return end
    if callbacks[actor.id] and callbacks[actor.id]["onHitAll"] then
        for k, fn in pairs(callbacks[actor.id]["onHitAll"]) do
            fn(Instance.wrap(actor), Instance.wrap(attack.target_true), Damager.wrap(attack.attack_info)) -- Attacker, Victim, Damager attack_info
        end
    end
end


local function inst_onKill(self, other, result, args)
    local actor = args[3].value
    if callbacks[actor.id] and callbacks[actor.id]["onKill"] then
        for k, fn in pairs(callbacks[actor.id]["onKill"]) do
            fn(Instance.wrap(actor), Instance.wrap(args[2].value))   -- Attacker, Victim
        end
    end
end


local function inst_onDamaged(self, other, result, args)
    if not args[3].value.attack_info then return end
    local actor = args[2].value
    if callbacks[actor.id] and callbacks[actor.id]["onDamaged"] then
        for k, fn in pairs(callbacks[actor.id]["onDamaged"]) do
            fn(Instance.wrap(actor), Damager.wrap(args[3].value.attack_info))   -- Actor, Damager attack_info
        end
    end
end


local function inst_onDamageBlocked(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["onDamageBlocked"] then
        for k, fn in pairs(callbacks[self.id]["onDamageBlocked"]) do
            fn(Instance.wrap(self), Damager.wrap(other.attack_info))   -- Actor, Damager attack_info
        end
    end
end


local function inst_onInteract(self, other, result, args)
    local actor = args[3].value
    if callbacks[actor.id] and callbacks[actor.id]["onInteract"] then
        for k, fn in pairs(callbacks[actor.id]["onInteract"]) do
            fn(Instance.wrap(actor), Instance.wrap(args[2].value))   -- Actor, Interactable
        end
    end
end


local function inst_onEquipmentUse(self, other, result, args)
    local actor = args[2].value
    if callbacks[actor.id] and callbacks[actor.id]["onEquipmentUse"] then
        for k, fn in pairs(callbacks[actor.id]["onEquipmentUse"]) do
            fn(Instance.wrap(actor), Equipment.wrap(args[3].value))   -- Actor, Equipment ID
        end
    end
end


local function inst_onPreStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    for id, c_table in pairs(callbacks) do
        local inst = c_table["CInstance"]
        if Instance.exists(inst) then

            if c_table["onPreStep"] then
                for k, fn in pairs(c_table["onPreStep"]) do
                    fn(Instance.wrap(inst))   -- Actor
                end
            end

            if inst.shield and inst.shield > 0.0 then inst.RMT_has_shield_inst = true end
            if inst.RMT_has_shield_inst and inst.shield <= 0.0 then
                inst.RMT_has_shield_inst = nil
                if c_table["onShieldBreak"] then
                    for k, fn in pairs(c_table["onShieldBreak"]) do
                        fn(Instance.wrap(inst))   -- Instance
                    end
                end
            end

        else callbacks[id] = nil
        end
    end
end


local function inst_onPostStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    for id, c_table in pairs(callbacks) do
        local inst = c_table["CInstance"]
        if Instance.exists(inst) then

            if c_table["onPostStep"] then
                for k, fn in pairs(c_table["onPostStep"]) do
                    fn(Instance.wrap(inst))   -- Instance
                end
            end

        else callbacks[id] = nil
        end
    end
end


local function inst_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    for id, c_table in pairs(callbacks) do
        local inst = c_table["CInstance"]
        if Instance.exists(inst) then

            if c_table["onDraw"] then
                for k, fn in pairs(c_table["onDraw"]) do
                    fn(Instance.wrap(inst))   -- Instance
                end
            end

        else callbacks[id] = nil
        end
    end
end



-- ========== Initialize ==========

initialize_instance = function()
    lock_table_actor = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_actor))})
    lock_table_player = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_actor)), table.unpack(Helper.table_get_keys(methods_player))})
    lock_table_interactable_instance = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_instance)), table.unpack(Helper.table_get_keys(methods_interactable_instance))})

    gm_add_instance_methods(methods_instance)

    Callback.add("onAttackCreate", "RMT-inst_onAttack", inst_onAttack)
    Callback.add("onAttackCreate", "RMT-inst_onAttackAll", inst_onAttackAll)
    Callback.add("onAttackHandleEnd", "RMT-inst_onPostAttack", inst_onPostAttack)
    Callback.add("onAttackHandleEnd", "RMT-inst_onPostAttackAll", inst_onPostAttackAll)
    Callback.add("onHitProc", "RMT-inst_onHit", inst_onHit)
    Callback.add("onAttackHit", "RMT-inst_onHitAll", inst_onHitAll)
    Callback.add("onKillProc", "RMT-inst_onKill", inst_onKill)
    Callback.add("onDamagedProc", "RMT-inst_onDamaged", inst_onDamaged)
    Callback.add("onDamageBlocked", "RMT-inst_onDamageBlocked", inst_onDamageBlocked)
    Callback.add("onInteractableActivate", "RMT-inst_onInteract", inst_onInteract)
    Callback.add("onEquipmentUse", "RMT-inst_onEquipmentUse", inst_onEquipmentUse)
    Callback.add("preStep", "RMT-inst_onPreStep", inst_onPreStep)
    Callback.add("postStep", "RMT-inst_onPostStep", inst_onPostStep)
    Callback.add("postHUDDraw", "RMT-inst_onDraw", inst_onDraw)
end



return Instance