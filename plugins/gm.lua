-- gm

-- For the list of gm functions below, if they are run by a mod,
-- wrapped values will be automatically unwrapped

local functions = {
    gm.constants.recalculate_stats
}



-- ========== Hooks ==========

for _, fn in ipairs(functions) do
    gm.pre_script_hook(fn, function(self, other, result, args)
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