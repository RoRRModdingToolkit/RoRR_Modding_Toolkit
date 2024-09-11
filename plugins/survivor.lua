-- Survivor

Survivor = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}
local instance_callbacks = {}

-- TODO maybe find a better way to do this?
local survivors = {}
local skins = {}


-- ========== Enums ==========

Survivor.ARRAY = {
    namespace                   = 0,
    identifier                  = 1,
    token_name                  = 2,
    token_name_upper            = 3,
    token_description           = 4,
    token_end_quote             = 5,
    skill_family_z              = 6,
    skill_family_x              = 7,
    skill_family_c              = 8,
    skill_family_v              = 9,
    skin_family                 = 10,
    all_loadout_families        = 11,
    all_skill_families          = 12,
    sprite_loadout              = 13,
    sprite_title                = 14,
    sprite_idle                 = 15,
    sprite_portrait             = 16,
    sprite_portrait_small       = 17,
    sprite_palette              = 18,
    sprite_portrait_palette     = 19,
    sprite_loadout_palette      = 20,
    sprite_credits              = 21,
    primary_color               = 22,
    select_sound_id             = 23,
    log_id                      = 24,
    achievement_id              = 25,
    milestone_kills_1           = 26,
    milestone_items_1           = 27,
    milestone_stages_1          = 28,
    on_init                     = 29,
    on_step                     = 30,
    on_remove                   = 31,
    is_secret                   = 32,
    cape_offset                 = 33
}

-- ========== Static Methods ==========

Survivor.find = function(namespace, identifier)
    if identifier then namespace = namespace.."-"..identifier end
    
    for i, survivor in ipairs(Class.SURVIVOR) do
        local _namespace = survivor:get(0)
        local _identifier = survivor:get(1)
        if namespace == _namespace.."-".._identifier then
            return Survivor.wrap(i - 1)
        end
    end
    
    return nil
end

Survivor.wrap = function(survivor_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_wrapper = "Survivor",
        value = survivor_id
    }
    setmetatable(abstraction, metatable_survivor)
    
    return abstraction
end

