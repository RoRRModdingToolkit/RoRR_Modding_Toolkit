-- Skill

Skill = class_refs["Skill"]

local callbacks = {}
-- local other_callbacks = {
--     "onPreStep",
--     "onPostStep"
-- }

local achievement_map = {}

-- TODO add checks for instance methods

-- ========== Enums ==========

Skill.OVERRIDE_PRIORITY = Proxy.new({
    upgrade     = 0,
    boosted     = 1,
    reload      = 2,
    cancel      = 3
}):lock()


Skill.SLOT = Proxy.new({
    primary     = 0,
    secondary   = 1,
    utility     = 2,
    special     = 3
}):lock()



-- ========== Static Methods ==========

Skill.new = function(namespace, identifier, cooldown, damage, sprite_id, sprite_subimage, animation, is_primary, is_utility)
    -- Check if skill already exist
    local skill = Skill.find(namespace, identifier)
    if skill then return skill end

    -- Create skill
    skill = Skill.wrap(
        gm.skill_create(
            namespace,                      -- Namespace
            identifier,                     -- Identifier
            nil,                            -- Skill ID
            cooldown,                       -- Cooldown
            sprite_id,                      -- Sprite ID
            sprite_subimage,                -- Sprite Subimage
            damage,                         -- Damage
            animation,                      -- Animation
            is_primary,                     -- Is Primary
            is_utility                      -- Is Utility
        )
    )

    return skill
end

Skill.newEmpty = function(namespace, identifier)
    -- Check if skill already exist
    local skill = Skill.find(namespace, identifier)
    if skill then return skill end

    -- Create skill
    local skill = gm.skill_create(
        namespace,                      -- Namespace
        identifier,                     -- Identifier
        nil,                            -- Skill ID
        0,                              -- Cooldown
        gm.constants.sRobomandoSkills,  -- Sprite ID
        3,                              -- Sprite Subimage
        0,                              -- Damage
        nil,                            -- Animation
        false,                          -- Is Primary
        false                           -- Is Utility
    )

    -- Make skill abstraction
    local abstraction = Skill.wrap(skill)

    abstraction.required_stock = 1
    abstraction.max_stock = 0

    return abstraction
end


-- ========== Instance Methods ==========

