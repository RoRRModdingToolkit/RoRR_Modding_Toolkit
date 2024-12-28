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



-- ========== Functions ==========

Callback.add = function(callback, id, func)
    local _type = callback
    if type(callback) == "string" then _type = Callback.TYPE[callback] end
    if not _type then log.error("Invalid callback name", 2) end

    -- Check if func has correct arg count for that callback
    local count = GM.variable_global_get("class_callback"):get(_type):get(2):size()
    local getinfo = debug.getinfo(func, "u")
    if getinfo.nparams ~= count and (not getinfo.isvararg) then log.error("Callback func has incorrect argument count (should be "..math.floor(count)..")", 2) end

    if not callbacks[_type] then callbacks[_type] = {} end
    if callbacks[_type][id] and id:sub(1, 3) == "RMT" then log.error("Cannot overwrite RMT callbacks", 2) end
    callbacks[_type][id] = func
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

        -- Create wrapped_args table out of args
        local arg_types = GM.variable_global_get("class_callback"):get(_type):get(2)    -- Array
        local wrapped_args = {}
        for i, atype in ipairs(arg_types) do
            local wrapped = args[i + 1].value

            if      atype:match("Instance")     then wrapped = Instance.wrap(wrapped)
            elseif  atype:match("AttackInfo")   then wrapped = Attack_Info.wrap(wrapped)
            elseif  atype:match("HitInfo")      then wrapped = Hit_Info.wrap(wrapped)
            elseif  atype:match("Equipment")    then wrapped = Equipment.wrap(wrapped)
            end

            -- Packet and Message edge cases (41 - net_message_onReceived)
            if _type == Callback.TYPE.net_message_onReceived then
                if      i == 1 then wrapped = Packet.wrap(wrapped)
                elseif  i == 2 then wrapped = Message.wrap(wrapped)
                end
            end

            wrapped_args[i] = wrapped
        end

        -- Call functions
        for id, fn in pairs(callbacks[_type]) do
            fn(table.unpack(wrapped_args))
        end

    end
end)



return Callback