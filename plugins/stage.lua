-- Stage

Stage = {}

local abstraction_data = setmetatable({}, {__mode = "k"})



-- ========== Enums ==========

Stage.ARRAY = {
    namespace                       = 0,
    identifier                      = 1,
    token_name                      = 2,
    token_subname                   = 3,
    spawn_enemies                   = 4,
    spawn_enemies_loop              = 5,
    spawn_interactables             = 6,
    spawn_interactables_loop        = 7,
    spawn_interactable_rarity       = 8,
    interactable_spawn_points       = 9,
    allow_mountain_shrine_spawn     = 10,
    classic_variant_count           = 11,
    is_new_stage                    = 12,
    room_list                       = 13,
    music_id                        = 14,
    teleporter_index                = 15,
    populate_biome_properties       = 16,
    log_id                          = 17
}



-- ========== Static Methods ==========

Stage.new = function(namespace, identifier)
    local stage = Stage.find(namespace, identifier)
    if stage then return stage end

    -- return Interactable_Card.wrap(gm.interactable_card_create(namespace, identifier))
end


Stage.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local stage = gm.stage_find(namespace)

    if stage then return Stage.wrap(stage) end
    return nil
end


Stage.wrap = function(stage_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Stage",
        value = stage_id
    }
    setmetatable(abstraction, metatable_stage)
    return abstraction
end



-- ========== Metatables ==========

metatable_stage_gs = {
    -- Getter
    __index = function(table, key)
        local index = Stage.ARRAY[key]
        if index then
            local array = Class.STAGE:get(table.value)
            return array:get(index)
        end
        log.error("Non-existent stage property", 2)
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Stage.ARRAY[key]
        if index then
            local array = Class.STAGE:get(table.value)
            array:set(index, value)
            return
        end
        log.error("Non-existent stage property", 2)
    end
}


metatable_stage = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        -- if methods_stage[key] then
        --     return methods_stage[key]
        -- end

        -- Pass to next metatable
        return metatable_stage_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end
        
        metatable_stage_gs.__newindex(table, key, value)
    end
}