methods_skill = {

    add_callback = function(self, callback, func)
        local callback_id = nil
        if      callback == "onCanActivate" then callback_id = self.on_can_activate
        elseif  callback == "onActivate"    then callback_id = self.on_activate
        elseif  callback == "onStep"        then callback_id = self.on_step
        elseif  callback == "onEquipped"    then callback_id = self.on_equipped
        elseif  callback == "onUnequipped"  then callback_id = self.on_unequipped
        end

        if callback_id then
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        
        -- elseif Helper.table_has(other_callbacks, callback) then
        --     if not callbacks[callback] then callbacks[callback] = {} end
        --     table.insert(callbacks[callback], {self.value, func})

        else log.error("Invalid callback name", 2)
        end
    end,

    clear_callbacks = function(self)
        callbacks[self.on_can_activate] = nil
        callbacks[self.on_activate] = nil
        callbacks[self.on_equipped] = nil
        callbacks[self.on_unequipped] = nil
        
        for _, c in ipairs(other_callbacks) do
            local c_table = callbacks[c]
            if c_table then
                for i, v in ipairs(c_table) do
                    if v[1] == self.value then
                        table.remove(c_table, i)
                    end
                end
            end
        end
    end,

    set_skill = function(self, name, desc, sprite, subimage, damage, cooldown)
        self.token_name = name
        self.token_description = desc
        self.sprite = sprite
        self.subimage = subimage
        self.damage = damage
        self.cooldown = cooldown
    end,
    
    set_skill_icon = function(self, sprite, subimage)
        self.sprite = sprite
        self.subimage = subimage
    end,

    set_skill_properties = function(self, damage, cooldown)
        self.damage = damage
        self.cooldown = cooldown
    end,

    set_skill_stock = function(self, max_stock, start_stock, auto_restock, required_stock)
        self.max_stock = max_stock
        self.start_with_stock = start_stock
        self.auto_restock = auto_restock
        self.required_stock = required_stock
    end,

    set_skill_primary = function(self)
        self.is_primary = true
        self.is_utility = false
    end,

    set_skill_utility = function(self)
        self.is_utility = true
        self.is_primary = false
    end,

    set_skill_animation = function(self, animation)
        self.animation = animation
    end,

    set_skill_settings = function(self, allow_buffered_input, use_delay, required_interrupt_priority, hold_facing_direction, override_strafe_direction, ignore_aim_direction, disable_aim_stall, does_change_activity_state)
        self.allow_buffered_input = allow_buffered_input
        self.use_delay = use_delay
        self.required_interrupt_priority = required_interrupt_priority
        self.hold_facing_direction = hold_facing_direction
        self.override_strafe_direction = override_strafe_direction
        self.ignore_aim_direction = ignore_aim_direction
        self.disable_aim_stall = disable_aim_stall
        self.does_change_activity_state = does_change_activity_state
    end,

    set_skill_upgrade = function(self, upgraded_skill)
        if type(upgraded_skill) ~= "table" or upgraded_skill.RMT_object ~= "Skill" then log.error("Upgraded Skill is not a RMT Skill, got a "..type(upgrade_skill), 2) return end
        
        self.upgrade_skill = upgraded_skill.value
    end,


    is_unlocked = function(self)
        local ach = achievement_map[self.value]
        return (not ach) or gm.achievement_is_unlocked(ach)
    end,

    add_achievement = function(self, progress_req, single_run)
        local loadout_unlockable = nil
        local lu_array = GM.variable_global_get("survivor_loadout_unlockables")
        for i, lu in ipairs(lu_array) do
            if lu.skill_id == self.value then
                loadout_unlockable = i - 1
                break
            end
        end

        if not loadout_unlockable then log.error("Loadout unlockable does not exist", 2) end

        local ach = gm.achievement_create(self.namespace, self.identifier)
        gm.achievement_set_unlock_survivor_loadout_unlockable(ach, loadout_unlockable)
        gm.achievement_set_requirement(ach, progress_req or 1)
    
        if single_run then
            local ach_array = Class.ACHIEVEMENT:get(ach)
            ach_array:set(21, single_run)
        end

        achievement_map[self.value] = ach
    end,

    progress_achievement = function(self, amount)
        if self:is_unlocked() then return end
        gm.achievement_add_progress(achievement_map[self.value], amount or 1)
    end,


    -- Callbacks
    onCanActivate   = function(self, func) self:add_callback("onCanActivate", func) end,
    onActivate      = function(self, func) self:add_callback("onActivate", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    -- onPreStep       = function(self, func) self:add_callback("onPreStep", func) end,
    -- onPostStep      = function(self, func) self:add_callback("onPostStep", func) end,
    onEquipped      = function(self, func) self:add_callback("onEquipped", func) end,
    onUnequipped    = function(self, func) self:add_callback("onUnequipped", func) end
    
}



-- ========== Metatables ==========

metatable_class["Skill"] = {
    __index = function(table, key)
        -- Methods
        if methods_skill[key] then
            return methods_skill[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Skill"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Skill"].__newindex(table, key, value)
    end,


    __metatable = "Skill"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            local new = fn(Instance.wrap(args[2].value), args[3].value, args[4].value) --(actor, ActorSkill struct, index)
            if new then result.value = new end
        end
    end
end)


gm.post_script_hook(gm.constants.callback_is_bound, function(self, other, result, args)
    if callbacks[args[1].value] then
        result.value = true
    end
end)



-- ========== Callbacks ==========

-- These currently only apply to Player skills to prevent lag
-- Should be fine until someone complains about it
-- Jan 14, 2025: Removed

-- local function skill_onPreStep(self, other, result, args)
--     if gm.variable_global_get("pause") then return end
    
--     if callbacks["onPreStep"] then
--         local actors = Instance.find_all(gm.constants.oP)
--         for n, actor in ipairs(actors) do

--             -- Loop through active skills
--             for slot = 0, 3 do
--                 local active_skill = actor:get_active_skill(slot)

--                 -- Loop through callbacks
--                 for _, c in ipairs(callbacks["onPreStep"]) do
--                     if c[1] == active_skill.skill_id then
--                         c[2](actor, active_skill, slot)  -- Actor, ActorSkill struct, index
--                     end
--                 end
--             end

--         end
--     end
-- end


-- local function skill_onPostStep(self, other, result, args)
--     if gm.variable_global_get("pause") then return end
    
--     if callbacks["onPostStep"] then
--         local actors = Instance.find_all(gm.constants.oP)
--         for n, actor in ipairs(actors) do

--             -- Loop through active skills
--             for slot = 0, 3 do
--                 local active_skill = actor:get_active_skill(slot)

--                 -- Loop through callbacks
--                 for _, c in ipairs(callbacks["onPostStep"]) do
--                     if c[1] == active_skill.skill_id then
--                         c[2](actor, active_skill, slot)  -- Actor, ActorSkill struct, index
--                     end
--                 end
--             end

--         end
--     end
-- end



-- ========== Initialize ==========

-- Callback_Raw.add("preStep", "RMT-skill_onPreStep", skill_onPreStep)
-- Callback_Raw.add("postStep", "RMT-skill_onPostStep", skill_onPostStep)



return Skill