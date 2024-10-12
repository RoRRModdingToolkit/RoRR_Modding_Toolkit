-- Survivor
-- Made by SmoothSpatula using code from Sarn

-- == Section survivor_setup (made by Sarn)== --
survivor_setup = {}

-- for interacting with global arrays as classes
local function gm_array_class(name, fields)
    local mt = {
        __index = function(t, k)
            local f = fields[k]
            if f then
                local v = gm.array_get(t.arr, f.idx)
                if f.typ then
                    return v
                elseif f.decode then
                    return f.decode(v)
                end
                return v
            end
            return nil
        end,
        __newindex = function(t, k, v)
            local f = fields[k]
            if f then
                if f.readonly then
                    error("field " .. k .. " is read-only")
                else
                    return gm.array_set(t.arr, f.idx, v)
                end
            else
                error("setting unknown field " .. k)
            end
        end
    }
    return function(id)
        local class_arr = gm.variable_global_get(name)
        local arr = gm.array_get(class_arr, id)
        return setmetatable({id = id, arr = arr}, mt)
    end
end

survivor_setup.Skill = gm_array_class("class_skill", {
    namespace  = {idx=0},
    identifier = {idx=1},

    token_name = {idx=2},
    token_description = {idx=3},

    sprite     = {idx=4},
    subimage   = {idx=5},

    cooldown     = {idx=6},
    damage   = {idx=7},
    max_stock   = {idx=8},
    start_with_stock   = {idx=9},
    auto_restock   = {idx=10},
    required_stock   = {idx=11},
    require_key_press   = {idx=12},
    allow_buffered_input   = {idx=13},
    use_delay   = {idx=14},
    animation   = {idx=15},
    is_utility   = {idx=16},
    is_primary   = {idx=17},
    required_interrupt_priority   = {idx=18},
    hold_facing_direction   = {idx=19},
    override_strafe_direction   = {idx=20},
    ignore_aim_direction   = {idx=21},
    disable_aim_stall   = {idx=22},
    does_change_activity_state   = {idx=23},
    
    on_can_activate   = {idx=24},
    on_activate   = {idx=25},
    on_step   = {idx=26},
    on_equipped   = {idx=27},
    on_unequipped   = {idx=28},
    
    upgrade_skill   = {idx=29},
})

local skill_family_mt = {
    __index = function(t,k)
        if type(k) == "number" then
            if k >= 0 and k < gm.array_length(t.elements) then
                -- the actual value in the array is a 'skill loadout unlockable' object, so get the skill id from it
                return survivor_setup.Skill(gm.variable_struct_get(gm.array_get(t.elements, k), "skill_id"))
            end
        end
        return nil
    end
}

local function wrap_skill_family(struct_loadout_family)
    -- too lazy to write a proper wrapper right now sorry
    local elements = gm.variable_struct_get(struct_loadout_family, "elements")
    return setmetatable({struct=struct_loadout_family, elements=elements}, skill_family_mt)
end

survivor_setup.Survivor = gm_array_class("class_survivor", {
    namespace  = {idx=0},
    identifier = {idx=1},

    token_name = {idx=2},
    token_name_upper = {idx=3},
    token_description = {idx=4},
    token_end_quote = {idx=5},
    
    skill_family_z = {idx=6,decode=wrap_skill_family},
    skill_family_x = {idx=7,decode=wrap_skill_family},
    skill_family_c = {idx=8,decode=wrap_skill_family},
    skill_family_v = {idx=9,decode=wrap_skill_family},
    skin_family = {idx=10,decode=nil},
    all_loadout_families = {idx=11,decode=nil},
    all_skill_families = {idx=12,decode=nil},

    sprite_loadout        = {idx=13},
    sprite_title          = {idx=14},
    sprite_idle           = {idx=15},
    sprite_portrait       = {idx=16},
    sprite_portrait_small = {idx=17},
    sprite_palette = {idx=18},
    sprite_portrait_palette = {idx=19},
    sprite_loadout_palette = {idx=20},
    sprite_credits = {idx=21},
    primary_color         = {idx=22},
    select_sound_id         = {idx=23},

    log_id         = {idx=24},

    achievement_id         = {idx=25},

    on_init         = {idx=29},
    on_step         = {idx=30},
    on_remove         = {idx=31},

    is_secret         = {idx=32},

    cape_offset         = {idx=33},
})

function survivor_setup:print_name ()
    print(survivor_setup.Survivor.token_name)
end

-- == Section 

local survivors = ... or {}

