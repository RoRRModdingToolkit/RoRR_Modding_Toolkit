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
    if Survivor.find(namespace, identifier) then return nil end

    -- Create survivor
    local survivor = gm.survivor_create(namespace, identifier)

    -- Make survivor abstraction
    local abstraction = Survivor.wrap(survivor)

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