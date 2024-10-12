-- Survivor_Log

Survivor_Log = class_refs["Survivor_Log"]



-- ========== Static Methods ==========

Survivor_Log.new = function(survivor, portrait_id, portrait_index)
    
    if type(survivor) ~= "table" or survivor.RMT_object ~= "Survivor" then log.error("Survivor is not a RMT survivor, got a "..type(survivor), 2) return end
    if type(portrait_id) ~= "number" and type(portrait_id) ~= "nil" then log.error("Portrait ID is not a number, got a "..type(portrait_id), 2) return end
    if type(portrait_index) ~= "number" and type(portrait_index) ~= "nil" then log.error("Portrait Index is not a number, got a "..type(portrait_index), 2) return end
    
    -- Check if survivor_log already exist
    local survivor_log = Survivor_Log.find(survivor.namespace, survivor.identifier)
    if survivor_log then return survivor_log end
    
    -- Create survivor_log
    survivor_log = gm.survivor_log_create(survivor.namespace, survivor.identifier, survivor.value, portrait_index or 0)

    -- Make survivor_log abstraction
    local abstraction = Survivor_Log.wrap(survivor_log)

    -- Set the name of the log
    abstraction.token_name = survivor.token_name

    -- Set the Big Portrait of the log
    abstraction.portrait_id = portrait_id or abstraction.portrait_id

    -- Set sprite icon id
    abstraction.sprite_icon_id = survivor.sprite_portrait

    -- Set sprite id (walk)
    abstraction.sprite_id = survivor.sprite_title

    -- Get the survivor's stats base and level (only give right value for custom survivor)
    local stats_base = survivor:get_stats_base()
    local stats_level = survivor:get_stats_level()

    -- Set the stats of the survivor log
    gm.survivor_log_set_stats(
        abstraction.value,
        stats_base.maxhp, stats_level.maxhp,
        stats_base.damage, stats_level.damage,
        stats_base.regen * 60, stats_level.regen * 60,
        stats_base.armor, stats_level.armor
    )

    survivor.log_id = abstraction.value

    return abstraction
end



-- ========== Instance Methods ==========

methods_survivor_log = {

    -- set_text = function(self, story, id, departed, arrival)
    --     self.token_story = story
    --     self.token_id  = id
    --     self.token_departed  = departed
    --     self.token_arrival  = arrival
    -- end,
}
methods_class_lock["Survivor_Log"] = Helper.table_get_keys(methods_survivor_log)



-- ========== Metatables ==========

metatable_class["Survivor_Log"] = {
    __index = function(table, key)
        -- Methods
        if methods_survivor_log[key] then
            return methods_survivor_log[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Survivor_Log"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Survivor_Log"].__newindex(table, key, value)
    end,


    __metatable = "survivor_log"
}



return Survivor_Log