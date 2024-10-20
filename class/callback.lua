-- Callback

Callback = Proxy.new()

local callbacks = {}



-- ========== Enums ==========

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
    local callback_id = Callback.TYPE[callback]
    if not callback_id then log.error("Invalid callback name", 2) end

    if not callbacks[callback_id] then callbacks[callback_id] = {} end
    if callbacks[callback_id][id] and id:sub(1, 3) == "RMT" then log.error("Cannot overwrite RMT callbacks", 2) end
    callbacks[callback_id][id] = func
end


Callback.remove = function(id)
    if id:sub(1, 3) == "RMT" then log.error("Cannot remove RMT callbacks", 2) end
    
    for _, c in ipairs(Callback.TYPE) do
        local c_table = callbacks[c]
        if c_table and c_table[id] then
            c_table[id] = nil
        end
    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)



return Callback