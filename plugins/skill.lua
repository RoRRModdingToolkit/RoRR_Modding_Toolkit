-- Skill

Skill = {}

local callbacks = {}


-- ========== Enums ==========

Skill.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_description           = 3,
    sprite                      = 4,
    subimage                    = 5,
    cooldown                    = 6,
    damage                      = 7,
    max_stock                   = 8,
    start_with_stock            = 9,
    auto_restock                = 10,
    required_stock              = 11,
    require_key_press           = 12,
    allow_buffered_input        = 13,
    use_delay                   = 14,
    animation                   = 15,
    is_utility                  = 16,
    is_primary                  = 17,
    required_interrupt_priority = 18,
    hold_facing_direction       = 19,
    override_strafe_direction   = 20,
    ignore_aim_direction        = 21,
    disable_aim_stall           = 22,
    does_change_activity_state  = 23,
    on_can_activate             = 24,
    on_activate                 = 25,
    on_step                     = 26,
    on_equipped                 = 27,
    on_unequipped               = 28,
    upgrade_skill               = 29
}


Skill.SLOT = {
    primary     = 0,
    secondary   = 1,
    utility     = 2,
    special     = 3
}



-- ========== Static Methods ==========

Skill.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    for i, skill in ipairs(Class.SKILL) do
        if skill ~= 0 then    -- There is a random nil(?) value at 186(?) for some reason
            local _namespace = skill:get(0)
            local _identifier = skill:get(1)
            if namespace == _namespace.."-".._identifier then
                return Skill.wrap(i - 1)
            end
        end
    end

    return nil
end


Skill.wrap = function(skill_id)
    local abstraction = {
        RMT_wrapper = "Skill",
        value = skill_id
    }
    setmetatable(abstraction, metatable_skill)

    return abstraction
end

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

Skill.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
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
        self.upgrade_skill = upgraded_skill
    end,
}

methods_skill_callbacks = {
    onCanActivate   = function(self, func) self:add_callback("onCanActivate", func) end,
    onActivate      = function(self, func) self:add_callback("onActivate", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    onEquipped      = function(self, func) self:add_callback("onEquipped", func) end,
    onUnequipped    = function(self, func) self:add_callback("onUnequipped", func) end
}

-- ========== Metatables ==========

metatable_skill_gs = {
    -- Getter
    __index = function(table, key)
        local index = Skill.ARRAY[key]
        if index then
            local skill_array = Class.SKILL:get(table.value)
            return skill_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Skill.ARRAY[key]
        if index then
            local skill_array = Class.SKILL:get(table.value)
            skill_array:set(index, value)
        end
    end
}

metatable_skill_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_skill_callbacks[key] then
            return methods_skill_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_skill_gs.__index(table, key)
    end
}

metatable_skill = {
    __index = function(table, key)
        -- Methods
        if methods_skill[key] then
            return methods_skill[key]
        end

        -- Pass to next metatable
        return metatable_skill_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_skill_gs.__newindex(table, key, value)
    end
}

-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value, args[4].value) --(actor, skill, index)
        end
    end
end)