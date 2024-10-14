-- Class

Class = Proxy.new()

local class_arrays = {
    Achievement         = "class_achievement",
    Skin                = "class_actor_skin",
    State               = "class_actor_state",
    Artifact            = "class_artifact",
    Buff                = "class_buff",
    Difficulty          = "class_difficulty",
    Elite               = "class_elite_type",
    Ending              = "class_ending",
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

local class_find_table = {}     -- Hash table for quick lookup for <class>.find()
local class_array_sizes = {}

for k, v in pairs(class_arrays) do
    class_find_table[v] = {}
    class_array_sizes[v] = 0
end



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
        class_wrappers[v:sub(7, #v):upper()] = Array.wrap(gm.variable_global_get(v))
        class_find_repopulate(v)
    end
end



-- ========== Internal ==========

class_find_repopulate = function(class)
    local arr = gm.variable_global_get(class)
    local size = gm.array_length(arr)
    if size ~= class_array_sizes[class] then
        class_array_sizes[class] = size
        local t = class_find_table[class]

        for i = 0, size - 1 do
            local element = gm.array_get(arr, i)
            if gm.is_array(element) then
                local namespace = gm.array_get(element, 0)
                local identifier = gm.array_get(element, 1)
                local full = namespace.."-"..identifier
                t[full] = i
            end
        end
    end
end

gm.post_script_hook(gm.constants.achievement_create,        function() class_find_repopulate("class_achievement") end)
gm.post_script_hook(gm.constants.actor_skin_create,         function() class_find_repopulate("class_actor_skin") end)
gm.post_script_hook(gm.constants.actor_state_create,        function() class_find_repopulate("class_actor_state") end)
gm.post_script_hook(gm.constants.artifact_create,           function() class_find_repopulate("class_artifact") end)
gm.post_script_hook(gm.constants.buff_create,               function() class_find_repopulate("class_buff") end)
gm.post_script_hook(gm.constants.difficulty_create,         function() class_find_repopulate("class_difficulty") end)
gm.post_script_hook(gm.constants.elite_type_create,         function() class_find_repopulate("class_elite_type") end)
gm.post_script_hook(gm.constants.ending_create,             function() class_find_repopulate("class_ending") end)
gm.post_script_hook(gm.constants.environment_log_create,    function() class_find_repopulate("class_environment_log") end)
gm.post_script_hook(gm.constants.equipment_create,          function() class_find_repopulate("class_equipment") end)
gm.post_script_hook(gm.constants.gamemode_create,           function() class_find_repopulate("class_game_mode") end)
gm.post_script_hook(gm.constants.interactable_card_create,  function() class_find_repopulate("class_interactable_card") end)
gm.post_script_hook(gm.constants.item_create,               function() class_find_repopulate("class_item") end)
gm.post_script_hook(gm.constants.item_log_create,           function() class_find_repopulate("class_item_log") end)
gm.post_script_hook(gm.constants.monster_card_create,       function() class_find_repopulate("class_monster_card") end)
gm.post_script_hook(gm.constants.monster_log_create,        function() class_find_repopulate("class_monster_log") end)
gm.post_script_hook(gm.constants.skill_create,              function() class_find_repopulate("class_skill") end)
gm.post_script_hook(gm.constants.stage_create,              function() class_find_repopulate("class_stage") end)
gm.post_script_hook(gm.constants.survivor_create,           function() class_find_repopulate("class_survivor") end)
gm.post_script_hook(gm.constants.survivor_log_create,       function() class_find_repopulate("class_survivor_log") end)



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
for class, class_array_id in pairs(class_arrays) do
    local class_array_id_og = class_array_id
    class_array_id = capitalize_class_name(class_array_id:sub(7, #class_array_id))

    local t = Proxy.new()

    t.ARRAY = Proxy.new(properties[class_array_id]):lock()
    
    t.find = function(namespace, identifier)
        if identifier then namespace = namespace.."-"..identifier
        else
            if not string.find(namespace, "-") then namespace = "ror-"..namespace end
        end

        local element = class_find_table[class_array_id_og][namespace]
        if element then return t.wrap(element) end
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
                local array = Class[class_array_id]:get(table.value)
                return array:get(index)
            end
            log.error("Non-existent "..class.." property", 2)
            return nil
        end,

        -- Setter
        __newindex = function(table, key, value)
            local index = t.ARRAY[key]
            if index then
                local array = Class[class_array_id]:get(table.value)
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