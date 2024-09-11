-- Artifact

Artifact = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}


-- ========== Enums ==========

Artifact.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_pickup_name           = 3,
    token_description           = 4,
    loadout_sprite_id           = 5,
    pickup_sprite_id            = 6,
    on_set_active               = 7,
    active                      = 8,
    achievement_id              = 9
}

-- ========== Static Methods ==========

Artifact.find = function(namespace, identifier)
    local id_string = namespace.."-"..identifier
    local artifact_id = gm.artifact_find(id_string)

    if not artifact_id then return nil end

    return Artifact.wrap(artifact_id)
end

Artifact.wrap = function(artifact_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_wrapper = "Artifact",
        value = artifact_id
    }
    setmetatable(abstraction, metatable_artifact)
    
    return abstraction
end

Artifact.new = function(namespace, identifier)
    -- Check if artifact already exist
    local artifact = Artifact.find(namespace, identifier)
    if artifact then return artifact end
    
    -- Create artifact
    artifact = gm.artifact_create(namespace, identifier)

    -- Make artifact abstraction
    local abstraction = Artifact.wrap(artifact)

    return abstraction
end

Artifact.new_skin = function(achievement)
    if not achievement then
        Class.ARTIFACT:push(0.0)
    else
        local artifact_skin = Array.new(10)
        artifact_skin:set(9, achievement.value)
        Class.ARTIFACT:push(artifact_skin)
    end

    return Class.ARTIFACT:size() - 1
end

Artifact.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_artifact = {

    add_callback = function(self, callback, func)

        if callback == "onSetActive" then
            local callback_id = self.on_set_active
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
    end,

    set_text = function(self, name, pickup_name, desc)
        self.token_name = name
        self.token_pickup_name = pickup_name
        self.token_description  = desc
    end,

    set_sprites = function(self, loadout, pickup)
        self.loadout_sprite_id = loadout
        self.pickup_sprite_id = pickup
    end,
}

methods_artifact_callbacks = {
    onSetActive = function(self, func) self:add_callback("onSetActive", func) end
}


-- ========== Metatables ==========

metatable_artifact_gs = {
    -- Getter
    __index = function(table, key)
        local index = Artifact.ARRAY[key]
        if index then
            local artifact_array = Class.ARTIFACT:get(table.value)
            return artifact_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Artifact.ARRAY[key]
        if index then
            local artifact_array = Class.ARTIFACT:get(table.value)
            artifact_array:set(index, value)
        end
    end
}

metatable_artifact_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_artifact_callbacks[key] then
            return methods_artifact_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_artifact_gs.__index(table, key)
    end
}

metatable_artifact = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_wrapper" then return abstraction_data[table].RMT_wrapper end

        -- Methods
        if methods_artifact[key] then
            return methods_artifact[key]
        end

        -- Pass to next metatable
        return metatable_artifact_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_wrapper" then
            log.error("Cannot modify wrapper values", 2)
            return
        end

        metatable_artifact_gs.__newindex(table, key, value)
    end
}


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value) --(actor, initial_set)
        end
    end
end)