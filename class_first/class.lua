-- Class

Class = Proxy.new()

local class_arrays = {
    "class_achievement",
    "class_actor_skin",
    "class_actor_state",
    "class_artifact",
    "class_buff",
    "class_callback",
    "class_difficulty",
    "class_elite",
    "class_ending_type",
    "class_environment_log",
    "class_equipment",
    "class_game_mode",
    "class_interactable_card",
    "class_item",
    "class_item_log",
    "class_monster_card",
    "class_monster_log",
    "class_skill",
    "class_stage",
    "class_survivor",
    "class_survivor_log"
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

for _, class in ipairs(class_arrays) do
    class = capitalize_class_name(class:sub(7, #class))

    local t = Proxy.new()

    t.ARRAY = properties[class]
    
    t.find = function(namespace, identifier)
        if identifier then namespace = namespace.."-"..identifier
        else
            if not string.find(namespace, "-") then namespace = "ror-"..namespace end
        end

        for i = 0, #Class[class] - 1 do
            local element = Class[class]:get(i)
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
                local array = Class[class]:get(table.value)
                return array:get(index)
            end
            log.error("Non-existent "..class.." property", 2)
            return nil
        end,

        -- Setter
        __newindex = function(table, key, value)
            local index = t.ARRAY[key]
            if index then
                local array = Class[class]:get(table.value)
                array:set(index, value)
                return
            end
            log.error("Non-existent "..class.." property", 2)
        end
    }

    class_refs[class] = t
end



return Class