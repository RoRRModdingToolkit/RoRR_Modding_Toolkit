-- Skill

Skill = class_refs["Skill"]

local callbacks = {}

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
    skill = gm.skill_create(
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

    -- Make skill abstraction
    local abstraction = Skill.wrap(skill)

    return abstraction
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

        if callback == "onCanActivate" then 
            local callback_id = self.on_can_activate
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onActivate" then 
            local callback_id = self.on_activate
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onEquipped" then
            local callback_id = self.on_equipped
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onUnequipped" then
            local callback_id = self.on_unequipped
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end 
    end,

    clear_callbacks = function(self)
        callbacks[self.on_can_activate] = nil
        callbacks[self.on_activate] = nil
        callbacks[self.on_step] = nil
        callbacks[self.on_equipped] = nil
        callbacks[self.on_unequipped] = nil
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


    -- Callbacks
    onCanActivate   = function(self, func) self:add_callback("onCanActivate", func) end,
    onActivate      = function(self, func) self:add_callback("onActivate", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    onEquipped      = function(self, func) self:add_callback("onEquipped", func) end,
    onUnequipped    = function(self, func) self:add_callback("onUnequipped", func) end
}
methods_class_lock["Skill"] = Helper.table_get_keys(methods_skill)



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


    __metatable = "skill"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(Instance.wrap(args[2].value), Skill.wrap(args[3].value), args[4].value) --(actor, skill, index)
        end
    end
end)



return Skill