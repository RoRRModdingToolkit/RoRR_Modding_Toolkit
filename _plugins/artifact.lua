-- Artifact

Artifact = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

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


-- ========== Enums ==========

Artifact.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_pickup_name           = 3,
    token_description           = 4,
    loadout_sprite_id           = 5,
    pickup_sprite_id            = 6,
    on_set_active               = 7,
    active                      = 8,
    achievement_id              = 9
}

-- ========== Static Methods ==========

Artifact.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    local id_string = namespace
    local artifact_id = gm.artifact_find(id_string)

    if not artifact_id then return nil end

    return Artifact.wrap(artifact_id)
end

Artifact.wrap = function(artifact_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Artifact",
        value = artifact_id
    }
    setmetatable(abstraction, metatable_artifact)
    
    return abstraction
end

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

Artifact.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
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
}

methods_artifact_callbacks = {
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


-- ========== Metatables ==========

metatable_artifact_gs = {
    -- Getter
    __index = function(table, key)
        local index = Artifact.ARRAY[key]
        if index then
            local artifact_array = Class.ARTIFACT:get(table.value)
            return artifact_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Artifact.ARRAY[key]
        if index then
            local artifact_array = Class.ARTIFACT:get(table.value)
            artifact_array:set(index, value)
        end
    end
}

metatable_artifact_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_artifact_callbacks[key] then
            return methods_artifact_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_artifact_gs.__index(table, key)
    end
}

metatable_artifact = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Methods
        if methods_artifact[key] then
            return methods_artifact[key]
        end

        -- Pass to next metatable
        return metatable_artifact_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_object" then
            log.error("Cannot modify RMT object values", 2)
            return
        end

        metatable_artifact_gs.__newindex(table, key, value)
    end
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

Artifact.__initialize = function()
    Callback.add("onStep", "RMT.artifact_onStep", artifact_onStep, true)
    Callback.add("preStep", "RMT.artifact_preStep", artifact_preStep, true)
    Callback.add("postStep", "RMT.artifact_postStep", artifact_postStep, true)
    Callback.add("onDirectorPopulateSpawnArrays", "RMT.artifact_onDirectorPopulateSpawnArrays", artifact_onDirectorPopulateSpawnArrays, true)
    Callback.add("onStageStart", "RMT.artifact_onStageStart", artifact_onStageStart, true)
    Callback.add("onSecond", "RMT.artifact_onSecond", artifact_onSecond, true)
    Callback.add("onMinute", "RMT.artifact_onMinute", artifact_onMinute, true)
    Callback.add("onAttackCreate", "RMT.artifact_onAttackCreate", artifact_onAttackCreate, true)
    Callback.add("onAttackHit", "RMT.artifact_onAttackHit", artifact_onAttackHit, true)
    Callback.add("onAttackHandleStart", "RMT.artifact_onAttackHandleStart", artifact_onAttackHandleStart, true)
    Callback.add("onAttackHandleEnd", "RMT.artifact_onAttackHandleEnd", artifact_onAttackHandleEnd, true)
    Callback.add("onDamageBlocked", "RMT.artifact_onDamageBlocked", artifact_onDamageBlocked, true)
    Callback.add("onEnemyInit", "RMT.artifact_onEnemyInit", artifact_onEnemyInit, true)
    Callback.add("onEliteInit", "RMT.artifact_onEliteInit", artifact_onEliteInit, true)
    Callback.add("onDeath", "RMT.artifact_onDeath", artifact_onDeath, true)
    Callback.add("onPlayerInit", "RMT.artifact_onPlayerInit", artifact_onPlayerInit, true)
    Callback.add("onPlayerStep", "RMT.artifact_onPlayerStep", artifact_onPlayerStep, true)
    Callback.add("prePlayerHUDDraw", "RMT.artifact_prePlayerHUDDraw", artifact_prePlayerHUDDraw, true)
    Callback.add("onPlayerHUDDraw", "RMT.artifact_onPlayerHUDDraw", artifact_onPlayerHUDDraw, true)
    Callback.add("onPlayerInventoryUpdate", "RMT.artifact_onPlayerInventoryUpdate", artifact_onPlayerInventoryUpdate, true)
    -- Callback.add("onPlayerDeath", "RMT.artifact_onPlayerDeath", artifact_onPlayerDeath, true)
    Callback.add("onCheckpointRespawn", "RMT.artifact_onCheckpointRespawn", artifact_onCheckpointRespawn, true)
    Callback.add("onPickupCollected", "RMT.artifact_onPickupCollected", artifact_onPickupCollected, true)
    Callback.add("onPickupRoll", "RMT.artifact_onPickupRoll", artifact_onPickupRoll, true)
    Callback.add("onEquipmentUse", "RMT.artifact_onEquipmentUse", artifact_onEquipmentUse, true)
    Callback.add("postEquipmentUse", "RMT.artifact_postEquipmentUse", artifact_postEquipmentUse, true)
    Callback.add("onInteractableActivate", "RMT.artifact_onInteractableActivate", artifact_onInteractableActivate, true)
    Callback.add("onHitProc", "RMT.artifact_onHitProc", artifact_onHitProc, true)
    Callback.add("onDamagedProc", "RMT.artifact_onDamagedProc", artifact_onDamagedProc, true)
    Callback.add("onKillProc", "RMT.artifact_onKillProc", artifact_onKillProc, true)
end