-- Difficulty

Difficulty = class_refs["Difficulty"]

local callbacks = {}
local other_callbacks = {
    "onActive",
    "onInactive",
    "onStep",
    "onDraw"
}

local active = -1.0



-- ========== Static Methods ==========

Difficulty.new = function(namespace, identifier)
    -- Check if difficulty already exist
    local difficulty = Difficulty.find(namespace, identifier)
    if difficulty then return difficulty end

    local difficulty = Difficulty.wrap(
        gm.difficulty_create(
            namespace,      -- Namespace
            identifier      -- Identifier
        )
    )

    class_find_repopulate("Difficulty")
    return difficulty
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


    set_primary_color = function(self, color)
        -- Find a way to check if it is an RMT colour
        self.primary_color = color
    end,

    set_primary_colour = function(self, colour)
        self:set_primary_color(colour)
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


    set_allow_blight_spawns = function(self, allow_blight_spawns)
        if type(allow_blight_spawns) ~= "boolean" then log.error("Blight Spawns toggle is not a boolean, got a "..type(allow_blight_spawns), 2) return end
        
        self.allow_blight_spawns = allow_blight_spawns
    end,


    -- Callbacks
    onActive        = function(self, func) self:add_callback("onActive", func) end,
    onInactive      = function(self, func) self:add_callback("onInactive", func) end,
    onStep          = function(self, func) self:add_callback("onStep", func) end,
    onDraw          = function(self, func) self:add_callback("onDraw", func) end
    
}
class_lock_tables["Difficulty"] = Proxy.make_lock_table({"value", "RMT_object", table.unpack(methods_difficulty)})



-- ========== Metatables ==========

metatable_class["Difficulty"] = {
    __index = function(table, key)
        -- Methods
        if methods_difficulty[key] then
            return methods_difficulty[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Difficulty"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Difficulty"].__newindex(table, key, value)
    end,


    __metatable = "difficulty"
}



-- ========== Callbacks ==========

local function diff_onActive(self, other, result, args)
    local current = gm._mod_game_getDifficulty()

    if current ~= active then
        local content = callbacks[active]
        if content and content["onInactive"] then
            for _, fn in ipairs(content["onInactive"]) do
                fn()
            end
        end

        content = callbacks[current]
        if content and content["onActive"] then
            for _, fn in ipairs(content["onActive"]) do
                fn()
            end
        end

        -- Recalculate all actor stats
        local actors = Instance.find_all(gm.constants.pActor)
        for _, actor in ipairs(actors) do
            actor:recalculate_stats()
        end
    end

    active = current
end


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

initialize_difficulty = function()
    Callback.add("preStep", "RMT-diff_onActive", diff_onActive)
    Callback.add("preStep", "RMT-diff_onStep", diff_onStep)
    Callback.add("postHUDDraw", "RMT-diff_onDraw", diff_onDraw)
end



return Difficulty