-- Difficulty

Difficulty = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}
local other_callbacks = {
    "onRunStart",
    "onRunEnd",
    "onStep",
    "onDraw"
}



-- ========== Enums ==========

Difficulty.ARRAY = {
    namespace               = 0,
    identifier              = 1,
    token_name              = 2,
    token_description       = 3,
    sprite_id               = 4,
    sprite_loadout_id       = 5,
    primary_color           = 6,
    sound_id                = 7,
    diff_scale              = 8,
    general_scale           = 9,
    point_scale             = 10,
    is_monsoon_or_higher    = 11,
    allow_blight_spawns     = 12
}



-- ========== Static Methods ==========

Difficulty.new = function(namespace, identifier)
    local difficulty = Difficulty.find(namespace, identifier)
    if difficulty then return difficulty end

    return Difficulty.wrap(gm.difficulty_create(namespace, identifier))
end


Difficulty.find = function(namespace, identifier)
    local id_string = namespace
    
    if identifier then id_string = namespace.."-"..identifier end
    
    local difficulty_id = gm.difficulty_find(id_string)

    if not difficulty_id then return nil end

    return Difficulty.wrap(difficulty_id)
end


Difficulty.wrap = function(difficulty_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Difficulty",
        value = difficulty_id
    }
    setmetatable(abstraction, metatable_difficulty)
    return abstraction
end



-- ========== Instance Methods ==========

methods_difficulty = {

    is_active = function(self)
        return gm._mod_game_getDifficulty() == self.value
    end,


    add_callback = function(self, callback, func)
        if Helper.table_has(other_callbacks, callback) then
            if not callbacks[self.value] then callbacks[self.value] = {} end
            if not callbacks[self.value][callback] then callbacks[self.value][callback] = {} end
            table.insert(callbacks[self.value][callback], func)

        else log.error("Invalid callback name", 2)
        end
    end,


    clear_callbacks = function(self)
        callbacks[self.value] = nil
    end,


    set_text = function(self, name, description)
        self.token_name = name
        self.token_description = description
    end,

    set_sprite = function(self, small, large)
        if type(small) ~= "number" then log.error("Small Sprite ID is not a number, got a "..type(small), 2) return end
        if type(large) ~= "number" then log.error("Large Sprite ID is not a number, got a "..type(large), 2) return end
        
        self.sprite_id = small
        self.sprite_loadout_id = large
    end,

    set_primary_color = function(self, R, G, B)
        self.primary_color = Color.from_rgb(R, G, B)
    end,

    set_sound = function(self, sound_id)
        if type(sound_id) ~= "number" then log.error("Sound ID is not a number, got a "..type(sound_id), 2) return end
        
        self.sound_id = sound_id
    end,

    set_scaling = function(self, difficulty, general, point)
        if type(difficulty) ~= "number" then log.error("Difficulty Scale is not a number, got a "..type(difficulty), 2) return end
        if type(general) ~= "number" then log.error("General Scale is not a number, got a "..type(general), 2) return end
        if type(point) ~= "number" then log.error("Point Scale is not a number, got a "..type(point), 2) return end
        
        self.diff_scale = difficulty
        self.general_scale = general
        self.point_scale = point
    end,

    set_monsoon_or_higher = function(self, monsoon_or_higher)
        if type(monsoon_or_higher) ~= "boolean" then log.error("Monsoon (or Higher) toggle is not a boolean, got a "..type(monsoon_or_higher), 2) return end
        
        self.is_monsoon_or_higher = monsoon_or_higher
    end,

    allow_blight_spawns = function(self, allow_blight_spawns)
        if type(allow_blight_spawns) ~= "boolean" then log.error("Blight Spawns toggle is not a boolean, got a "..type(allow_blight_spawns), 2) return end
        
        self.allow_blight_spawns = allow_blight_spawns
    end
}


methods_difficulty_callbacks = {

    onRunStart      = function(self, func) self:add_callback("onRunStart", func) end,
    onRunEnd        = function(self, func) self:add_callback("onRunEnd", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    onDraw          = function(self, func) self:add_callback("onDraw", func) end

}



-- ========== Metatables ==========

metatable_difficulty_gs = {
    -- Getter
    __index = function(table, key)
        local index = Difficulty.ARRAY[key]
        if index then
            local array = Class.DIFFICULTY:get(table.value)
            return array:get(index)
        end
        log.error("Non-existent difficulty property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Difficulty.ARRAY[key]
        if index then
            local array = Class.DIFFICULTY:get(table.value)
            array:set(index, value)
            return
        end
        log.error("Non-existent difficulty property", 2)
    end
}


metatable_difficulty_callbacks = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_difficulty_callbacks[key] then
            return methods_difficulty_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_difficulty_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_difficulty_gs.__newindex(table, key, value)
    end
}


metatable_difficulty = {
    __index = function(table, key)
        -- Methods
        if methods_difficulty[key] then
            return methods_difficulty[key]
        end

        -- Pass to next metatable
        return metatable_difficulty_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_difficulty_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    for id, content in pairs(callbacks) do
        log.info(content)
        if content["onRunStart"] and Difficulty.wrap(id):is_active() then
            for _, fn in ipairs(content["onRunStart"]) do
                log.info("run")
                fn()
            end
        end
    end
end)


gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    for id, content in pairs(callbacks) do
        if content["onRunEnd"] and Difficulty.wrap(id):is_active() then
            for _, fn in ipairs(content["onRunEnd"]) do
                fn()
            end
        end
    end
end)



-- ========== Callbacks ==========

local function diff_onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    for id, content in pairs(callbacks) do
        if content["onStep"] and Difficulty.wrap(id):is_active() then
            for _, fn in ipairs(content["onStep"]) do
                fn()
            end
        end
    end
end


local function diff_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    for id, content in pairs(callbacks) do
        if content["onDraw"] and Difficulty.wrap(id):is_active() then
            for _, fn in ipairs(content["onDraw"]) do
                fn()
            end
        end
    end
end



-- ========== Initialize ==========

Difficulty.__initialize = function()
    Callback.add("preStep", "RMT.diff_onStep", diff_onStep, true)
    Callback.add("postHUDDraw", "RMT.diff_onDraw", diff_onDraw, true)
end
