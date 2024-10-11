-- Environment_Log

Environment_Log = {}

local abstraction_data = setmetatable({}, {__mode = "k"})


-- ========== Enums ==========

Environment_Log.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_story                 = 3,
    stage_id                    = 4,
    display_room_ids            = 5,
    initial_cam_x_1080          = 6,
    initial_cam_y_1080          = 7,
    initial_cam_x_720           = 8,
    initial_cam_y_720           = 9,
    initial_cam_alt_x_1080      = 10,
    initial_cam_alt_y_1080      = 11,
    initial_cam_alt_x_720       = 12,
    initial_cam_alt_y_720       = 13,
    is_secret                   = 14,
    spr_icon                    = 15
}


-- ========== Static Methods ==========

Environment_Log.find = function(namespace, identifier)
    local id_string = namespace.."-"..identifier
    
    for i, environment_log in ipairs(Class.ENVIRONMENT_LOG) do
        local _namespace = environment_log:get(0)
        local _identifier = environment_log:get(1)
        if namespace == _namespace.."-".._identifier then
            return Environment_Log.wrap(i - 1)
        end
    end
    
    return nil
end

Environment_Log.wrap = function(environment_log_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Environment_Log",
        value = environment_log_id
    }
    setmetatable(abstraction, metatable_environment_log)
    
    return abstraction
end

Environment_Log.new = function(stage)
    
    if type(stage) ~= "table" or stage.RMT_object ~= "Stage" then log.error("Stage is not a RMT item, got a "..type(stage), 2) return end
    
    -- Check if environment_log already exist
    local environment_log = Environment_Log.find(stage.namespace, stage.identifier)
    if environment_log then return environment_log end

    -- Create environment_log
    environment_log = gm.environment_log_create(stage.namespace, stage.identifier)

    -- Make environment_log abstraction
    local abstraction = Environment_Log.wrap(environment_log)

    -- Set the log id of the stage
    stage.log_id = abstraction.value

    -- Set the room list
    local display_room_ids = List.wrap(abstraction.display_room_ids)
    for num, room in ipairs(stage.room_list) do
        display_room_ids:add(room)
        gm.room_associate_environment_log(room, stage.log_id, num)
    end

    return abstraction
end


-- ========== Instance Methods ==========

methods_environment_log = {

    add_room = function(self, ...)
        local roomList = List.wrap(self.display_room_ids)

        local t = {...}
        if type(t[1]) == "table" then t = t[1] end

        for _, path in ipairs(t) do
            local num = #roomList

            roomList:add(room)
            gm.room_associate_environment_log(room, self.value, num)
        end
    end,

    clear_room = function(self)
        local roomList = List.wrap(self.display_room_ids)
        roomList:clear()
    end,

    set_log_icon = function(self, sprite)
        if type(sprite) ~= "number" then log.error("Sprite should be a number, got a "..type(sprite), 2) return end
        
        self.spr_icon = sprite
    end,


    set_log_view_start = function(self, camx, camy)
        if type(camx) ~= "number" then log.error("CamX should be a number, got a "..type(camx), 2) return end
        if type(camy) ~= "number" then log.error("CamY should be a number, got a "..type(camy), 2) return end
        
        self.initial_cam_x_1080, self.initial_cam_x_720 = x, x
        self.initial_cam_y_1080, self.initial_cam_y_720 = y, y
    end,


    set_log_secret = function(self, issecret)
        if type(issecret) ~= "boolean" then log.error("Is Hidden should be a boolean, got a "..type(issecret), 2) return end
        
        self.is_secret = issecret
    end,
}


-- ========== Metatables ==========

metatable_environment_log_gs = {
    -- Getter
    __index = function(table, key)
        local index = Environment_Log.ARRAY[key]
        if index then
            local environment_log_array = Class.ENVIRONMENT_LOG:get(table.value)
            return Wrap.wrap(environment_log_array:get(index))
        end
        log.warning("Non-existent environment log property")
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Environment_Log.ARRAY[key]
        if index then
            local environment_log_array = Class.ENVIRONMENT_LOG:get(table.value)
            environment_log_array:set(index, Wrap.unwrap(value))
        end
        log.warning("Non-existent environment log property")
    end
}

metatable_environment_log = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_environment_log[key] then
            return methods_environment_log[key]
        end

        -- Pass to next metatable
        return metatable_environment_log_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.warning("Cannot modify RMT object values")
            return
        end

        metatable_environment_log_gs.__newindex(table, key, value)
    end
}