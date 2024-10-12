-- Artifact

Artifact = class_refs["Artifact"]

local callbacks = {}

local other_callbacks = {
    "onStep",
    "preStep",
    "postStep",
    "onDirectorPopulateSpawnArrays",
    "onStageStart",
    "onSecond",
    "onMinute",
    "onAttackCreate",
    "onAttackHit",
    "onAttackHandleStart",
    "onAttackHandleEnd",
    "onDamageBlocked",
    "onEnemyInit",
    "onEliteInit",
    "onDeath",
    "onPlayerInit",
    "onPlayerStep",
    "prePlayerHUDDraw",
    "onPlayerHUDDraw",
    "onPlayerInventoryUpdate",
    -- "onPlayerDeath",
    "onCheckpointRespawn",
    "onPickupCollected",
    "onPickupRoll",
    "onEquipmentUse",
    "postEquipmentUse",
    "onInteractableActivate",
    "onHitProc",
    "onDamagedProc",
    "onKillProc"
}



-- ========== Static Methods ==========

Artifact.new = function(namespace, identifier)
    -- Check if artifact already exist
    local artifact = Artifact.find(namespace, identifier)
    if artifact then return artifact end
    
    -- Create artifact
    artifact = gm.artifact_create(namespace, identifier)

    -- Make artifact abstraction
    local abstraction = Artifact.wrap(artifact)

    return abstraction
end

Artifact.new_skin = function(achievement)
    if not achievement then
        Class.ARTIFACT:push(0.0)
    else
        local artifact_skin = Array.new(10)
        artifact_skin:set(9, achievement.value)
        Class.ARTIFACT:push(artifact_skin)
    end

    return Class.ARTIFACT:size() - 1
end


-- ========== Instance Methods ==========

methods_artifact = {

    add_callback = function(self, callback, func)

        if callback == "onSetActive" then
            local callback_id = self.on_set_active
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        elseif Helper.table_has(other_callbacks, callback) then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], func)
        else log.error("Invalid callback name", 2) end
    end,

    set_text = function(self, name, pickup_name, desc)
        self.token_name = name
        self.token_pickup_name = pickup_name
        self.token_description  = desc
    end,

    set_sprites = function(self, loadout, pickup)
        self.loadout_sprite_id = loadout
        self.pickup_sprite_id = pickup
    end,



    -- Callbacks
    onSetActive                     = function(self, func) self:add_callback("onSetActive", func) end,
    onStep                          = function(self, func) self:add_callback("onStep", func) end,
    preStep                         = function(self, func) self:add_callback("preStep", func) end,
    postStep                        = function(self, func) self:add_callback("postStep", func) end,
    onDirectorPopulateSpawnArrays   = function(self, func) self:add_callback("onDirectorPopulateSpawnArrays", func) end,
    onStageStart                    = function(self, func) self:add_callback("onStageStart", func) end,
    onSecond                        = function(self, func) self:add_callback("onSecond", func) end,
    onMinute                        = function(self, func) self:add_callback("onMinute", func) end,
    onAttackCreate                  = function(self, func) self:add_callback("onAttackCreate", func) end,
    onAttackHit                     = function(self, func) self:add_callback("onAttackHit", func) end,
    onAttackHandleStart             = function(self, func) self:add_callback("onAttackHandleStart", func) end,
    onAttackHandleEnd               = function(self, func) self:add_callback("onAttackHandleEnd", func) end,
    onDamageBlocked                 = function(self, func) self:add_callback("onDamageBlocked", func) end,
    onEnemyInit                     = function(self, func) self:add_callback("onEnemyInit", func) end,
    onEliteInit                     = function(self, func) self:add_callback("onEliteInit", func) end,
    onDeath                         = function(self, func) self:add_callback("onDeath", func) end,
    onPlayerInit                    = function(self, func) self:add_callback("onPlayerInit", func) end,
    onPlayerStep                    = function(self, func) self:add_callback("onPlayerStep", func) end,
    prePlayerHUDDraw                = function(self, func) self:add_callback("prePlayerHUDDraw", func) end,
    onPlayerHUDDraw                 = function(self, func) self:add_callback("onPlayerHUDDraw", func) end,
    onPlayerInventoryUpdate         = function(self, func) self:add_callback("onPlayerInventoryUpdate", func) end,
    -- onPlayerDeath                   = function(self, func) self:add_callback("onPlayerDeath", func) end,
    onCheckpointRespawn             = function(self, func) self:add_callback("onCheckpointRespawn", func) end,
    onPickupCollected               = function(self, func) self:add_callback("onPickupCollected", func) end,
    onPickupRoll                    = function(self, func) self:add_callback("onPickupRoll", func) end,
    onEquipmentUse                  = function(self, func) self:add_callback("onEquipmentUse", func) end,
    postEquipmentUse                = function(self, func) self:add_callback("postEquipmentUse", func) end,
    onInteractableActivate          = function(self, func) self:add_callback("onInteractableActivate", func) end,
    onHitProc                       = function(self, func) self:add_callback("onHitProc", func) end,
    onDamagedProc                   = function(self, func) self:add_callback("onDamagedProc", func) end,
    onKillProc                      = function(self, func) self:add_callback("onKillProc", func) end
}
methods_class_lock["Artifact"] = Helper.table_get_keys(methods_artifact)



