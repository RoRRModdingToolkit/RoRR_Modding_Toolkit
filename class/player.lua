-- Player

Player = Proxy.new()

local auto_callbacks = {}



-- ========== Static Methods ==========

Player.get_client = function()
    local players = Instance.find_all(gm.constants.oP)

    -- Return the first player if there is only one player
    if #players == 1 then return players[1] end

    -- Loop through players and return the one that "is_local"
    for _, p in ipairs(players) do
        if p.is_local then
            return p
        end
    end

    -- None
    return Instance.wrap_invalid()
end


Player.get_host = function()
    -- Return the player that has an m_id of 1.0
    local players = Instance.find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.m_id == 1.0 then
            return p
        end
    end

    -- None
    return Instance.wrap_invalid()
end


Player.get_from_name = function(name)
    local players = Instance.find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.user_name == name then
            return p
        end
    end

    -- None
    return Instance.wrap_invalid()
end


Player.add_callback = function(callback, id, func, skill)
    table.insert(auto_callbacks, {
        callback,
        id,
        func,
        skill
    })
end


Player.remove_callback = function(id)
    for n, c in ipairs(auto_callbacks) do
        if c[2] == id then
            table.remove(auto_callbacks, n)
            return
        end
    end
end


Player.callback_exists = function(id)
    for n, c in ipairs(auto_callbacks) do
        if c[2] == id then return true end
    end
    return false
end



-- ========== Instance Methods ==========

methods_player = {

    get_equipment = function(self)
        local equip = gm.equipment_get(self.value)
        if equip >= 0 then
            return Equipment.wrap(equip)
        end
        return nil
    end,


    set_equipment = function(self, equipment)
        gm.equipment_set(self.value, Wrap.unwrap(equipment))
    end,


    get_equipment_cooldown = function(self)
        return gm.player_get_equipment_cooldown(self.value)
    end,


    reduce_equipment_cooldown = function(self, amount)
        gm.player_grant_equipment_cooldown_reduction(self.value, amount)
    end,


    get_equipment_use_direction = function(self)
        local num = self.value:player_util_local_player_get_equipment_activation_direction()
        local bool = true
        if num == true then num = 1.0 end
        if num == false then num = -1.0 end
        if num == -1.0 then bool = false end
        return num, bool
    end

}


methods_player_callbacks = {}

for c, _ in pairs(instance_valid_callbacks) do
    methods_player_callbacks[c] = function(self, id, func, skill)
        Player.add_callback(c, id, func, skill)
    end
end



-- ========== Metatables ==========

metatable_player = {
    __index = function(table, key)
        -- Methods
        if methods_player[key] then
            return methods_player[key]
        end

        -- Pass to next metatable
        return metatable_actor.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end,


    __metatable = "player"
}


metatable_player_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_player_callbacks[key] then
            return methods_player_callbacks[key]
        end
    end,

    __metatable = "player_callbacks"
}
Player:setmetatable(metatable_player_callbacks)



-- ========== Initialize ==========

Callback.add("onGameStart", "RMT-player_addAutoCallbacks", function(self, other, result, args)
    Alarm.create(function()
        local player = Player.get_client()
        if player:exists() then
            for _, c in ipairs(auto_callbacks) do
                player:add_callback(c[1], c[2], c[3], c[4])
            end
        end
    end, 1)
end)

Player:onPreStep("RMT-player_skillOverrideFreezePrevSkillCooldown", function(actor)
    for slot = 0, 3 do
        local skills_slot = actor.skills:get(slot)
        local overrides = skills_slot.overrides
        local size = gm.array_length(overrides)
        if size > 0 then
            -- Freeze default skill cd
            local struct = skills_slot.default_skill
            struct.freeze_cooldown(struct, actor.value)

            -- Freeze other override cds
            local struct = skills_slot.active_skill
            for i = 0, size - 1 do
                local override_skill = gm.array_get(overrides, i).skill
                if struct ~= override_skill then
                    override_skill.freeze_cooldown(override_skill, actor.value)
                end
            end
        end
    end
end)



return Player