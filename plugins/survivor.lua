-- Survivor

Survivor = {}

local callbacks = {}


-- ========== Enums ==========

Survivor.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_name_upper            = 3,
    token_description           = 4,
    token_end_quote             = 5,
    skill_family_z              = 6,
    skill_family_x              = 7,
    skill_family_c              = 8,
    skill_family_v              = 9,
    skin_family                 = 10,
    all_loadout_families        = 11,
    all_skill_families          = 12,
    sprite_loadout              = 13,
    sprite_title                = 14,
    sprite_idle                 = 15,
    sprite_portrait             = 16,
    sprite_portrait_small       = 17,
    sprite_palette              = 18,
    sprite_portrait_palette     = 19,
    sprite_loadout_palette      = 20,
    sprite_credits              = 21,
    primary_color               = 22,
    select_sound_id             = 23,
    log_id                      = 24,
    achievement_id              = 25,
    _SURVIVOR_MILESTONE_FIELDS  = 26,
    on_init                     = 27,
    on_step                     = 28,
    on_remove                   = 29,
    is_secret                   = 30,
    cape_offset                 = 31
}


-- ========== Static Methods ==========

Survivor.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    for i, survivor in ipairs(Class.SURVIVOR) do
        local _namespace = survivor:get(0)
        local _identifier = survivor:get(1)
        if namespace == _namespace.."-".._identifier then
            return Survivor.wrap(i - 1)
        end
    end

    return nil
end

Survivor.wrap = function(survivor_id)
    local abstraction = {
        RMT_wrapper = "Survivor",
        value = survivor_id
    }
    setmetatable(abstraction, metatable_survivor)

    return abstraction
end

Survivor.new = function(namespace, identifier)
    -- Check if survivor already exist
    local survivor = Survivor.find(namespace, identifier)
    if survivor then return survivor end

    -- Create survivor
    survivor = gm.survivor_create(namespace, identifier)

    -- Make survivor abstraction
    local abstraction = Survivor.wrap(survivor)

    -- Create callbacks for on_init and on_step
    -- abstraction.on_init = gm.callback_create()
    abstraction.on_init = 77
    abstraction.on_step = gm.callback_create()

    return abstraction
end

Survivor.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_survivor = {

    add_callback = function(self, callback, func)

        if callback == "onInit" then
            local callback_id = self.on_init
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onRemove" then
            local callback_id = self.on_remove
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
    end,

    add_skill = function(self, skill, skill_family, achievement)
        if not achievement then achievement = -1 end

        local survivor_loadout_unlockables = gm.variable_global_get("survivor_loadout_unlockables")
        
        local survivor_loadout = gm.struct_create()

        gm.static_set(survivor_loadout, gm.static_get(skill_family[1]))

        survivor_loadout.skill_id = skill.value
        survivor_loadout.achievement_id = achievement -- TODO make it compatible with the achievement module
        survivor_loadout.save_flag_viewed = nil
        survivor_loadout.index = gm.array_length(survivor_loadout_unlockables)

        gm.array_push(survivor_loadout_unlockables, survivor_loadout)
        gm.array_push(skill_family, survivor_loadout)
    end,

    add_primary = function(self, skill, achievement)
        self:add_skill(skill, self.skill_family_z.elements, achievement)
    end,
    
    add_secondary = function(self, skill, achievement)
        self:add_skill(skill, self.skill_family_x.elements, achievement)
    end,
    
    add_utility = function(self, skill, achievement)
        self:add_skill(skill, self.skill_family_c.elements, achievement)
    end,
    
    add_special = function(self, skill, achievement)
        self:add_skill(skill, self.skill_family_v.elements, achievement)
    end,

    get_skill = function(self, skill_family, family_index)
        if family_index > #skill_family or family_index < 1 then 
            log.error("Family index is out of bound!")
            return nil
        end
        return Skill.wrap(skill_family[family_index].skill_id)
    end,
    
    get_primary = function(self, family_index)
        local elements = self.skill_family_z.elements
        return self:get_skill(elements, family_index)
    end,

    get_secondary = function(self, family_index)
        local elements = self.skill_family_x.elements
        return self:get_skill(elements, family_index)
    end,

    get_utility = function(self, family_index)
        local elements = self.skill_family_c.elements
        return self:get_skill(elements, family_index)
    end,

    get_special = function(self, family_index)
        local elements = self.skill_family_v.elements
        return self:get_skill(elements, family_index)
    end,
}

methods_survivor_callbacks = {
    onInit      = function(self, func) self:add_callback("onInit", func) end,
    onStep      = function(self, func) self:add_callback("onStep", func) end,
    onRemove    = function(self, func) self:add_callback("onRemove", func) end
}


-- ========== Metatables ==========

metatable_survivor_gs = {
    -- Getter
    __index = function(table, key)
        local index = Survivor.ARRAY[key]
        if index then
            local survivor_array = Class.SURVIVOR:get(table.value)
            return survivor_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Survivor.ARRAY[key]
        if index then
            local survivor_array = Class.SURVIVOR:get(table.value)
            survivor_array:set(index, value)
        end
    end
}

metatable_survivor_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_survivor_callbacks[key] then
            return methods_survivor_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_survivor_gs.__index(table, key)
    end
}

metatable_survivor = {
    __index = function(table, key)
        -- Methods
        if methods_survivor[key] then
            return methods_survivor[key]
        end

        -- Pass to next metatable
        return metatable_survivor_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_survivor_gs.__newindex(table, key, value)
    end
}


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value, args[3].value) --(actor, ??)
        end
    end
end)