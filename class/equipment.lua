-- Equipment

Equipment = class_refs["Equipment"]

local callbacks = {}
local valid_callbacks = {
    onPickup                = true,
    onDrop                  = true,
    onUse                   = true,
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
    onStageStart            = true
}

local has_custom_equip = {}
local has_callbacks = {}
local is_passive = {}

local disabled_loot = {}
local loot_toggled = {}     -- Loot pools that have been added to this frame



-- ========== Static Methods ==========

Equipment.new = function(namespace, identifier, no_log)
    local equip = Equipment.find(namespace, identifier)
    if equip then return equip end

    -- Create equipment
    local equipment = Equipment.wrap(
        gm.equipment_create(
            namespace,
            identifier,
            Class.EQUIPMENT:size(),   -- class_equipment index
            Item.TIER.equipment,    -- tier
            gm.object_add_w(namespace, identifier, gm.constants.pPickupEquipment),  -- pickup object
            0.0,    -- loot tags
            nil,    -- not sure; might be an anon function call
            45.0,   -- cooldown
            true,   -- ? (most have this)
            6.0,    -- ? (most have this)
            nil,    -- ? (most have this)
            nil     -- ? (most have this)
        )
    )

    -- Have to manually increase this variable for some reason (class_equipment array length)
    gm.variable_global_set("count_equipment", gm.variable_global_get("count_equipment") + 1.0)

    -- Equipment log
    if not no_log then
        -- Remove previous item log position (if found)
        local item_log_order = List.wrap(gm.variable_global_get("item_log_display_list"))
        local pos = item_log_order:find(equipment.item_log_id)
        if pos then item_log_order:delete(pos) end

        -- Set item log position
        local pos = 0
        for i, log_id in ipairs(item_log_order) do
            local log_ = Class.ITEM_LOG:get(log_id)
            local iter_item = Equipment.find(log_:get(0), log_:get(1))
            if iter_item and iter_item.tier == 3.0 then pos = i end
        end
        item_log_order:insert(pos, equipment.item_log_id)
    
    else
        local item_log_order = List.wrap(gm.variable_global_get("item_log_display_list"))
        local pos = item_log_order:find(equipment.item_log_id)
        if pos then item_log_order:delete(pos) end
        equipment.item_log_id = nil
    end

    return equipment
end


