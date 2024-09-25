-- Achievement

Achievement = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}


-- ========== Enums ==========

Achievement.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_desc                  = 3,
    token_desc2                 = 4,
    token_unlock_name           = 5,
    unlock_kind                 = 6,
    unlock_id                   = 7,
    sprite_id                   = 8,
    sprite_subimage             = 9,
    sprite_scale                = 10,
    sprite_scale_ingame         = 11,
    is_hidden                   = 12,
    is_trial                    = 13,
    is_server_authorative       = 14,
    milestone_alt_unlock        = 15,
    milestone_survivor          = 16,
    progress                    = 17,
    unlocked                    = 18,
    parent_id                   = 19,
    progress_needed             = 20,
    death_reset                 = 21,
    group                       = 22,
    on_completed                = 23
}

Achievement.KIND = {
    none                        = 0,
    mode                        = 1,
    survivor                    = 2,
    item                        = 3,
    equipment                   = 4,
    artifact                    = 5,
    survivor_loadout_unlockable = 6 
}

Achievement.GROUP = {
    challenge   = 0,
    character   = 1,
    artifact    = 2
}
-- ========== Static Methods ==========

Achievement.find = function(namespace, identifier)
    local id_string = namespace.."-"..identifier
    local achievement_id = gm.achievement_find(id_string)

    if not achievement_id then return nil end

    return Achievement.wrap(achievement_id)
end

Achievement.wrap = function(achievement_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Achievement",
        value = achievement_id
    }
    setmetatable(abstraction, metatable_achievement)
    
    return abstraction
end

Achievement.new = function(namespace, identifier)
    -- Check if Achievement already exist
    local achievement = Achievement.find(namespace, identifier)
    if achievement then return achievement end
    
    -- Create Achievement
    achievement = gm.achievement_create(namespace, identifier)

    -- Make Achievement abstraction
    local abstraction = Achievement.wrap(achievement)

    return abstraction
end

Achievement.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_achievement = {

    add_callback = function(self, callback, func)

        if callback == "onCompleted" then
            local callback_id = self.on_completed
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        else log.error("Invalid callback name", 2) end
    end,

    set_text = function(self, name, desc, subdesc, unlock_name)
        self.token_name = name
        self.token_desc = desc
        self.token_desc2 = subdesc
        self.token_unlock_name = unlock_name
    end,

    set_unlock = function(self, unlock_kind, unlock_id)
        if not Helper.table_has(Artifact.KIND, unlock_kind) then log.error("Unlock Kind is not recognized, got "..tostring(unlock_kind), 2) return end

        self.unlock_kind = unlock_kind
        self.unlock_id = unlock_id
    end,

    set_sprite = function(self, sprite_id, subimage)
        if type(sprite_id) ~= "number" then log.error("Sprite ID is not a number, got a "..type(sprite_id), 2) return end
        if type(subimage) ~= "number" and type(subimage) ~= "nil" then log.error("Subimage is not a number, got a "..type(subimage), 2) return end
        
        self.sprite_id = sprite_id
        self.sprite_subimage = subimage or 0
    end,

    set_sprite_scale = function(self, scale, scale_ingame)
        if type(scale) ~= "number" then log.error("Scale is not a number, got "..tostring(scale), 2) return end
        if type(scale_ingame) ~= "number" and type(scale_ingame) ~= "nil" then log.error("Scale Ingame is not a number, got a "..tostring(scale_ingame), 2)  return end
        
        self.scale = scale
        self.scale_ingame = scale_ingame or self.scale_ingame
    end,

    set_properties = function(self, is_hidden, is_trial, is_server)
        if type(is_hidden) ~= "boolean" then log.error("Is Hidden is not a boolean, got a "..type(is_hidden), 2) return end
        if type(is_trial) ~= "boolean" and type(is_trial) ~= "nil" then log.error("Is Trial is not a boolean, got a "..type(is_trial), 2) return end
        if type(is_server) ~= "boolean" and type(is_server) ~= "nil" then log.error("Is Server Authorative is not a boolean, got a "..type(is_server), 2) return end
        
        self.is_hidden = is_hidden
        self.is_trial = is_trial or self.is_trial
        self.is_server_authorative = is_server or self.is_server_authorative
    end,

    set_milestone = function(self, milestone_id, survivor)
        if type(milestone_id) ~= "number" then log.error("Milestone ID is not a number, got a "..type(milestone_id), 2) return end
        if milestone_id < 0 or milestone_id > 2 then log.error("Milestone ID should be between 0 and 2, got "..tostring(milestone_id), 2) return end
        if type(survivor) ~= "table" or (survivor.RMT_object ~= "Survivor" and not survivor.value) then log.error("Survivor is not a RMT survivor, got a "..type(survivor), 2) return end

        self.milestone_alt_unlock = milestone_id
        self.milestone_survivor = survivor.value
    end,

    set_progress = function(self, progress, unlocked)
        if type(progress) ~= "number" then log.error("Progress is not a number, got a"..type(progress), 2) return end
        if type(unlocked) ~= "number" and type(unlocked) ~= "nil" then log.error("Unlocked is not a number, got a "..type(unlocked), 2) return end
        
        self.progress = progress
        self.unlocked = unlocked or self.unlocked
    end,

    set_requirement = function(self, parent_id, progress_needed, death_reset)
        if type(parent_id) ~= "number" and type(parent_id) ~= "nil" then log.error("Parent ID is not a number, got a "..type(parent_id), 2) return end
        if type(progress_needed) ~= "number" and type(progress_needed) ~= "nil" then log.error("Progress Needed is not a number, got a "..type(progress_needed), 2) return end
        if type(death_reset) ~= "boolean" and type(death_reset) ~= "nil" then log.error("Death Reset is not a boolean, got a "..type(death_reset), 2) return end

        self.parent_id = parent_id or self.parent_id
        self.progress_needed = progress_needed or self.progress_needed
        self.death_reset = death_reset or self.death_reset
    end,

    set_group = function(self, group)
        if not Helper.table_has(Artifact.GROUP, group) then log.error("Group is not recognized, got "..tostring(group), 2) return end
    
        self.group = group
    end,
}

methods_achievement_callbacks = {
    onCompleted = function(self, func) self:add_callback("onCompleted", func) end,
}


-- ========== Metatables ==========

metatable_achievement_gs = {
    -- Getter
    __index = function(table, key)
        local index = Achievement.ARRAY[key]
        if index then
            local achievement_array = Class.ACHIEVEMENT:get(table.value)
            return achievement_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Achievement.ARRAY[key]
        if index then
            local achievement_array = Class.ACHIEVEMENT:get(table.value)
            achievement_array:set(index, value)
        end
    end
}

metatable_achievement_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_achievement_callbacks[key] then
            return methods_achievement_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_achievement_gs.__index(table, key)
    end
}

metatable_achievement = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_achievement[key] then
            return methods_achievement[key]
        end

        -- Pass to next metatable
        return metatable_achievement_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end

        metatable_achievement_gs.__newindex(table, key, value)
    end
}


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value) --(is_active)
        end
    end
end)