-- Callback

Callback = Proxy.new()

local callbacks = {}



-- ========== Enums and Tables ==========

-- Manual population due to at least one report of "callback_names" being empty at runtime
Callback.TYPE = Proxy.new({
    onLoad                          = 0,
    postLoad                        = 1,
    onStep                          = 2,
    preStep                         = 3,
    postStep                        = 4,
    onDraw                          = 5,
    preHUDDraw                      = 6,
    onHUDDraw                       = 7,
    postHUDDraw                     = 8,
    camera_onViewCameraUpdate       = 9,
    onScreenRefresh                 = 10,
    onGameStart                     = 11,
    onGameEnd                       = 12,
    onDirectorPopulateSpawnArrays   = 13,
    onStageStart                    = 14,
    onSecond                        = 15,
    onMinute                        = 16,
    onAttackCreate                  = 17,
    onAttackHit                     = 18,
    onAttackHandleStart             = 19,
    onAttackHandleEnd               = 20,
    onDamageBlocked                 = 21,
    onEnemyInit                     = 22,
    onEliteInit                     = 23,
    onDeath                         = 24,
    onPlayerInit                    = 25,
    onPlayerStep                    = 26,
    prePlayerHUDDraw                = 27,
    onPlayerHUDDraw                 = 28,
    onPlayerInventoryUpdate         = 29,
    onPlayerDeath                   = 30,
    onCheckpointRespawn             = 31,
    onInputPlayerDeviceUpdate       = 32,
    onPickupCollected               = 33,
    onPickupRoll                    = 34,
    onEquipmentUse                  = 35,
    postEquipmentUse                = 36,
    onInteractableActivate          = 37,
    onHitProc                       = 38,
    onDamagedProc                   = 39,
    onKillProc                      = 40,
    net_message_onReceived          = 41,
    console_onCommand               = 42
}):lock()


Callback.arg_keys = Proxy.new({
    {}, -- 0
    {}, -- 1
    {}, -- 2
    {}, -- 3
    {}, -- 4
    {}, -- 5
    {}, -- 6
    {}, -- 7
    {}, -- 8
    {}, -- 9
    {}, -- 10
    {}, -- 11
    {}, -- 12
    {}, -- 13
    {}, -- 14
    {"", ""},                                       -- 15
    {"", ""},                                       -- 16
    {"attack_info"},                                -- 17
    {"hit_info"},                                   -- 18
    {"attack_info"},                                -- 19
    {"attack_info"},                                -- 20
    {"player", "", "damage"},                       -- 21
    {"actor"},                                      -- 22
    {"actor"},                                      -- 23
    {"actor", "out_of_bounds"},                     -- 24
    {"player"},                                     -- 25
    {"player"},                                     -- 26
    {"player", "", ""},                             -- 27
    {"player", "", ""},                             -- 28
    {"player"},                                     -- 29
    {"player"},                                     -- 30
    {"player"},                                     -- 31
    {""},                                           -- 32
    {"pickup_instance", "player"},                  -- 33
    {""},                                           -- 34
    {"player", "equipment", "", "direction"},       -- 35
    {"player", "equipment", "", "direction"},       -- 36
    {"interactable", "player"},                     -- 37
    {"actor", "victim", "hit_info"},                -- 38
    {"actor", "hit_info"},                          -- 39
    {"victim", "actor"},                            -- 40
    {"packet", "message", "buffer_pos", "sending_player"},  -- 41
    {"string"}                                      -- 42
}):lock()



-- ========== Functions ==========

Callback.add = function(callback, id, func)
    local callback_id = Callback.TYPE[callback]
    if not callback_id then log.error("Invalid callback name", 2) end

    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if callbacks[callback_id][id] and id:sub(1, 3) == "RMT" then log.error("Cannot overwrite RMT callbacks", 2) end
    callbacks[callback_id][id] = func
end


Callback.remove = function(id)
    if id:sub(1, 3) == "RMT" then log.error("Cannot remove RMT callbacks", 2) end
    
    for _, c_id in pairs(Callback.TYPE) do
        local c_table = callbacks[c_id]
        if c_table and c_table[id] then
            c_table[id] = nil
        end
    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local _type = args[1].value
    if callbacks[_type] then

        -- Create wrapped arg_map table out of args
        local arg_types = GM.variable_global_get("class_callback"):get(_type):get(2)    -- Array
        local arg_keys = Callback.arg_keys[_type + 1]
        local arg_map = {}
        local arg_order = {}
        for i, atype in ipairs(arg_types) do
            local key = arg_keys[i]
            local wrapped = args[i + 1].value

            if      atype:match("Instance")     then wrapped = Instance.wrap(wrapped)
            elseif  atype:match("AttackInfo")   then wrapped = Attack_Info.wrap(wrapped)
            elseif  atype:match("HitInfo")      then wrapped = Hit_Info.wrap(wrapped)
            elseif  atype:match("Equipment")    then wrapped = Equipment.wrap(wrapped)
            elseif  key:match("packet")         then wrapped = Packet.wrap(wrapped)
            elseif  key:match("message")        then wrapped = Message.wrap(wrapped)
            end

            arg_map[key] = wrapped
            table.insert(arg_order, key)
        end

        -- Call functions with arg_map
        for _, fn in pairs(callbacks[_type]) do
            fn(arg_map)

            -- Modify arg_map string keys if numerical keys were modified instead
            -- This allows for modifying in arg order like was done before (e.g., "arg_map[1]", similar to "args[2].value")
            -- and exists because not all of args have descriptive key names
            for j = 1, #arg_order do
                if arg_map[j] then
                    arg_map[arg_order[j]] = arg_map[j]
                    arg_map[j] = nil
                end
            end
        end

        -- Slot arg_map changes back into args
        for i, v in ipairs(arg_order) do
            args[i + 1].value = Wrap.unwrap(arg_map[v])
        end

    end
end)



return Callback