Equipment.get_random = function()
    local equips = {}

    -- Add valid equipment to table
    for i, _ in ipairs(Class.EQUIPMENT) do
        local equip = Equipment.wrap(i - 1)
        table.insert(equips, equip)
    end

    -- Pick random equipment from table
    return equips[gm.irandom_range(1, #equips)]
end



-- ========== Instance Methods ==========

methods_equipment = {

    create = function(self, x, y, target)
        if not self.object_id then return nil end

        gm.item_drop_object(self.object_id, x, y, target, false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        -- The drop spawns 40 px above y parameter
        local drop = nil
        local drops = Instance.find_all(gm.constants.pPickupEquipment, gm.constants.oCustomObject_pPickupEquipment)
        for _, d in ipairs(drops) do
            if math.abs(d.x - x) <= 1.0 and math.abs(d.y - (y - 40.0)) <= 1.0 then
                drop = d
                d.y = d.y + 40.0
                d.ystart = d.y
                break
            end
        end

        return Instance.wrap(drop)
    end,
    

    add_callback = function(self, callback, func)
        -- Add onPickup/onDrop callback to add/remove actor to/from has_custom_equip
        local function add_onPickup()
            if has_callbacks[self.value] then return end
            has_callbacks[self.value] = true

            self:onPickup(function(actor)
                has_custom_equip[actor.id] = true
            end)
            self:onDrop(function(actor, new_equipment)
                has_custom_equip[actor.id] = nil
            end)
        end

        if callback == "onUse" then
            add_onPickup()
            local callback_id = self.on_use
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)

        elseif valid_callbacks[callback] then
            add_onPickup()
            if not callbacks[callback] then callbacks[callback] = {} end
            if not callbacks[callback][self.value] then callbacks[callback][self.value] = {} end
            table.insert(callbacks[callback][self.value], func)

        else log.error("Invalid callback name", 2)
        end
    end,


    clear_callbacks = function(self)
        callbacks[self.on_use] = nil

        for callback, _ in pairs(valid_callbacks) do
            local c_table = callbacks[callback]
            if c_table then c_table[self.value] = nil end
        end

        has_callbacks[self.value] = nil
    end,


    set_sprite = function(self, sprite)
        -- Set class_equipment sprite
        self.sprite_id = sprite

        -- Set equipment object sprite
        gm.object_set_sprite_w(self.object_id, sprite)

        -- Set equipment log sprite
        if self.item_log_id then
            local log_array = Class.ITEM_LOG:get(self.item_log_id)
            log_array:set(9, sprite)
        end
    end,


    set_loot_tags = function(self, ...)
        local tags = 0
        for _, t in ipairs{...} do tags = tags + t end

        self.loot_tags = tags
    end,


    set_cooldown = function(self, cooldown)
        self.cooldown = cooldown * 60.0
    end,


    set_passive = function(self, bool)
        if bool and not is_passive[self.value] then is_passive[self.value] = true
        elseif not bool and is_passive[self.value] then is_passive[self.value] = nil
        end
    end,


    is_unlocked = function(self)
        return (not self.achievement_id) or gm.achievement_is_unlocked(self.achievement_id)
    end,


    add_achievement = function(self, progress_req, single_run)
        local ach = gm.achievement_create(self.namespace, self.identifier)
        gm.achievement_set_unlock_equipment(ach, self.value)
        gm.achievement_set_requirement(ach, progress_req or 1)
    
        if single_run then
            local ach_array = Class.ACHIEVEMENT:get(ach)
            ach_array:set(21, single_run)
        end
    end,


    progress_achievement = function(self, amount)
        if self:is_unlocked() then return end
        gm.achievement_add_progress(self.achievement_id, amount or 1)
    end,


    toggle_loot = function(self, enabled)
        if enabled == nil then return end

        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        local equip_array = Class.EQUIPMENT:get(self.value)
        local obj = equip_array:get(8)
        
        if enabled then
            if disabled_loot[self.value] then
                -- Add back to loot pools
                for _, pool_id in ipairs(disabled_loot[self.value]) do
                    local drop_pool = List.wrap(loot_pools:get(pool_id).drop_pool)
                    drop_pool:add(obj)

                    if not Helper.table_has(loot_toggled, pool_id) then
                        table.insert(loot_toggled, pool_id)
                    end
                end

                disabled_loot[self.value] = nil
            end

        else
            if not disabled_loot[self.value] then
                -- Remove from loot pools
                -- and store the pool indexes
                local pools = {}
                
                for i = 0, #loot_pools - 1 do
                    local drop_pool = List.wrap(loot_pools:get(i).drop_pool)
                    local pos = drop_pool:find(obj)
                    if pos then
                        drop_pool:delete(pos)
                        table.insert(pools, i)
                    end
                end

                disabled_loot[self.value] = pools
            end

        end
    end

}

-- Callbacks
for c, _ in pairs(valid_callbacks) do
    methods_equipment[c] = function(self, func)
        self:add_callback(c, func)
    end
end



-- ========== Metatables ==========

metatable_class["Equipment"] = {
    __index = function(table, key)
        -- Methods
        if methods_equipment[key] then
            return methods_equipment[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Equipment"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Equipment"].__newindex(table, key, value)
    end,


    __metatable = "equipment"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    -- onUse
    if callbacks[args[1].value] then
        local player = Instance.wrap(args[2].value)
        for _, fn in ipairs(callbacks[args[1].value]) do
            fn(player)
        end
    end
end)


gm.pre_script_hook(gm.constants.item_use_equipment, function(self, other, result, args)
    -- Prevent passive equipment use
    local equipment = Instance.wrap(self):get_equipment()
    if equipment and is_passive[equipment.value] then
        return false
    end
end)


gm.pre_script_hook(gm.constants.equipment_set, function(self, other, result, args)
    local player = Instance.wrap(args[1].value)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onDrop"] then return end

    local new_equipment = Equipment.wrap(args[2].value)

    for _, fn in ipairs(callbacks[equipment.value]["onDrop"]) do
        fn(player, new_equipment)
    end
end)


gm.post_script_hook(gm.constants.equipment_set, function(self, other, result, args)
    local player = Instance.wrap(args[1].value)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPickup"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onPickup"]) do
        fn(player)
    end

    player:recalculate_stats()
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_equip[self.id] then return end

    local player = Instance.wrap(self)
    local playerData = player:get_data("equip")
    local equipment = player:get_equipment()

    if not callbacks[equipment.value] then return end

    if callbacks[equipment.value]["onPreStep"] then
        for _, fn in ipairs(callbacks[equipment.value]["onPreStep"]) do
            fn(player)
        end
    end

    if not callbacks[equipment.value]["onShieldBreak"] then return end

    if self.shield and self.shield > 0.0 then playerData.has_shield = true end
    if playerData.has_shield and self.shield <= 0.0 then
        playerData.has_shield = nil

        for _, fn in ipairs(callbacks[equipment.value]["onShieldBreak"]) do
            fn(player)
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if not has_custom_equip[self.id] then return end

    local player = Instance.wrap(self)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPostStep"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onPostStep"]) do
        fn(player)
    end
