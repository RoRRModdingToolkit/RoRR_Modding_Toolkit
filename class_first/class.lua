-- Class

Class = Proxy.new()

local class_arrays = {
    Achievement         = "class_achievement",
    Skin                = "class_actor_skin",
    State               = "class_actor_state",
    Artifact            = "class_artifact",
    Buff                = "class_buff",
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

local class_wrappers = {}



-- ========== Metatable ==========

Class:setmetatable({
    __index = function(table, key)
        key = key:upper()
        if class_wrappers[key] then return class_wrappers[key] end
        log.error("Class does not exist", 2)
    end
})


initialize_class = function()
    for k, v in pairs(class_arrays) do
        class_wrappers[k:upper()] = Array.wrap(gm.variable_global_get(v))
    end
end



-- ========== Class Array Base Implementations ==========

-- This class will also create the base
-- implementations for every global "class_"
-- array, containing "ARRAY", "find", and "wrap".

local file_path = _ENV["!plugins_mod_folder_path"].."/internal/class_array.txt"
local success, file = pcall(toml.decodeFromFile, file_path)
local properties = {}
if success then properties = file.Array end

-- These are to be used by other
-- files that extend these bases
-- See "item.lua" for example (and [Ctrl + F] search for these tables)
metatable_class_gs = Proxy.new()    -- Base getter/setter (immutable)
metatable_class = {}                -- First metatable for each class (goes straight to getter/setter if nil)
-- Also "class_refs"                -- Get existing class table, containing this base setup

-- NOTE: You can override "find" and "wrap" if you want to
-- (e.g., special edge case for the class)

-- Loop and create class bases
for class, class_arr in pairs(class_arrays) do
    class_arr = capitalize_class_name(class_arr:sub(7, #class_arr))

    local t = Proxy.new()

    t.ARRAY = Proxy.new(properties[class_arr]):lock()
    
    t.find = function(namespace, identifier)
        if identifier then namespace = namespace.."-"..identifier
        else
            if not string.find(namespace, "-") then namespace = "ror-"..namespace end
        end

        -- This is way faster since it doesn't have to wrap every array in the class_array
        local class_raw = Class[class_arr].value
        local size = gm.array_length(class_raw)
        for i = 0, size - 1 do
            local element = gm.array_get(class_raw, i)
            if gm.is_array(element) then
                local _namespace = gm.array_get(element, 0)
                local _identifier = gm.array_get(element, 1)
                if namespace == _namespace.."-".._identifier then
                    return t.wrap(i)
                end
            end
        end

        -- for i = 0, #Class[class_arr] - 1 do
        --     local element = Class[class_arr]:get(i)
        --     if gm.is_array(element.value) then
        --         local _namespace = element:get(0)
        --         local _identifier = element:get(1)
        --         if namespace == _namespace.."-".._identifier then
        --             return t.wrap(i)
        --         end
        --     end
        -- end

        return nil
    end

    t.wrap = function(value)
        local mt = metatable_class_gs[class]
        if metatable_class[class] then mt = metatable_class[class] end
        return make_wrapper(value, class, mt)
    end

    metatable_class_gs[class] = {
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
        end,
        
        __metatable = "class getter/setter"
    }

    class_refs[class] = t
end

metatable_class_gs:lock()



return Class