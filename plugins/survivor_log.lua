-- Survivor_Log

Survivor_Log = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}


-- ========== Enums ==========

Survivor_Log.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_story                 = 3,
    token_id                    = 4,
    token_departed              = 5,
    token_arrival               = 6,
    sprite_icon_id              = 7,
    sprite_id                   = 8,
    portrait_id                 = 9,
    portrait_index              = 10,
    stat_hp_base                = 11,
    stat_hp_level               = 12,
    stat_damage_base            = 13,
    stat_damage_level           = 14,
    stat_regen_base             = 15,
    stat_regen_level            = 16,
    stat_armor_base             = 17,
    stat_armor_level            = 18,
    survivor_id                 = 19
}

-- ========== Static Methods ==========

Survivor_Log.find = function(namespace, identifier)
    local id_string = namespace.."-"..identifier
    
    for i, survivor_log in ipairs(Class.SURVIVOR_LOG) do
        local _namespace = survivor_log:get(0)
        local _identifier = survivor_log:get(1)
        if namespace == _namespace.."-".._identifier then
            return Survivor_Log.wrap(i - 1)
        end
    end
    
    return nil
end

Survivor_Log.wrap = function(survivor_log_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Survivor_Log",
        value = survivor_log_id
    }
    setmetatable(abstraction, metatable_survivor_log)
    
    return abstraction
end

-- 
Survivor_Log.new = function(survivor, portrait_id, portrait_index)
    
    if type(survivor) ~= "table" or survivor.RMT_object ~= "Survivor" or not survivor.value then log.error("Survivor is not a RMT survivor, got a "..type(survivor), 2) return end
    if type(portrait_id) ~= "number" and type(portrait_id) ~= "nil" then log.error("Portrait ID is not a number, got a "..type(portrait_id), 2) return end
    if type(portrait_index) ~= "number" and type(portrait_index) ~= "nil" then log.error("Portrait Index is not a number, got a "..type(portrait_index), 2) return end
    
    -- Check if survivor_log already exist
    local survivor_log = Survivor_Log.find(survivor.namespace, survivor.identifier)
    if survivor_log then return survivor_log end
    
    -- Create survivor_log
    survivor_log = gm.survivor_log_create(survivor.namespace, survivor.identifier, survivor.value, portrait_index or 0)

    -- Make survivor_log abstraction
    local abstraction = Survivor_Log.wrap(survivor_log)

    -- Set the name of the log
    abstraction.token_name = survivor.token_name

    -- Set the Big Portrait of the log
    abstraction.portrait_id = portrait_id or abstraction.portrait_id

    -- Set sprite icon id
    abstraction.sprite_icon_id = survivor.sprite_portrait

    -- Set sprite id (walk)
    abstraction.sprite_id = survivor.sprite_title

    -- Get the survivor's stats base and level (only give right value for custom survivor)
    local stats_base = survivor:get_stats_base()
    local stats_level = survivor:get_stats_level()

    -- Set the stats of the survivor log
    gm.survivor_log_set_stats(
        abstraction.value,
        stats_base.maxhp, stats_level.maxhp,
        stats_base.damage, stats_level.damage,
        stats_base.regen * 60, stats_level.regen * 60,
        stats_base.armor, stats_level.armor
    )

    return abstraction
end


-- ========== Instance Methods ==========

methods_survivor_log = {

    set_text = function(self, story, id, departed, arrival)
        self.token_story = story
        self.token_id  = id
        self.token_departed  = departed
        self.token_arrival  = arrival
    end,
}


-- ========== Metatables ==========

metatable_survivor_log_gs = {
    -- Getter
    __index = function(table, key)
        local index = Survivor_Log.ARRAY[key]
        if index then
            local survivor_log_array = Class.SURVIVOR_LOG:get(table.value)
            return survivor_log_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Survivor_Log.ARRAY[key]
        if index then
            local survivor_log_array = Class.SURVIVOR_LOG:get(table.value)
            survivor_log_array:set(index, value)
        end
    end
}

metatable_survivor_log = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_survivor_log[key] then
            return methods_survivor_log[key]
        end

        -- Pass to next metatable
        return metatable_survivor_log_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify wrapper values", 2)
            return
        end

        metatable_survivor_log_gs.__newindex(table, key, value)
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