-- RMTtest v1.0.0
-- RoRRModdingToolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            Skill = m.Skill
            State = m.State
            break
        end
    end
end)

if hot_reloading then
    __initialize()
end
hot_reloading = true

local function devconsole(self, other, result, args)
    gm.instance_create_depth(0, 0, -100000001, 776)
end

__initialize = function()

    devconsole()
    
    -- Create a new skill       (namespace, identifier, cooldown, damage, sprite_id, sprite_subimage, animation, is_primary, is_utility)
    local new_skill = Skill.new("RMT", "skilltest", 4, 5.0, gm.constants.sCommandoSkills, 0, gm.constants.sRobomandoShoot1, true, false)
    
    -- Create a new empty/locked skill
    local new_empty_skill = Skill.newEmpty("RMT", "emptyskill")

    -- Create a new state
    local new_state = State.new("RMT", "skilltest")

    -- Set skill's settings such as allow_buffered_input or hold_facing_direction
    new_skill:set_skill_settings(true, 0.0, 1.0, true, 0.0, false, false, true)

    -- Set individual skill field
    new_skill.max_stock = 1

    -- When skill is activated change actor state
    new_skill:onActivate(function(actor, skill, index)
        gm.actor_set_state(actor, new_state.value)
    end)

    -- When entering the state set the animation to the first frame
    -- and create a custom data variable that will be carried over the state's callbacks
    new_state:onEnter(function(actor, data)
        actor.image_index = 0
        data.fired = 0
    end)
    
    -- During the skill animation, fix speed, set animation, and code the behaviour of the skill
    new_state:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        
        actor:actor_animation_set(actor:actor_get_skill_animation(new_skill.value), 0.25)

        if data.fired == 0 then
            local damage = actor:skill_get_damage(new_skill.value)
            
            if actor:is_authority() then
                if not actor:skill_util_update_heaven_cracker(actor, damage) then
                    local buff_shadow_clone = Buff.find("ror", "shadowClone")
                    for i=0, gm.get_buff_stack(actor, buff_shadow_clone.value) do
                        -- (??, x, y, damage_team??, damage, range, spark_sprite, facing_dir, is_crit??, can_proc??, can_pierce??)
                        local attack = actor:fire_bullet(0, actor.x, actor.y, 0, damage, 1400, gm.constants.sSparks1, actor:skill_util_facing_direction(), 1, 1, -1)
                        attack.climb = i * 8
                        attack.tracer_kind = 16 -- TODO add a better way to use attack_tracer_kind
                    end
                end
            end

            actor:sound_play(gm.constants.wBullet1, 1, gm.random_range(0.85, 1))
            data.fired = 1
        end

        actor:skill_util_exit_state_on_anim_end()
    end)
end