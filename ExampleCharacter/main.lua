-- IWBTS v1.0.0
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")


mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            Callback = m.Callback
            Helper = m.Helper
            Instance = m.Instance
            Item = m.Item
            Net = m.Net
            Player = m.Player
            Survivor = m.Survivor
            Resources = m.Resources
            break
        end
    end
end)

-- == Section Setup + Stats == --

local bullet_speed = 10.0
local jump_force = 8.0
local body_parts = 15

local normal_hp = 1
local normal_elite_hp = 3
local boss_hp = 6
local boss_elite_hp = 9
local providence_hp = 20


if hot_reloading then
    __initialize()
    local player = Player.get_client()
    if player then
        Survivor.survivor_init(player)
    end
end
hot_reloading = true


__initialize = function()
    local Guy_id = -1
    local Guy = nil

    -- == Section Sprites == --
    -- Menu
    local portrait_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPortrait.png"))
    local portraitsmall_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPortraitSmall.png"))
    local skills_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSSkill.png"))
    local loadout_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSMetroidedReversed.png"), 14, true, false, 16, -130)

    -- In game
    local idle_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSIdle.png"), 4, true, false, 16, 19)
    local jump_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSJump.png"), 2, true, false, 16, 19)
    local jumpfall_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSFall.png"), 2, true, false, 16, 19)
    local walk_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSWalk.png"), 4, true, false, 16, 19, 0.5)
    local death_sprite = Resources.sprite_duplicate(gm.constants.sGolemDeath, 1000000, 1000000)

    local bullet_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSBullet.png"), 1, false, false, 0, 0)

    -- Body Parts 
    local PartsHead_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPartsHead.png"), 1, true, false, 0, 0)
    local PartsArm_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPartsArm.png"), 1, true, false, 0, 0)
    local PartsLeg_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPartsLeg.png"), 1, true, false, 0, 0)
    local PartsBody_sprite = Resources.sprite_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "IWBTSPartsBody.png"), 32, true, false, 0, 0)

    -- == Section Audio == --

    local shoot_sfx = Resources.sfx_load(path.combine(_ENV["!plugins_mod_folder_path"], "Sprites", "shoot.ogg"))

    -- == Section Survivor == --

    -- -- function setup_survivor(namespace, identifier, name, description, end_quote,
    -- -- loadout_sprite, portrait_sprite, portraitsmall_sprite, palette_sprite, 
    -- -- walk_sprite, idle_sprite, death_sprite, jump_sprite, jump_peak_sprite, jumpfall_sprite, climb_sprite,
    -- -- colour, cape_array)
    Guy, Guy_id = Survivor.setup_survivor(
        "SmoothSpatula", "Guy", "The Kid", "The Kid sets out on an adventure to become <y>The Survivor<y>.", "...",
        loadout_sprite, portrait_sprite, portraitsmall_sprite, loadout_sprite,
        walk_sprite, idle_sprite, death_sprite, jump_sprite, jumpfall_sprite, jumpfall_sprite, nil,
        {["r"]=17, ["g"] = 26, ["b"] = 143}, {[1] = 0.0, [2] = -4.0, [3] = 3.0}
    )

    -- -- function setup_stats(survivor_id, armor, attack_speed, movement_speed, critical_chance, damage, hp_regen, maxhp, maxbarrier, maxshield, maxhp_cap, jump_force)
    Survivor.setup_stats(Guy_id, nil, 1.0, nil, 1.0, nil, 0, 1,  0, 0, 1, jump_force)

    -- -- function setup_level_stats(survivor_id, armor_level, attack_speed_level, critical_chance_level, damage_level, hp_regen_level, maxhp_level)
    Survivor.setup_level_stats(Guy_id, nil, nil, nil, nil, nil, 0)

    -- -- == Section skills == --

    -- -- function setup_skill(skill_ref, name, description, 
    -- -- sprite, sprite_subimage,animation, 
    -- -- cooldown, damage, is_primary, skill_id)
    Survivor.setup_skill(Guy.skill_family_z[0], "Gun", "Shoots bullets", 
        skills_sprite, 1, idle_sprite,
        0.0, 10.0, true, 160)


    Guy.skill_family_z[0].does_change_activity_state = false
    Guy.skill_family_z[0].override_strafe_direction = false
    Guy.skill_family_z[0].require_key_press = true

    Survivor.setup_empty_skill(Guy.skill_family_x[0])
    Survivor.setup_empty_skill(Guy.skill_family_c[0])
    Survivor.setup_empty_skill(Guy.skill_family_v[0])

