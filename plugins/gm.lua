-- gm

-- For the list of gm functions below, if they are run by a mod,
-- wrapped values will be automatically unwrapped

gm_functions = {
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


gm_add_instance_methods = function(methods_table)
    for _, fn in ipairs(gm_functions) do
        methods_table[fn] = function(self, ...)
            local t = {...}
            for i, arg in ipairs(t) do
                t[i] = Wrap.unwrap(arg)
            end
            return gm.call(fn, self.value, self.value, table.unpack(t))
        end
    end
end



-- ========== Hooks ==========

-- ok this doesn't work because passed-in lua values get converted into nil before hook
-- adding as instance methods as above works fine though

-- for _, fn in ipairs(gm_functions) do
--     if gm.constants[fn] then
--         gm.pre_script_hook(gm.constants[fn], function(self, other, result, args)
--             -- Check if function was run by a mod
--             -- (This is done by the fact that debug.getinfo(2) will be nil if run by the game)
--             -- If so, do Wrap.unwrap on all arguments
--             log.info(fn)
--             Helper.log_hook(self, other, result, args)

--             if debug.getinfo(2, "f") then
--                 self = Wrap.unwrap(self)
--                 other = Wrap.unwrap(other)
--                 for _, a in ipairs(args) do
--                     a.value = Wrap.unwrap(a.value)
--                 end
--             end
--         end)
--     end
-- end