local is_init = false

Survivor = {}

-- Section Setup/Stats == --

Survivor.setup_survivor = function(namespace, identifier, name, description, end_quote,
                        loadout_sprite, portrait_sprite, portraitsmall_sprite, palette_sprite, 
                        walk_sprite, idle_sprite, death_sprite, jump_sprite, jump_peak_sprite, jumpfall_sprite, climb_sprite,
                        colour, cape_array)
    
    -- check if survivor already exists (same namespace and identifier)               
    local CLASS_SURVIVOR = gm.variable_global_get("class_survivor")
    local survivor_id = nil
    for i=1, #CLASS_SURVIVOR do
        if CLASS_SURVIVOR[i][1] == namespace and CLASS_SURVIVOR[i][2] == identifier then
            survivor_id = i - 1
            break
        end
    end

    if survivor_id == nil then
        survivor_id = gm.survivor_create(namespace, identifier)
    end
    survivor = survivor_setup.Survivor(survivor_id)

    -- Configure Properties
    survivor.token_name = name
    survivor.token_name_upper = string.upper(name)
    survivor.token_description = description
    survivor.token_end_quote = end_quote

    survivor.sprite_loadout = loadout_sprite
    survivor.sprite_title = walk_sprite
    survivor.sprite_idle = idle_sprite
    survivor.sprite_portrait = portrait_sprite
    survivor.sprite_portrait_small = portraitsmall_sprite
    survivor.sprite_palette = palette_sprite
    survivor.sprite_portrait_palette = palette_sprite
    survivor.sprite_loadout_palette = palette_sprite
    survivor.sprite_credits = walk_sprite

    survivor.primary_color = gm.make_colour_rgb(colour.r, colour.g, colour.b) -- for stats screen

    local vanilla_survivor = survivor_setup.Survivor(0)
    survivor.on_init = vanilla_survivor.on_init
    survivor.on_step = vanilla_survivor.on_step
    survivor.on_remove = vanilla_survivor.on_remove

    survivor.cape_offset = gm.array_create(4, nil)

    local cape_offset = gm.variable_global_get("class_survivor")[survivor_id+1][34]
    gm.array_set(cape_offset, 0, cape_array[1])
    gm.array_set(cape_offset, 1, cape_array[2])
    gm.array_set(cape_offset, 2, cape_array[3])
    gm.array_set(cape_offset, 3, -1.0)

    survivors[survivor_id] = {
        ["identifier"] = identifier, 
        ["idle_sprite"] = idle_sprite, 
        ["walk_sprite"] = walk_sprite, 
        ["death_sprite"] = death_sprite,
        ["jump_sprite"] = jump_sprite,
        ["jumpfall_sprite"] = jumpfall_sprite,
        ["jumppeak_sprite"] = jump_peak_sprite,
        ["climb_sprite"] = climb_sprite
    }

    return survivor, survivor_id
end

Survivor.setup_stats = function(survivor_id, armor, attack_speed, movement_speed, critical_chance, damage, hp_regen, maxhp, maxbarrier, maxshield, maxhp_cap, jump_force)
    survivors[survivor_id]["armor"] = armor
    survivors[survivor_id]["attack_speed"] = attack_speed
    survivors[survivor_id]["movement_speed"] = movement_speed
    survivors[survivor_id]["critical_chance"] = critical_chance
    survivors[survivor_id]["damage"] = damage
    survivors[survivor_id]["hp_regen"] =  hp_regen
    survivors[survivor_id]["maxhp"] =  maxhp
    survivors[survivor_id]["maxbarrier"] = maxbarrier
    survivors[survivor_id]["maxshield"] = maxshield
    survivors[survivor_id]["maxhp_cap"] = maxhp_cap
    survivors[survivor_id]["pVmax"] = jump_force
end

Survivor.setup_level_stats = function(survivor_id, armor_level, attack_speed_level, critical_chance_level, damage_level, hp_regen_level, maxhp_level)
    survivors[survivor_id]["armor_level"] = armor_level
    survivors[survivor_id]["attack_speed_level"] = attack_speed_level
    survivors[survivor_id]["critical_chance_level"] = critical_chance_level
    survivors[survivor_id]["damage_level"] = damage_level
    survivors[survivor_id]["hp_regen_level"] =  hp_regen_level
    survivors[survivor_id]["maxhp_level"] = maxhp_level
end

-- == Section Skill == --

