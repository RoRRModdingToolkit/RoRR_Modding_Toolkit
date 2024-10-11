-- Class

Class = Proxy.new()

local class_arrays = {
    Achievement         = "class_achievement",
    Skin                = "class_actor_skin",
    State               = "class_actor_state",
    Artifact            = "class_artifact",
    Buff                = "class_buff",
    Callback            = "class_callback",
    Difficulty          = "class_difficulty",
    Elite               = "class_elite",
    Ending              = "class_ending_type",
    Environment_Log     = "class_environment_log",
    Equipment           = "class_equipment",
    Gamemode            = "class_game_mode",
    Interactable_Card   = "class_interactable_card",
    Item                = "class_item",
    Item_Log            = "class_item_log",
    Monster_Card        = "class_monster_card",
    Monster_Log         = "class_monster_log",
    Skill               = "class_skill",
    Stage               = "class_stage",
    Survivor            = "class_survivor",
    Survivor_Log        = "class_survivor_log"
}



-- ========== Metatable ==========

metatable_class = {
    __index = function(table, key)
        local k = "class_"..key:lower()
        if Helper.table_has(class_arrays, k) then
            return Array.wrap(gm.variable_global_get(k))
        else log.error("Class does not exist", 2)
        end
    end
}
Class:setmetatable(metatable_class)



-- ========== Class Array Wrapper Bases ==========

-- This class will also initialize the base
-- wrappers for every global "class_" array.

local file_path = _ENV["!plugins_mod_folder_path"].."/class_first/class_array.txt"
local success, file = pcall(toml.decodeFromFile, file_path)
local properties = {}
if success then properties = file.Array end

metatable_class_array = {}

for class, class_arr in pairs(class_arrays) do
    class_arr = capitalize_class_name(class_arr:sub(7, #class_arr))

    local t = Proxy.new()

    t.ARRAY = properties[class_arr]
    
    t.find = function(namespace, identifier)
        if identifier then namespace = namespace.."-"..identifier
        else
            if not string.find(namespace, "-") then namespace = "ror-"..namespace end
        end

        for i = 0, #Class[class_arr] - 1 do
            local element = Class[class_arr]:get(i)
            if gm.is_array(element.value) then
                local _namespace = element:get(0)
                local _identifier = element:get(1)
                if namespace == _namespace.."-".._identifier then
                    return t.wrap(i)
                end
            end
        end

        return nil
    end

    t.wrap = function(value)
        local wrapper = Proxy.new()
        wrapper.RMT_object = class
        wrapper.value = value
        wrapper:setmetatable(metatable_class_array[class])
        wrapper:lock(
            "RMT_object",
            "value"
        )
        return wrapper
    end

    metatable_class_array[class] = {
        -- Getter
        __index = function(table, key)
            local index = t.ARRAY[key]
            if index then
                local array = Class[class_arr]:get(table.value)
                return array:get(index)
            end
            log.error("Non-existent "..class.." property", 2)
            return nil
        end,

        -- Setter
        __newindex = function(table, key, value)
            local index = t.ARRAY[key]
            if index then
                local array = Class[class_arr]:get(table.value)
                array:set(index, value)
                return
            end
            log.error("Non-existent "..class.." property", 2)
        end
    }

    class_refs[class] = t
end



return Class