Survivor.new = function(namespace, identifier)
    -- Check if survivor already exist
    local survivor = Survivor.find(namespace, identifier)
    if survivor then return survivor end
    
    -- Create survivor
    survivor = gm.survivor_create(namespace, identifier)
    
    -- TODO maybe find a better way to do this?
    -- Create default variable for the survivor
    survivors[survivor] = {
        -- Default Scale
        xscale                  = 1.0,
        yscale                  = 1.0,

        -- Default Sprites
        idle                    = gm.constants.sCommandoIdle,
        walk                    = gm.constants.sCommandoWalk,
        walk_last               = gm.constants.sCommandoWalk,
        jump                    = gm.constants.sCommandoJump,
        jump_peak               = gm.constants.sCommandoJumpPeak,
        fall                    = gm.constants.sCommandoFall,
        climb                   = gm.constants.sCommandoClimb,
        death                   = gm.constants.sCommandoDeath,
        decoy                   = gm.constants.sDronePlayerCommandoIdle,
        drone_idle              = gm.constants.sDronePlayerCommandoShoot,
        drone_shoot             = gm.constants.sCommandoDecoy,
        climb_hurt              = -1,
        palette                 = gm.constants.sCommandoPalette,
        
        -- Default Stats Base
        maxhp_base              = 110.0,
        damage_base             = 12.0,
        regen_base              = 0.01,
        attack_speed_base       = 1.0,
        critical_chance_base    = 1.0,
        armor_base              = 0.0,
        maxshield_base          = 0.0,
        pHmax_base              = 2.8,
        pVmax_base              = 6.0,
        pGravity1_base          = 0.52,
        pGravity2_base          = 0.36,
        pAccel_base             = 0.15,
    
        -- Default Stats Level
        maxhp_level             = 32.0,
        damage_level            = 2.0,
        regen_level             = 0.002,
        attack_speed_level      = 0.0,
        critical_chance_level   = 0.0,
        armor_level             = 2.0
    }

    -- Make survivor abstraction
    local abstraction = Survivor.wrap(survivor)

    abstraction:onInit(function(actor)

        -- Survivor scale
        actor.image_xscale          = survivors[actor.class].xscale
        actor.image_yscale          = survivors[actor.class].yscale

        -- Set sprites
        actor.sprite_idle           = survivors[actor.class].idle
        actor.sprite_walk           = survivors[actor.class].walk
        actor.sprite_walk_last      = survivors[actor.class].walk_last
        actor.sprite_jump           = survivors[actor.class].jump
        actor.sprite_jump_peak      = survivors[actor.class].jump_peak
        actor.sprite_fall           = survivors[actor.class].fall
        actor.sprite_climb          = survivors[actor.class].climb
        actor.sprite_death          = survivors[actor.class].death
        actor.sprite_decoy          = survivors[actor.class].decoy
        actor.sprite_drone_idle     = survivors[actor.class].drone_idle
        actor.sprite_drone_shoot    = survivors[actor.class].drone_shoot
        actor.sprite_climb_hurt     = survivors[actor.class].climb_hurt    
        actor.sprite_palette        = survivors[actor.class].palette

        -- Set base stats
        actor.maxhp_base            = survivors[actor.class].maxhp_base
        actor.damage_base           = survivors[actor.class].damage_base
        actor.hp_regen_base         = survivors[actor.class].regen_base
        actor.attack_speed_base     = survivors[actor.class].attack_speed_base
        actor.critical_chance_base  = survivors[actor.class].critical_chance_base
        actor.armor_base            = survivors[actor.class].armor_base
        actor.maxshield_base        = survivors[actor.class].maxshield_base
        actor.pHmax_base            = survivors[actor.class].pHmax_base
        actor.pVmax_base            = survivors[actor.class].pVmax_base
        actor.pGravity1_base        = survivors[actor.class].pGravity1_base
        actor.pGravity2_base        = survivors[actor.class].pGravity2_base
        actor.pAccel_base           = survivors[actor.class].pAccel_base

        -- Set level stats
        actor.maxhp_level           = survivors[actor.class].maxhp_level
        actor.damage_level          = survivors[actor.class].damage_level
        actor.hp_regen_level        = survivors[actor.class].regen_level
        actor.attack_speed_level    = survivors[actor.class].attack_speed_level
        actor.critical_chance_level = survivors[actor.class].critical_chance_level
        actor.armor_level           = survivors[actor.class].armor_level
    end)

    return abstraction
end

Survivor.get_callback_count = function()
    local count = 0
    for k, v in pairs(callbacks) do
        count = count + #v
    end
    return count
end


-- ========== Instance Methods ==========