Survivor.setup_skill = function(skill_ref, name, description, 
                    sprite, sprite_subimage,animation, 
                    cooldown, damage, is_primary, skill_id)
    skill_ref.token_name = name
    skill_ref.token_description = description
    skill_ref.sprite = sprite
    skill_ref.subimage = sprite_subimage
    skill_ref.animation = animation
    skill_ref.cooldown = cooldown
    skill_ref.damage = damage
    skill_ref.is_primary = is_primary
    skill_ref.required_stock = is_primary and 0 or 1 -- primary skill dont need stock
    skill_ref.use_delay = 0
    skill_ref.require_key_press = not is_primary
    skill_ref.does_change_activity_state = true

    local skills = gm.variable_global_get("class_skill")

    -- skill_ref.on_can_activate = skills[skill_id][25]
    -- skill_ref.on_activate = skills[skill_id][26]

    skill_ref.on_can_activate = skills[skill_id][25]
    skill_ref.on_activate = skills[skill_id][26]

    return skill_ref
end

Survivor.setup_empty_skill = function(skill_ref)
    skill_ref.token_name = "Locked"
    skill_ref.token_description = ""
    skill_ref.sprite = gm.constants.sRobomandoSkills
    skill_ref.subimage = 3
    skill_ref.animation = nil
    skill_ref.cooldown = 0
    skill_ref.damage = 0
    skill_ref.is_primary = false
    skill_ref.required_stock = 10000
    skill_ref.max_stock = 0
    skill_ref.use_delay = 0
    skill_ref.require_key_press = 0
    skill_ref.does_change_activity_state = false

    local skills = gm.variable_global_get("class_skill")

    skill_ref.on_can_activate = skills[1][25]
    skill_ref.on_activate = skills[1][26]



    return skill_ref
end

-- == Section Initialize == --

Survivor.add_callback = function(survivor_id, callback, init_func)
    survivors[survivor_id][callback] = init_func
end

Survivor.survivor_init = function(self)
    local survs = gm.variable_global_get("class_survivor")

    if not survs or not survivors[self.class] then return end
    print("achieved survivor_init")
    self.sprite_idle        = survivors[self.class].idle_sprite
    self.sprite_walk        = survivors[self.class].walk_sprite
    self.sprite_jump        = survivors[self.class].jump_sprite
    self.sprite_jump_peak   = survivors[self.class].jumppeak_sprite or survivors[self.class].jump_sprite
    self.sprite_fall        = survivors[self.class].jumpfall_sprite or survivors[self.class].jump_sprite
    self.sprite_climb       = survivors[self.class].climb_sprite or survivors[self.class].idle_sprite
    self.sprite_death       = survivors[self.class].death_sprite
    self.sprite_decoy       = survivors[self.class].death_sprite


    if survivors[self.class].movement_speed ~= nil then self.pHmax = survivors[self.class].movement_speed end
    if survivors[self.class].movement_speed ~= nil then self.pHmax_base = survivors[self.class].movement_speed end
    if survivors[self.class].movement_speed ~= nil then self.pHmax_raw = survivors[self.class].movement_speed end

    local stats = {"armor", "attack_speed", "critical_chance", "damage", "hp_regen", "maxhp", "maxbarrier", "maxshield", "maxhp_cap"}
    local level_stats = {"survivor_id", "armor_level", "attack_speed_level", "critical_chance_level", "damage_level", "hp_regen_level", "maxhp_level", "pVmax"}
    for _,stat in ipairs(stats) do
        if survivors[self.class][stat] ~= nil then 
            self[stat.."_base"] = survivors[self.class][stat]
            self[stat] = survivors[self.class][stat]
        end
    end

    for _,stat in ipairs(level_stats) do
        if survivors[self.class][stat] ~= nil then 
            self[stat] = survivors[self.class][stat]
        end
    end
end

-- ========== Callbacks ==========

callbacks = {}

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if not survivors[self.class] then return end

    local callback = callback_names[args[1].value + 1] 

    if args[1].value == callbacks["onPlayerInit"] then
        Survivor.survivor_init(self)
    end
    if survivors[self.class][callback] then
        survivors[self.class][callback] (self, other, result, args)
    end
end)

-- section possible additions : call_later

-- local myMethod = gm.method(self.id, gm.constants.function_dummy)
-- local _handle = gm.call_later(20, 1, myMethod, false)



-- ========== Initialize ==========

Survivor.__initialize = function()
    -- Populate callbacks
    callback_names = gm.variable_global_get("callback_names")
    for i = 1, #callback_names do
        callbacks[callback_names[i]] = i - 1
    end
end



return Survivor