end)


gm.pre_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not has_custom_equip[self.id] then return end

    local player = Instance.wrap(self)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPreDraw"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onPreDraw"]) do
        fn(player)
    end
end)


gm.post_script_hook(gm.constants.draw_actor, function(self, other, result, args)
    if not has_custom_equip[self.id] then return end

    local player = Instance.wrap(self)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPostDraw"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onPostDraw"]) do
        fn(player)
    end
end)


gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local player = Instance.wrap(self)
    player:get_data().post_stat_recalc = true
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onStatRecalc"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onStatRecalc"]) do
        fn(player)
    end
end)


gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if not has_custom_equip[self.id] then return end
    
    local callback = {
        "onPrimaryUse",
        "onSecondaryUse",
        "onUtilityUse",
        "onSpecialUse"
    }
    callback = callback[args[1].value + 1]

    local player = Instance.wrap(self)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value][callback] then return end

    local active_skill = player:get_active_skill(args[1].value)

    for _, fn in ipairs(callbacks[equipment.value][callback]) do
        fn(player, active_skill)
    end
end)


gm.post_script_hook(gm.constants.player_heal_networked, function(self, other, result, args)
    local player = args[1].value
    if not has_custom_equip[player.id] then return end

    player = Instance.wrap(player)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onHeal"] then return end

    local heal_amount = args[2].value

    for _, fn in ipairs(callbacks[equipment.value]["onHeal"]) do
        fn(player, heal_amount)
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Sort loot tables that have been added to
    for _, pool_id in ipairs(loot_toggled) do
        local loot_pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))

        -- Get equipment IDs from objects and sort
        local ids = List.new()
        local drop_pool = List.wrap(loot_pools:get(pool_id).drop_pool)
        for _, obj in ipairs(drop_pool) do
            ids:add(gm.object_to_equipment(obj))
        end
        ids:sort()

        -- Add objects of sorted IDs back into loot pool
        drop_pool:clear()
        for _, id in ipairs(ids) do
            local equip = Class.EQUIPMENT:get(id)
            local obj = equip:get(8)
            drop_pool:add(obj)
        end
        ids:destroy()
    end
    loot_toggled = {}
end)



-- ========== Callbacks ==========

function equipment_onPostStatRecalc(player)
    if not player.RMT_object == "Player" then return end
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPostStatRecalc"] then return end

    for _, fn in ipairs(callbacks[equipment.value]["onPostStatRecalc"]) do
        fn(player)
    end
end


Callback.add("onAttackCreate", "RMT-Equipment.onAttackCreate", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local player = attack_info.parent

    if not Instance.exists(player) then return end
    if not has_custom_equip[player.id] then return end

    player = Instance.wrap(player)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value] then return end

    if callbacks[equipment.value]["onAttackCreate"] then
        for _, fn in ipairs(callbacks[equipment.value]["onAttackCreate"]) do
            fn(player, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks[equipment.value]["onAttackCreateProc"] then
        for _, fn in ipairs(callbacks[equipment.value]["onAttackCreateProc"]) do
            fn(player, attack_info)
        end
    end
end)


Callback.add("onAttackHit", "RMT-Equipment.onAttackHit", function(self, other, result, args)
    local hit_info = Hit_Info.wrap(args[2].value)
    local player = hit_info.inflictor

    if not Instance.exists(player) then return end
    if not has_custom_equip[player.id] then return end

    player = Instance.wrap(player)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onAttackHit"] then return end
    
    local victim = Instance.wrap(hit_info.target_true)

    for _, fn in ipairs(callbacks[equipment.value]["onAttackHit"]) do
        fn(player, victim, hit_info)
    end
end)


