-- Environment_Log

Environment_Log = class_refs["Environment_Log"]



-- ========== Static Methods ==========

Environment_Log.new = function(stage, sprite_icon, is_secret)
    
    if type(stage) ~= "table" or stage.RMT_object ~= "Stage" then log.error("Stage is not a RMT item, got a "..type(stage), 2) return end
    if type(sprite_icon) ~= "number" or type(sprite_icon) ~= "nil" then log.error("Sprite should be a number, got a "..type(sprite_icon), 2) return end
    if type(is_secret) ~= "boolean" or type(is_secret) ~= "nil" then log.error("Is Secret should be a boolean, got a "..type(is_secret), 2) return end
    
    -- Check if environment_log already exist
    local environment_log = Environment_Log.find(stage.namespace, stage.identifier)
    if environment_log then return environment_log end

    -- Create environment_log
    environment_log = Environment_Log.wrap(
        gm.environment_log_create(
            stage.namespace,      -- Namespace
            stage.identifier      -- Identifier
        )
    )

    -- Make environment_log abstraction
    local abstraction = Environment_Log.wrap(environment_log)

    -- Set the log sprite icon
    abstraction.spr_icon = sprite_icon or gm.constants.sEnvironmentDesolateForest

    -- Set if the log is secret
    abstraction.is_secret = is_secret or false

    -- Set the log id of the stage
    stage.log_id = environment_log.value

    -- Set the room list
    local display_room_ids = List.wrap(environment_log.display_room_ids)
    for num, room in ipairs(stage.room_list) do
        display_room_ids:add(room)
        gm.room_associate_environment_log(room, stage.log_id, num)
    end

    return environment_log
end


-- ========== Instance Methods ==========

methods_environment_log = {

    add_room = function(self, stage)

        if type(stage) ~= "table" or item.RMT_object ~= "Stage" then log.error("Stage is not a RMT Stage, got a "..type(stage), 2) return end
        
        local roomList = List.wrap(self.display_room_ids)
        local stageRoomList = List.wrap(stage.room_list)

        for num = #roomList, #stageRoomList do
            roomList:add(stageRoomList[num+1])
            gm.room_associate_environment_log(stageRoomList[num+1], self.value, num)
        end
    end,

    clear_room = function(self)
        local roomList = List.wrap(self.display_room_ids)
        roomList:clear()
    end,

    set_log_icon = function(self, sprite_icon)
        if type(sprite_icon) ~= "number" then log.error("Sprite Icon should be a number, got a "..type(sprite_icon), 2) return end
        
        self.spr_icon = sprite_icon
    end,


    set_log_view_start = function(self, camx, camy)
        if type(camx) ~= "number" then log.error("CamX should be a number, got a "..type(camx), 2) return end
        if type(camy) ~= "number" then log.error("CamY should be a number, got a "..type(camy), 2) return end
        
        self.initial_cam_x_1080, self.initial_cam_x_720 = x, x
        self.initial_cam_y_1080, self.initial_cam_y_720 = y, y
    end,


    set_log_secret = function(self, is_secret)
        if type(is_secret) ~= "boolean" then log.error("Is Secret should be a boolean, got a "..type(is_secret), 2) return end
        
        self.is_secret = is_secret
    end,
}



-- ========== Metatables ==========

metatable_class["Environment_Log"] = {
    __index = function(table, key)
        -- Methods
        if methods_environment_log[key] then
            return methods_environment_log[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Environment_Log"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Environment_Log"].__newindex(table, key, value)
    end,


    __metatable = "Environment_Log"
}



return Environment_Log