-- == Section callbacks == --

    -- shooting
    gm.pre_script_hook(gm.constants.callback_execute, function(self, other, result, args)
        if self.class ~= Guy_id then return end
        if args[1].value == Guy.skill_family_z[0].on_activate then
            local bullet = gm.instance_create_depth(self.x, self.y, 1, gm.constants.oHuntressBolt1)
            bullet.hspeed = (gm.actor_get_facing_direction(self) == 180) and -bullet_speed or bullet_speed 
            bullet.vspeed = 0.0
            bullet.gravity = 0.0
            bullet.parent = self
            bullet.damage_coeff = 1000000
            bullet.sprite_index = bullet_sprite
            gm.sound_play_at(shoot_sfx, 1, 1, self.x, self.y, 500)
            return false
        end
    end)

-- -- damage application
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        if args[6].value == nil or args[6].value.class ~= Guy_id then return end
        local target = args[3].value or args[2].value
        if target.object_name:match("oWormBody") or target.object_name:match("sWormBody") then          -- wormBody
            print(target.parent.object_name)
            local damage_dealt = (target.parent.elite_type == - 1) and boss_hp or boss_elite_hp         
            target.parent.hp = target.parent.hp - math.ceil(target.maxhp / damage_dealth)
        elseif target.object_name:match("oBoss[1-4]") ~= nil then                                       -- Providence
            target.hp = target.hp - math.ceil(target.maxhp / providence_hp)
        elseif string.match(gm.object_get_name(gm.object_get_parent(target.object_index)),"pBoss") then -- boss
            local damage_dealt = (target.elite_type == - 1) and boss_hp or boss_elite_hp
            target.hp = target.hp - math.ceil(target.maxhp / damage_dealt)
        elseif string.match(gm.object_get_name(gm.object_get_parent(target.object_index)),"pEnemy") then -- normal enemy
            if  target.elite_type == -1 then
                target.hp = target.hp - math.ceil(target.maxhp / normal_hp)
            else
                target.hp = target.hp - math.ceil(target.maxhp / normal_elite_hp)
            end
        end
        return false
    end)

    local function Guy_init(self)
        if Player.get_client().m_id < 2.0 then
            local feather = Item.find("ror-hopooFeather")
            gm.item_give_internal(self, feather, 1, 0)
        end
    end

    local wet_value = nil
    local function onGuyStep(self)
        if self.maxbarrier > 0 then self.maxbarrier = 0 end
        if self.maxshield > 0 then self.maxshield = 0 end
        if wet_value ~= self.wet then
            wet_value = self.wet
            self.jump_count = 0
        end
    end

    local function onDeath(self)
        if Player.get_client().m_id < 2.0 then
            local head = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)
            local arm1 = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)
            local arm2 = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)
            local leg1 = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)
            local leg2 = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)

            head.is_guy_part = 1.0
            arm1.is_guy_part = 1.0
            arm2.is_guy_part = 1.0
            leg1.is_guy_part = 1.0
            leg2.is_guy_part = 1.0

            head.image_xscale = 2.0
            arm1.image_xscale = 2.0
            arm2.image_xscale = 2.0
            leg1.image_xscale = 2.0
            leg2.image_xscale = 2.0

            head.image_yscale = 2.0
            arm1.image_yscale = 2.0
            arm2.image_yscale = 2.0
            leg1.image_yscale = 2.0
            leg2.image_yscale = 2.0
            
            head.sprite_index = PartsHead_sprite
            arm1.sprite_index = PartsArm_sprite
            arm2.sprite_index = PartsArm_sprite
            leg1.sprite_index = PartsLeg_sprite
            leg2.sprite_index = PartsLeg_sprite

            for i=1, body_parts do
                local part = gm.instance_create_depth(self.x, self.y - 15, 1, gm.constants.oEfNugget)
                part.sprite_index = PartsBody_sprite
                part.image_speed = 0
                part.image_xscale = 2.0
                part.image_yscale = 2.0
                part.image_index = i
                part.is_guy_part = 1.0
            end
        end
    end

    Survivor.add_callback(Guy_id, "onPlayerInit", Guy_init)
    Survivor.add_callback(Guy_id, "onPlayerStep", onGuyStep)
    Survivor.add_callback(Guy_id, "onPlayerDeath", onDeath)
end