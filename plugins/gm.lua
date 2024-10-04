-- gm

-- For the list of gm functions below, if they are run by a mod,
-- wrapped values will be automatically unwrapped

local functions = {
    "instance_create",
    "recalculate_stats",
    "skill_util_unlock_cooldown",
    "skill_util_lock_cooldown",
    "skill_util_facing_direction",
    "skill_util_apply_friction",
    "skill_util_exit_state_on_anim_end",
    "actor_skill_add_stock",
    "sound_play_at",
    "",
    "",
}



-- ========== Hooks ==========

for _, fn in ipairs(functions) do
    gm.pre_script_hook(gm.constants[fn], function(self, other, result, args)
        -- Check if function was run by a mod
        -- (This is done by the fact that debug.getinfo(2) will be nil if run by the game)
        -- If so, do Wrap.unwrap on all arguments
        if debug.getinfo(2) then
            self = Wrap.unwrap(self)
            other = Wrap.unwrap(other)
            for _, a in ipairs(args) do
                a.value = Wrap.unwrap(a.value)
            end
        end
    end)
end