methods_survivor = {

    add_callback = function(self, callback, func)

        if callback == "onInit" then
            local callback_id = self.on_init
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onStep" then
            local callback_id = self.on_step
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
        if callback == "onRemove" then
            local callback_id = self.on_remove
            if not callbacks[callback_id] then callbacks[callback_id] = {} end
            table.insert(callbacks[callback_id], func)
        end
    end,
    
    -- Put that somewhere else
    add_instance_callback = function(self, func)
        local id = #instance_callbacks + 1
        instance_callbacks[id] = func
        return id
    end,

    add_skill = function(self, skill, skill_family_index, achievement)

        local skill_family = nil
        if skill_family_index == 1 then
            skill_family = self.skill_family_z.elements
        elseif  skill_family_index == 2 then
            skill_family = self.skill_family_x.elements
        elseif skill_family_index == 3 then
            skill_family = self.skill_family_c.elements
        elseif skill_family_index == 4 then
            skill_family = self.skill_family_v.elements
        else
            log.error("Skill Family Index should be between 1 and 4, got "..skill_family_index, 2)
            return
        end

        for _, skill_el in ipairs(skill_family) do
            if skill_el.skill_id == skill.value then return end
        end

        local survivor_loadout_unlockables = gm.variable_global_get("survivor_loadout_unlockables")
        
        local survivor_loadout = gm.struct_create()

        gm.static_set(survivor_loadout, gm.static_get(skill_family[1]))

        survivor_loadout.skill_id = skill.value
        survivor_loadout.achievement_id = (achievement and achievement.value) or -1
        survivor_loadout.save_flag_viewed = nil
        survivor_loadout.index = gm.array_length(survivor_loadout_unlockables)

        gm.array_push(survivor_loadout_unlockables, survivor_loadout)
        gm.array_push(skill_family, survivor_loadout)
    end,

    add_primary = function(self, skill, achievement)
        self:add_skill(skill, 1, achievement)
    end,
    
    add_secondary = function(self, skill, achievement)
        self:add_skill(skill, 2, achievement)
    end,
    
    add_utility = function(self, skill, achievement)
        self:add_skill(skill, 3, achievement)
    end,
    
    add_special = function(self, skill, achievement)
        self:add_skill(skill, 4, achievement)
    end,

    get_skill = function(self, skill_family_index, family_index)
        local skill_family = nil
        if skill_family_index == 1 then
            skill_family = self.skill_family_z.elements
        elseif  skill_family_index == 2 then
            skill_family = self.skill_family_x.elements
        elseif skill_family_index == 3 then
            skill_family = self.skill_family_c.elements
        elseif skill_family_index == 4 then
            skill_family = self.skill_family_v.elements
        else
            log.error("Skill Family Index should be between 1 and 4, got "..skill_family_index, 2)
            return
        end

        family_index = family_index or 1
        if family_index > #skill_family or family_index < 1 then 
            log.error("Family index is out of bound!", 2)
            return nil
        end
        return Skill.wrap(skill_family[family_index].skill_id)
    end,
    
    get_primary = function(self, family_index)
        return self:get_skill(1, family_index)
    end,

    get_secondary = function(self, family_index)
        return self:get_skill(2, family_index)
    end,

    get_utility = function(self, family_index)
        return self:get_skill(3, family_index)
    end,

    get_special = function(self, family_index)
        return self:get_skill(4, family_index)
    end,

    set_animations = function(self, sprites)
        survivors[self.value].idle          = sprites.idle or survivors[self.value].idle
        survivors[self.value].walk          = sprites.walk or survivors[self.value].walk
        survivors[self.value].walk_last     = sprites.walk_last or (sprites.walk or survivors[self.value].walk)
        survivors[self.value].jump          = sprites.jump or survivors[self.value].jump
        survivors[self.value].jump_peak     = sprites.jump_peak or (sprites.jump or survivors[self.value].jump_peak)
        survivors[self.value].fall          = sprites.fall or (sprites.jump or survivors[self.value].fall)
        survivors[self.value].climb         = sprites.climb or survivors[self.value].climb
        survivors[self.value].death         = sprites.death or survivors[self.value].death
        survivors[self.value].decoy         = sprites.decoy or survivors[self.value].decoy
        survivors[self.value].drone_idle    = sprites.drone_idle or survivors[self.value].drone_idle
        survivors[self.value].drone_shoot   = sprites.drone_shoot or survivors[self.value].drone_shoot
        survivors[self.value].climb_hurt    = sprites.climb_hurt or survivors[self.value].climb_hurt
        survivors[self.value].palette       = sprites.palette or survivors[self.value].palette

        self.sprite_palette                 = sprites.palette or survivors[self.value].palette
    end,

    set_primary_color = function(self, R, G, B)
        self.primary_color = Color.from_rgb(R, G, B)
    end,

    set_text = function(self, name, description, end_quote)
        self.token_name = name
        self.token_name_upper = string.upper(name)
        self.token_description = description
        self.token_end_quote = end_quote
    end,

    set_stats_base = function(self, maxhp, damage, regen, armor, attack_speed, critical_chance, maxshield)
        if type(maxhp) ~= "number" and type(maxhp) ~= "nil" then log.error("Max HP base should be a number, got a "..type(maxhp), 2) return end
        if type(damage) ~= "number" and type(damage) ~= "nil" then log.error("Damage base should be a number, got a "..type(damage), 2) return end
        if type(regen) ~= "number" and type(regen) ~= "nil" then log.error("Regen base should be a number, got a "..type(regen), 2) return end
        if type(armor) ~= "number" and type(armor) ~= "nil" then log.error("Armor base should be a number, got a "..type(armor), 2) return end
        if type(attack_speed) ~= "number" and type(attack_speed) ~= "nil" then log.error("Attack Speed base should be a number, got a "..type(attack_speed), 2) return end
        if type(critical_chance) ~= "number" and type(critical_chance) ~= "nil" then log.error("Critical Chance base should be a number, got a "..type(critical_chance), 2) return end
        if type(maxshield) ~= "number" and type(maxshield) ~= "nil" then log.error("Max Shield base should be a number, got a "..type(maxshield), 2) return end

        survivors[self.value].maxhp_base = maxhp or survivors[self.value].maxhp_base
        survivors[self.value].damage_base = damage or survivors[self.value].damage_base
        survivors[self.value].regen_base = regen or survivors[self.value].regen_base
        survivors[self.value].attack_speed_base = attack_speed or survivors[self.value].attack_speed_base
        survivors[self.value].critical_chance_base = critical_chance or survivors[self.value].critical_chance_base
        survivors[self.value].armor_base = armor or survivors[self.value].armor_base
        survivors[self.value].maxshield_base = maxshield or survivors[self.value].maxshield_base
    end,
    
    set_physic_base = function(self, hmax, vmax, gravity1, gravity2, accel)
        if type(hmax) ~= "number" and type(hmax) ~= "nil" then log.error("Hmax base should be a number, got a "..type(hmax), 2) return end
        if type(vmax) ~= "number" and type(vmax) ~= "nil" then log.error("Vmax base should be a number, got a "..type(vmax), 2) return end
        if type(gravity1) ~= "number" and type(gravity1) ~= "nil" then log.error("Gravity1 base should be a number, got a "..type(gravity1), 2) return end
        if type(gravity2) ~= "number" and type(gravity2) ~= "nil" then log.error("Gravity2 base should be a number, got a "..type(gravity2), 2) return end
        if type(accel) ~= "number" and type(accel) ~= "nil" then log.error("Acceleration base should be a number, got a "..type(accel), 2) return end

        survivors[self.value].pHmax_base = hmax or survivors[self.value].pHmax_base
        survivors[self.value].pVmax_base = vmax or survivors[self.value].pVmax_base
        survivors[self.value].pGravity1_base = gravity1 or survivors[self.value].pGravity1_base
        survivors[self.value].pGravity2_base = gravity2 or survivors[self.value].pGravity2_base
        survivors[self.value].pAccel_base = accel or survivors[self.value].pAccel_base
    end,

    set_stats_level = function(self, maxhp, damage, regen, armor, attack_speed, critical_chance)
        if type(maxhp) ~= "number" and type(maxhp) ~= "nil" then log.error("Max HP level should be a number, got a "..type(maxhp), 2) return end
        if type(damage) ~= "number" and type(damage) ~= "nil" then log.error("Damage level should be a number, got a "..type(damage), 2) return end
        if type(regen) ~= "number" and type(regen) ~= "nil" then log.error("Regen level should be a number, got a "..type(regen), 2) return end
        if type(armor) ~= "number" and type(armor) ~= "nil" then log.error("Armor level should be a number, got a "..type(armor), 2) return end
        if type(attack_speed) ~= "number" and type(attack_speed) ~= "nil" then log.error("Attack Speed level should be a number, got a "..type(attack_speed), 2) return end
        if type(critical_chance) ~= "number" and type(critical_chance) ~= "nil" then log.error("Critical Chance level should be a number, got a "..type(critical_chance), 2) return end

        survivors[self.value].maxhp_level = maxhp or survivors[self.value].maxhp_level
        survivors[self.value].damage_level = damage or survivors[self.value].damage_level
        survivors[self.value].regen_level = regen or survivors[self.value].regen_level
        survivors[self.value].attack_speed_level = attack_speed or survivors[self.value].attack_speed_level
        survivors[self.value].critical_chance_level = critical_chance or survivors[self.value].critical_chance_level
        survivors[self.value].armor_level = armor or survivors[self.value].armor_level
    end,

    set_palettes = function(self, palette, portrait_palette, loadout_palette)
        self.sprite_palette = palette
        survivors[self.value].palette = palette

        self.sprite_portrait_palette = portrait_palette
        slef,sprite_loadout_palette = loadout_palette
    end,

    set_cape_offset = function(self, xoffset, yoffset, xoffset_rope, yoffset_rope)
        if type(xoffset) ~= "number" then log.error("X Offset should be a number, got a "..type(maxhp), 2) return end
        if type(yoffset) ~= "number" then log.error("Y Offset should be a number, got a "..type(maxhp), 2) return end
        if type(xoffset_rope) ~= "number" then log.error("X Offset Rope should be a number, got a "..type(maxhp), 2) return end
        if type(yoffset_rope) ~= "number" then log.error("Y Offset Rope should be a number, got a "..type(maxhp), 2) return end

        if type(self.cape_offset) == "nil" then self.cape_offset = gm.array_create(4) end
        
        self.cape_offset[1] = xoffset
        self.cape_offset[2] = yoffset
        self.cape_offset[3] = xoffset_rope
        self.cape_offset[4] = yoffset_rope
    end,
    
    set_scale = function(self, xscale, yscale)
        if type(xscale) ~= "number" then log.error("Xscale should be a number, got a "..type(xscale), 2) return end
        if type(yscale) ~= "number" and type(yscale) ~= "nil" then log.error("Yscale should be a number, got a "..type(yscale), 2) return end

        survivors[self.value].xscale = xscale
        survivors[self.value].yscale = yscale or xscale
    end,

    add_skin = function(self, name, skin_index, achievement)
        for _, skin_name in ipairs(skins) do
            if skin_name == name then 
                -- log.error("Skin Name already exist: "..name)
                return 
            end
        end

        local artifact_skin = Artifact.new_skin(achievement)
        local skin_alt = gm.struct_create()
        gm.static_set(skin_alt, gm.static_get(self.skin_family.elements[1]))
        skin_alt.skin_id = skin_index
        skin_alt.achievement_id = (achievement and achievement.value) or -1
        skin_alt.index = artifact_skin
        gm.array_push(self.skin_family.elements, skin_alt)
        skins[#skins + 1] = name
    end,
}

methods_survivor_callbacks = {
    onInit      = function(self, func) self:add_callback("onInit", func) end,
    onStep      = function(self, func) self:add_callback("onStep", func) end,
    onRemove    = function(self, func) self:add_callback("onRemove", func) end
}


-- ========== Metatables ==========

metatable_survivor_gs = {
    -- Getter
    __index = function(table, key)
        local index = Survivor.ARRAY[key]
        if index then
            local survivor_array = Class.SURVIVOR:get(table.value)
            return survivor_array:get(index)
        end
        return nil
    end,


    -- Setter
    __newindex = function(table, key, value)
        local index = Survivor.ARRAY[key]
        if index then
            local survivor_array = Class.SURVIVOR:get(table.value)
            survivor_array:set(index, value)
        end
    end
}

metatable_survivor_callbacks = {
    __index = function(table, key)
        -- Methods
        if methods_survivor_callbacks[key] then
            return methods_survivor_callbacks[key]
        end

        -- Pass to next metatable
        return metatable_survivor_gs.__index(table, key)
    end
}

metatable_survivor = {
    __index = function(table, key)
        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_wrapper" then return abstraction_data[table].RMT_wrapper end

        -- Methods
        if methods_survivor[key] then
            return methods_survivor[key]
        end

        -- Pass to next metatable
        return metatable_survivor_callbacks.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        if key == "value" or key == "RMT_wrapper" then
            log.error("Cannot modify wrapper values", 2)
            return
        end

        metatable_survivor_gs.__newindex(table, key, value)
    end
}


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if callbacks[args[1].value] then
        for _, fn in pairs(callbacks[args[1].value]) do
            fn(args[2].value) --(actor, initial_set)
        end
    end
end)

-- Need to put that somewhere else
-- And add more callback type?
gm.post_script_hook(gm.constants.instance_callback_call, function(self, other, result, args)
    for _, fn in pairs(instance_callbacks) do

        -- on Hit
        if #args == 6 and debug.getinfo(fn).nparams == 4 then
            fn(args[3].value, args[4].value, args[5].value, args[6].value) --(object_instance, hit_instance, hit_x, hit_y)
        end

        -- on End
        if #args == 3 and debug.getinfo(fn).nparams == 1 then
            fn(args[3].value) --(object_instance)
        end
    end
end)