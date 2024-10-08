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
    local diff = Difficulty.find(namespace, identifier)
    if diff then return diff end

    local diff = gm.difficulty_create(namespace, identifier)
    return Difficulty.wrap(diff)
end


Difficulty.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local diff = gm.difficulty_find(namespace)

    if diff then return Difficulty.wrap(diff) end
    return nil
end


Difficulty.wrap = function(diff_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Difficulty",
        value = diff_id
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