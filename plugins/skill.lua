-- Skill

Skill = {}



-- ========== Enums ==========

Skill.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_description           = 3,
    sprite                      = 4,
    subimage                    = 5,
    cooldown                    = 6,
    damage                      = 7,
    max_stock                   = 8,
    start_with_stock            = 9,
    auto_restock                = 10,
    required_stock              = 11,
    require_key_press           = 12,
    allow_buffered_input        = 13,
    use_delay                   = 14,
    animation                   = 15,
    is_utility                  = 16,
    is_primary                  = 17,
    required_interrupt_priority = 18,
    hold_facing_direction       = 19,
    override_strafe_direction   = 20,
    ignore_aim_direction        = 21,
    disable_aim_stall           = 22,
    does_change_activity_state  = 23,
    on_can_activate             = 24,
    on_activate                 = 25,
    on_step                     = 26,
    on_equipped                 = 27,
    on_unequipped               = 28,
    upgrade_skill               = 29
}


Skill.SLOT = {
    primary     = 0,
    secondary   = 1,
    utility     = 2,
    special     = 3
}



-- ========== Static Methods ==========

Skill.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    for i, skill in ipairs(Class.SKILL) do
        if gm.is_array(skill.value) then    -- There is a random nil(?) value at 186(?) for some reason
            local _namespace = skill:get(0)
            local _identifier = skill:get(1)
            if namespace == _namespace.."-".._identifier then
                return Skill.wrap(i - 1)
            end
        end
    end

    return nil
end


Skill.wrap = function(skill_id)
    local abstraction = {
        RMT_wrapper = "Skill",
        value = skill_id
    }
    setmetatable(abstraction, metatable_skill)
    return abstraction
end



-- ========== Metatables ==========

metatable_skill_gs = {
    -- Getter
    __index = function(table, key)
        local index = Skill.ARRAY[key]
        if index then
            local skill_array = Class.SKILL:get(table.value)
            return skill_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Skill.ARRAY[key]
        if index then
            local skill_array = Class.SKILL:get(table.value)
            skill_array:set(index, value)
        end
    end
}


metatable_skill = {
    __index = function(table, key)
        -- Methods
        -- if methods_skill[key] then
        --     return methods_skill[key]
        -- end

        -- Pass to next metatable
        return metatable_skill_gs.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_skill_gs.__newindex(table, key, value)
    end
}