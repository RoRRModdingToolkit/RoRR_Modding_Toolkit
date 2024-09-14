-- RMTtest v1.0.0
-- RoRRModdingToolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            Buff = m.Buff
            Class = m.Class
            Color = m.Color
            Helper = m.Helper
            Skill = m.Skill
            State = m.State
            Survivor = m.Survivor
            Resources = m.Resources
            break
        end
    end
end)

if hot_reloading then
    __initialize()
end
hot_reloading = true

local PATH = _ENV["!plugins_mod_folder_path"]

__initialize = function()

    local jam = Survivor.new("RMT", "jamman")
    
    -- Load all of our sprites into a table
    local sprites = {
        idle = Resources.sprite_load("RMT", "jam_idle", path.combine(PATH, "jam", "idle.png"), 1, 6, 20),
        walk = Resources.sprite_load("RMT", "jam_walk", path.combine(PATH, "jam", "walk.png"), 8, 8, 20),
        jump = Resources.sprite_load("RMT", "jam_jump", path.combine(PATH, "jam", "jump.png"), 1, 10, 22),
        climb = Resources.sprite_load("RMT", "jam_climb", path.combine(PATH, "jam", "climb.png"), 2, 8, 14),
        death = Resources.sprite_load("RMT", "jam_death", path.combine(PATH, "jam", "death.png"), 8, 96, 26),
        
        -- This sprite is used by the Crudely Drawn Buddy
	    -- If the player doesn't have one, the Commando's sprite will be used instead
        decoy = Resources.sprite_load("RMT", "jam_decoy", path.combine(PATH, "jam", "decoy.png"), 1, 18, 36),
    }
    
    -- Attack sprites are loaded separately as we'll be using them in our code
    local sprShoot1 = Resources.sprite_load("RMT", "jam_shoot1", path.combine(PATH, "jam", "shoot1.png"), 7, 10, 28)
    local sprShoot2 = Resources.sprite_load("RMT", "jam_shoot2", path.combine(PATH, "jam", "shoot2.png"), 5, 8, 22)
    local sprShoot3 = Resources.sprite_load("RMT", "jam_shoot3", path.combine(PATH, "jam", "shoot3.png"), 9, 12, 16)
    local sprShoot4 = Resources.sprite_load("RMT", "jam_shoot4", path.combine(PATH, "jam", "shoot4.png"), 15, 8, 38)
    
    -- The hit sprite used by our X skill
    local sprSparksJam = Resources.sprite_load("RMT", "jam_sparks1", path.combine(PATH, "jam", "bullet.png"), 4, 20, 16)
    
    -- The spikes creates by our V skill
    local sprJamSpike = Resources.sprite_load("RMT", "jam_spike", path.combine(PATH, "jam", "spike.png"), 5, 24, 64)
    local sprSparksSpike = Resources.sprite_load("RMT", "jam_sparks2", path.combine(PATH, "jam", "hitspike.png"), 4, 16, 18)

    -- The sprite used by the skill icons
    local sprSkills = Resources.sprite_load("RMT", "jam_skills", path.combine(PATH, "jam", "skills.png"), 6, 0, 0)
    
    -- Palette used for alt skins
    local sprPalette = Resources.sprite_load("RMT", "jam_palette", path.combine(PATH, "jam", "palette.png"))
    local sprPaletteLoadout = Resources.sprite_load("RMT", "jam_paletteLoadout", path.combine(PATH, "jam", "paletteLoadout.png"))


    -- Set the Name, Description and EndQuote of the survivor
    jam:set_text(
        "Jam Man",
        "The <y>Jam Man</c> is an <y>example character</c> intended to serve as a base for other characters.\n<y>Stab</c> can hit more enemies at a time compared to other melee attacks.\n<y>Raspberry Bullet</c> can be used as an opener to deal extra damage as you use other skills.\n<y>Spikes of Death</c> is very effective against large groups.",
        "..and so it left, still not knowing how it got here to begin with."
    )
    
    -- The color of the character's skill names in the character select
    jam:set_primary_color(162, 62, 224)
    
    -- The character's sprite in the selection pod
    jam.sprite_loadout = Resources.sprite_load("RMT", "jam_select", path.combine(PATH, "jam", "select.png"), 4, 28, 0)

    -- The character's sprite palettes (WIP)
    jam:set_palettes(sprPalette, sprPaletteLoadout, sprPaletteLoadout)

    -- Create alternative skin for the survivor
    jam:add_skin("jammanpurple", 1)
    jam:add_skin("jammanred", 2)
    
    -- The character's walk animation on the title screen when selected
    jam.sprite_title = sprites.walk
    
    -- The character's idle animation
    jam.sprite_idle = sprites.idle
    
    -- The character's idle animation when beating the game
    jam.sprite_credits = sprites.idle
    
    -- Set the Prophet cape offset for the player
    jam:set_cape_offset(-1, -6, 0, -5)

    -- Set the player's sprites to those we previously loaded
    jam:set_animations(sprites)
    
    -- Set the player's starting stats
    jam:set_stats_base(120, 14, 0.01)
    
    -- Set the player's leveling stats
    jam:set_stats_level(24, 4, 0.002, 4)
    
    -- Get the default survivor skills
    local skill_stab = jam:get_primary()
    local skill_raspberry = jam:get_secondary()
    local skill_roll = jam:get_utility()
    local skill_spikes = jam:get_special()
    
    -- Create a new alt skill for the secondary skill
    local skill_spoiled = Skill.new("RMT", "jammanX2")
    jam:add_secondary(skill_spoiled)

    -- Create a new skill for the special skill upgrade
    local skill_spikesScepter = Skill.new("RMT", "jammanV_Upgrade")
    skill_spikes:set_skill_upgrade(skill_spikesScepter)
    
    -- Set the animation for each skills
    skill_stab:set_skill_animation(sprShoot1)
    skill_raspberry:set_skill_animation(sprShoot2)
    skill_spoiled:set_skill_animation(sprShoot2)
    skill_roll:set_skill_animation(sprShoot3)
    skill_spikes:set_skill_animation(sprShoot4)
    skill_spikesScepter:set_skill_animation(sprShoot4)

    -- Create State skill
    local state_stab = State.new("RMT", skill_stab.identifier)
    local state_raspberry = State.new("RMT", skill_raspberry.identifier)
    local state_spoiled = State.new("RMT", skill_spoiled.identifier)
    local state_roll = State.new("RMT", skill_roll.identifier)
    local state_spikes = State.new("RMT", skill_spikes.identifier)
    local state_spikesScepter = State.new("RMT", skill_spikesScepter.identifier)


    -- Setup the Primary skill
    skill_stab:set_skill(
        "Stab",
        "Stab for <y>90% damage</c> hitting <y>up to 5</c> enemies.",
        sprSkills,
        0,
        0.9,
        40
    )

    -- Called when the player tries to use its primary skill
    skill_stab:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_stab.value)
    end)

    -- Reset the sprite animation to frame 0
    state_stab:onEnter(function(actor, data)
        actor.image_index = 0
        data.fired = 0
    end)
    
    -- Implement the actual mechanics of the skill
    state_stab:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(skill_stab.value), 0.25)
        
        if data.fired == 0 and actor.image_index >= 4.0 then
            local damage = actor:skill_get_damage(skill_stab.value)
            
            if actor:is_authority() then
                if not actor:skill_util_update_heaven_cracker(actor, damage) then
                    local buff_shadow_clone = Buff.find("ror", "shadowClone")
                    for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                        local attack = gm._mod_attack_fire_explosion(actor, actor.x + gm.cos(gm.degtorad(actor:skill_util_facing_direction())) * 25, actor.y, 40, 45, damage, -1, gm.constants.sSparks7)
                        attack.max_hit_number = 5
                        attack.attack_info.climb = i * 8
                    end
                end
            end

            actor:sound_play(gm.constants.wClayShoot1, 1, 0.8 + math.random() * 0.2)
            data.fired = 1
        end

        actor:skill_util_exit_state_on_anim_end()
    end)


    -- Setup the Secondary skill
    skill_raspberry:set_skill(
        "Raspberry Bullet",
        "Fire a projectile from your rod for <y>60% damage.</c>\n<y>Pierces enemies</c> and causes bleeding for <y>4x60% damage</c> over time.",
        sprSkills,
        1,
        0.6,
        6 * 60
    )

    -- Called when the player tries to use its secondary skill
    skill_raspberry:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_raspberry.value)
    end)

    -- Reset the sprite animation to frame 0
    state_raspberry:onEnter(function(actor, data)
        actor.image_index = 0
        data.fired = 0
    end)
    
    -- Implement the actual mechanics of the skill
    state_raspberry:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(skill_raspberry.value), 0.25)

        if data.fired == 0 and actor.image_index >= 1.0 then
            local damage = actor:skill_get_damage(skill_raspberry.value)
            
            if actor:is_authority() then
                local buff_shadow_clone = Buff.find("ror", "shadowClone")
                for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                    local attack = gm._mod_attack_fire_bullet(actor, actor.x, actor.y, 500, actor:skill_util_facing_direction(), damage, gm.constants.sSparks7, true, true)
                    attack.jamdot = true
                    attack.attack_info.climb = i * 8
                end
            end

            actor:sound_play(gm.constants.wBullet2, 1, 0.9 + math.random() * 0.2)
            data.fired = 1
        end

        actor:skill_util_exit_state_on_anim_end()
    end)

    jam:add_instance_callback(function(obj_inst, hit_inst, hit_x, hit_y)
        if not obj_inst.jamdot then return end
    
        local dot = gm.instance_create(hit_x, hit_y, gm.constants.oDot)
        dot.target = hit_inst.id
        dot.parent = obj_inst.attack_info.parent.id
        dot.damage = obj_inst.attack_info.damage
        dot.ticks = 3
        dot.team = obj_inst.attack_info.team
        dot.textColor = Color.RED
        dot.sprite_index = gm.constants.sSparks9
    end)
    
    
    -- Setup the Secondary alt skill
    skill_spoiled:set_skill(
        "Spoiled Bullet",
        "Fire a projectile from your rod for <y>80% damage.</c>\n<y>Pierces enemies</c> and <b>poison</c> them.",
        sprSkills,
        2,
        0.8,
        6 * 60
    )

    -- Called when the player tries to use its secondary alt skill
    skill_spoiled:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_spoiled.value)
    end)

    -- Reset the sprite animation to frame 0
    state_spoiled:onEnter(function(actor, data)
        actor.image_index = 0
        data.fired = 0
    end)
    
    -- Implement the actual mechanics of the skill
    state_spoiled:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(skill_spoiled.value), 0.25)

        if data.fired == 0 and actor.image_index >= 1.0 then
            local damage = actor:skill_get_damage(skill_spoiled.value)
            
            if actor:is_authority() then
                local buff_shadow_clone = Buff.find("ror", "shadowClone")
                for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                    local attack = gm._mod_attack_fire_bullet(actor, actor.x, actor.y, 500, actor:skill_util_facing_direction(), damage, gm.constants.sSparks7, true, true)
                    attack.attack_info.attack_flags = 1 << 1
                    attack.attack_info.climb = i * 8
                end
            end

            actor:sound_play(gm.constants.wBullet2, 1, 0.9 + math.random() * 0.2)
            data.fired = 1
        end

        actor:skill_util_exit_state_on_anim_end()
    end)


    -- Setup the Utility skill
    skill_roll:set_skill(
        "Roll",
        "<y>Roll forward</c> a small distance.\nYou <b>cannot be hit</c> while rolling.",
        sprSkills,
        3,
        0,
        4.5 * 60
    )

    -- Called when the player tries to use its utility skill
    skill_roll:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_roll.value)
    end)

    -- Reset the sprite animation to frame 0
    state_roll:onEnter(function(actor, data)
        actor.image_index = 0
        data.dodged = 0
    end)
    
    -- Implement the actual mechanics of the skill
    state_roll:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor.sprite_index = actor:actor_get_skill_animation(skill_roll.value)
        actor.image_speed = 0.25

        if data.dodged == 0 and actor.image_index >= 8.0 then
            -- Ran on the last frame of the animation

            -- Reset the player's invincibility
            if actor.invincible <= 5 then
                actor.invincible = 0
            end
        else
            -- Ran all other frames of the animation
			
			-- Make the player invincible
			-- Only set the invincibility when below a certain value to make sure we don't override other invincibility effects
            if actor.invincible < 5 then 
                actor.invincible = 5
            end
            
            -- Set the player's horizontal speed
            actor.pHspeed = gm.cos(gm.degtorad(actor:skill_util_facing_direction())) * actor.pHmax * 2.2
        end
        
        actor:skill_util_exit_state_on_anim_end()
    end)


    -- Setup the Special skill
    skill_spikes:set_skill(
        "Spikes of Death",
        "Form spikes in front of yourself dealing up to <y>3x240% damage</c>.",
        sprSkills,
        4,
        2.4,
        7 * 60
    )

    -- Called when the player tries to use its special skill
    skill_spikes:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_spikes.value)
    end)

    -- Reset the sprite animation to frame 0
    state_spikes:onEnter(function(actor, data)
        actor.image_index = 0
        data.spikes = 3
    end)
    
    -- Implement the actual mechanics of the skill
    state_spikes:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(skill_spikes.value), 0.25)

        if (data.spikes == 3 and actor.image_index >= 6.0) or (data.spikes == 2 and actor.image_index >= 10.0) or (data.spikes == 1 and (actor.image_index >= 14.0 or actor.image_index >= 13.9)) then
            local damage = actor:skill_get_damage(skill_stab.value)
            
            if actor:is_authority() then
                if not actor:skill_util_update_heaven_cracker(actor, damage) then
                    local buff_shadow_clone = Buff.find("ror", "shadowClone")
                    for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                        -- Calculate the offset from the player
                        local pos = ((actor.image_index - 2) / 4) * 48 + i * 12

                        -- Create the spike
                        local attack = gm._mod_attack_fire_explosion(actor, actor.x + gm.cos(gm.degtorad(actor:skill_util_facing_direction())) * pos, actor.y, 40, 80, damage, sprJamSpike, sprSparksSpike)
                        attack.attack_info.climb = i * 8
                    end
                end
            end

            actor:sound_play(gm.constants.wBoss1Shoot1, 1, 1.2 + math.random() * 0.3)          
            data.spikes = data.spikes - 1  
        end
        
        actor:skill_util_exit_state_on_anim_end()
    end)


    -- Setup the Special Upgrade skill
    skill_spikesScepter:set_skill(
        "Spikes of Super Death",
        "Form spikes in both directions dealing up to <y>2x3x240% damage</c>.",
        sprSkills,
        5,
        2.4,
        7 * 60
    )

    -- Called when the player tries to use its special upgrade skill
    skill_spikesScepter:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, state_spikesScepter.value)
    end)

    -- Reset the sprite animation to frame 0
    state_spikesScepter:onEnter(function(actor, data)
        actor.image_index = 0
        data.spikes = 3
    end)
    
    -- Implement the actual mechanics of the skill
    state_spikesScepter:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(skill_spikesScepter.value), 0.25)

        if (data.spikes == 3 and actor.image_index >= 6.0) or (data.spikes == 2 and actor.image_index >= 10.0) or (data.spikes == 1 and (actor.image_index >= 14.0 or actor.image_index >= 13.9)) then
            local damage = actor:skill_get_damage(skill_stab.value)
            
            if actor:is_authority() then
                if not actor:skill_util_update_heaven_cracker(actor, damage) then
                    local buff_shadow_clone = Buff.find("ror", "shadowClone")
                    for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                        -- Calculate the offset from the player
                        local pos = ((actor.image_index - 2) / 4) * 48 + i * 12

                        -- Create the spike
                        local attack1 = gm._mod_attack_fire_explosion(actor, actor.x + gm.cos(gm.degtorad(actor:skill_util_facing_direction())) * pos, actor.y, 40, 80, damage, sprJamSpike, sprSparksSpike)
                        local attack2 = gm._mod_attack_fire_explosion(actor, actor.x - gm.cos(gm.degtorad(actor:skill_util_facing_direction())) * pos, actor.y, 40, 80, damage, sprJamSpike, sprSparksSpike)
                        attack1.attack_info.climb = i * 8
                        attack2.attack_info.climb = i * 8
                    end
                end
            end

            -- Layer sound effects when scepter is active
            actor:sound_play(gm.constants.wGuardDeath, 0.6, 1.2 + math.random() * 0.3)            
            actor:sound_play(gm.constants.wBoss1Shoot1, 1, 1.2 + math.random() * 0.3)  
            data.spikes = data.spikes - 1          
        end
        
        actor:skill_util_exit_state_on_anim_end()
    end)
end