-- ========== Metatables ==========

metatable_class["Artifact"] = {
    __index = function(table, key)
        -- Methods
        if methods_artifact[key] then
            return methods_artifact[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Artifact"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Artifact"].__newindex(table, key, value)
    end,


    __metatable = "artifact"
}


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value) --(is_active)
        end
    end
end)

-- ========== Callbacks ==========

local function artifact_onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onStep"] then
        for _, fn in ipairs(callbacks["onStep"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_preStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["preStep"] then
        for _, fn in ipairs(callbacks["preStep"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_postStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["postStep"] then
        for _, fn in ipairs(callbacks["postStep"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onDirectorPopulateSpawnArrays(self, other, result, args)
    if callbacks["onDirectorPopulateSpawnArrays"] then
        for _, fn in ipairs(callbacks["onDirectorPopulateSpawnArrays"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onStageStart(self, other, result, args)
    if callbacks["onStageStart"] then
        for _, fn in ipairs(callbacks["onStageStart"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onSecond(self, other, result, args)
    if callbacks["onSecond"] then
        for _, fn in ipairs(callbacks["onSecond"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onMinute(self, other, result, args)
    if callbacks["onMinute"] then
        for _, fn in ipairs(callbacks["onMinute"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onAttackCreate(self, other, result, args)
    if callbacks["onAttackCreate"] then
        for _, fn in ipairs(callbacks["onAttackCreate"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onAttackHit(self, other, result, args)
    if callbacks["onAttackHit"] then
        for _, fn in ipairs(callbacks["onAttackHit"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onAttackHandleStart(self, other, result, args)
    if callbacks["onAttackHandleStart"] then
        for _, fn in ipairs(callbacks["onAttackHandleStart"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onAttackHandleEnd(self, other, result, args)
    if callbacks["onAttackHandleEnd"] then
        for _, fn in ipairs(callbacks["onAttackHandleEnd"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onDamageBlocked(self, other, result, args)
    if callbacks["onDamageBlocked"] then
        for _, fn in ipairs(callbacks["onDamageBlocked"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onEnemyInit(self, other, result, args)
    if callbacks["onEnemyInit"] then
        for _, fn in ipairs(callbacks["onEnemyInit"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onEliteInit(self, other, result, args)
    if callbacks["onEliteInit"] then
        for _, fn in ipairs(callbacks["onEliteInit"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onDeath(self, other, result, args)
    if callbacks["onDeath"] then
        for _, fn in ipairs(callbacks["onDeath"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPlayerInit(self, other, result, args)
    if callbacks["onPlayerInit"] then
        for _, fn in ipairs(callbacks["onPlayerInit"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPlayerStep(self, other, result, args)
    if callbacks["onPlayerStep"] then
        for _, fn in ipairs(callbacks["onPlayerStep"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_prePlayerHUDDraw(self, other, result, args)
    if callbacks["prePlayerHUDDraw"] then
        for _, fn in ipairs(callbacks["prePlayerHUDDraw"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPlayerHUDDraw(self, other, result, args)
    if callbacks["onPlayerHUDDraw"] then
        for _, fn in ipairs(callbacks["onPlayerHUDDraw"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPlayerInventoryUpdate(self, other, result, args)
    if callbacks["onPlayerInventoryUpdate"] then
        for _, fn in ipairs(callbacks["onPlayerInventoryUpdate"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPlayerDeath(self, other, result, args)
    print("I AM")
    if callbacks["onPlayerDeath"] then
        print("INSIDE")
        for _, fn in ipairs(callbacks["onPlayerDeath"]) do
            print("UR WALL")
            fn(self, other, result, args)
        end
    end
end

local function artifact_onCheckpointRespawn(self, other, result, args)
    if callbacks["onCheckpointRespawn"] then
        for _, fn in ipairs(callbacks["onCheckpointRespawn"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPickupCollected(self, other, result, args)
    if callbacks["onPickupCollected"] then
        for _, fn in ipairs(callbacks["onPickupCollected"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onPickupRoll(self, other, result, args)
    if callbacks["onPickupRoll"] then
        for _, fn in ipairs(callbacks["onPickupRoll"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onEquipmentUse(self, other, result, args)
    if callbacks["onEquipmentUse"] then
        for _, fn in ipairs(callbacks["onEquipmentUse"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_postEquipmentUse(self, other, result, args)
    if callbacks["postEquipmentUse"] then
        for _, fn in ipairs(callbacks["postEquipmentUse"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onInteractableActivate(self, other, result, args)
    if callbacks["onInteractableActivate"] then
        for _, fn in ipairs(callbacks["onInteractableActivate"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onHitProc(self, other, result, args)
    if callbacks["onHitProc"] then
        for _, fn in ipairs(callbacks["onHitProc"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onDamagedProc(self, other, result, args)
    if callbacks["onDamagedProc"] then
        for _, fn in ipairs(callbacks["onDamagedProc"]) do
            fn(self, other, result, args)
        end
    end
end

local function artifact_onKillProc(self, other, result, args)
    if callbacks["onKillProc"] then
        for _, fn in ipairs(callbacks["onKillProc"]) do
            fn(self, other, result, args)
        end
    end
end

-- ========== Initialize ==========

initialize_artifact = function()
    Callback.add("onStep", "RMT-artifact_onStep", artifact_onStep)
    Callback.add("preStep", "RMT-artifact_preStep", artifact_preStep)
    Callback.add("postStep", "RMT-artifact_postStep", artifact_postStep)
    Callback.add("onDirectorPopulateSpawnArrays", "RMT-artifact_onDirectorPopulateSpawnArrays", artifact_onDirectorPopulateSpawnArrays)
    Callback.add("onStageStart", "RMT-artifact_onStageStart", artifact_onStageStart)
    Callback.add("onSecond", "RMT-artifact_onSecond", artifact_onSecond)
    Callback.add("onMinute", "RMT-artifact_onMinute", artifact_onMinute)
    Callback.add("onAttackCreate", "RMT-artifact_onAttackCreate", artifact_onAttackCreate)
    Callback.add("onAttackHit", "RMT-artifact_onAttackHit", artifact_onAttackHit)
    Callback.add("onAttackHandleStart", "RMT-artifact_onAttackHandleStart", artifact_onAttackHandleStart)
    Callback.add("onAttackHandleEnd", "RMT-artifact_onAttackHandleEnd", artifact_onAttackHandleEnd)
    Callback.add("onDamageBlocked", "RMT-artifact_onDamageBlocked", artifact_onDamageBlocked)
    Callback.add("onEnemyInit", "RMT-artifact_onEnemyInit", artifact_onEnemyInit)
    Callback.add("onEliteInit", "RMT-artifact_onEliteInit", artifact_onEliteInit)
    Callback.add("onDeath", "RMT-artifact_onDeath", artifact_onDeath)
    Callback.add("onPlayerInit", "RMT-artifact_onPlayerInit", artifact_onPlayerInit)
    Callback.add("onPlayerStep", "RMT-artifact_onPlayerStep", artifact_onPlayerStep)
    Callback.add("prePlayerHUDDraw", "RMT-artifact_prePlayerHUDDraw", artifact_prePlayerHUDDraw)
    Callback.add("onPlayerHUDDraw", "RMT-artifact_onPlayerHUDDraw", artifact_onPlayerHUDDraw)
    Callback.add("onPlayerInventoryUpdate", "RMT-artifact_onPlayerInventoryUpdate", artifact_onPlayerInventoryUpdate)
    -- Callback.add("onPlayerDeath", "RMT-artifact_onPlayerDeath", artifact_onPlayerDeath)
    Callback.add("onCheckpointRespawn", "RMT-artifact_onCheckpointRespawn", artifact_onCheckpointRespawn)
    Callback.add("onPickupCollected", "RMT-artifact_onPickupCollected", artifact_onPickupCollected)
    Callback.add("onPickupRoll", "RMT-artifact_onPickupRoll", artifact_onPickupRoll)
    Callback.add("onEquipmentUse", "RMT-artifact_onEquipmentUse", artifact_onEquipmentUse)
    Callback.add("postEquipmentUse", "RMT-artifact_postEquipmentUse", artifact_postEquipmentUse)
    Callback.add("onInteractableActivate", "RMT-artifact_onInteractableActivate", artifact_onInteractableActivate)
    Callback.add("onHitProc", "RMT-artifact_onHitProc", artifact_onHitProc)
    Callback.add("onDamagedProc", "RMT-artifact_onDamagedProc", artifact_onDamagedProc)
    Callback.add("onKillProc", "RMT-artifact_onKillProc", artifact_onKillProc)
end



return Artifact