Callback.add("onAttackHandleEnd", "RMT-Equipment.onAttackHandleEnd", function(self, other, result, args)
    local attack_info = Attack_Info.wrap(args[2].value)
    local player = attack_info.parent

    if not Instance.exists(player) then return end
    if not has_custom_equip[player.id] then return end

    player = Instance.wrap(player)
    local equipment = player:get_equipment()

    if not callbacks[equipment.value] then return end

    if callbacks[equipment.value]["onAttackHandleEnd"] then
        for _, fn in ipairs(callbacks[equipment.value]["onAttackHandleEnd"]) do
            fn(player, attack_info)
        end
    end

    if Helper.is_false(attack_info.proc) then return end

    if callbacks[equipment.value]["onAttackHandleEndProc"] then
        for _, fn in ipairs(callbacks[equipment.value]["onAttackHandleEndProc"]) do
            fn(player, attack_info)
        end
    end
end)


Callback.add("onHitProc", "RMT-Equipment.onHitProc", function(self, other, result, args)     -- Runs before onAttackHit
    local player = Instance.wrap(args[2].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onHitProc"] then return end

    local victim = Instance.wrap(args[3].value)
    local hit_info = Hit_Info.wrap(args[4].value)

    for _, fn in ipairs(callbacks[equipment.value]["onHitProc"]) do
        fn(player, victim, hit_info)
    end
end)


Callback.add("onKillProc", "RMT-Equipment.onKillProc", function(self, other, result, args)
    local player = Instance.wrap(args[3].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onKillProc"] then return end

    local victim = Instance.wrap(args[2].value)

    for _, fn in ipairs(callbacks[equipment.value]["onKillProc"]) do
        fn(player, victim)
    end
end)


Callback.add("onDamagedProc", "RMT-Equipment.onDamagedProc", function(self, other, result, args)
    local player = Instance.wrap(args[2].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onDamagedProc"] then return end

    local hit_info = Hit_Info.wrap(args[3].value)
    local attacker = Instance.wrap(hit_info.inflictor)

    for _, fn in ipairs(callbacks[equipment.value]["onDamagedProc"]) do
        fn(player, attacker, hit_info)
    end
end)


Callback.add("onDamageBlocked", "RMT-Equipment.onDamageBlocked", function(self, other, result, args)
    local player = Instance.wrap(args[2].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onDamageBlocked"] then return end

    local damage = args[4].value

    for _, fn in ipairs(callbacks[equipment.value]["onDamageBlocked"]) do
        fn(player, damage)
    end
end)


Callback.add("onInteractableActivate", "RMT-Equipment.onInteractableActivate", function(self, other, result, args)
    local player = Instance.wrap(args[3].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onInteractableActivate"] then return end

    local interactable = Instance.wrap(args[2].value)

    for _, fn in ipairs(callbacks[equipment.value]["onInteractableActivate"]) do
        fn(player, interactable)
    end
end)


Callback.add("onPickupCollected", "RMT-Equipment.onPickupCollected", function(self, other, result, args)
    local player = Instance.wrap(args[3].value)
    if not has_custom_equip[player.id] then return end

    local equipment = player:get_equipment()

    if not callbacks[equipment.value]
    or not callbacks[equipment.value]["onPickupCollected"] then return end

    local pickup_object = Instance.wrap(args[2].value)  -- Will be oCustomObject_pPickupItem/Equipment for all custom items/equipment

    for _, fn in ipairs(callbacks[equipment.value]["onPickupCollected"]) do
        fn(player, pickup_object)
    end
end)


Callback.add("onStageStart", "RMT-Equipment.onStageStart", function(self, other, result, args)
    for player_id, _ in pairs(has_custom_equip) do
        if not Instance.exists(player_id) then
            has_custom_equip[player_id] = nil
        end
    end

    for player_id, _ in pairs(has_custom_equip) do
        local player = Instance.wrap(player_id)
        local equipment = player:get_equipment()

        if callbacks[equipment.value] and callbacks[equipment.value]["onStageStart"] then
            for _, fn in ipairs(callbacks[equipment.value]["onStageStart"]) do
                fn(player)
            end
        end
    end
end)



return Equipment