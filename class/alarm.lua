-- Alarm
-- Miguel

Alarm = Proxy.new()

local alarms = {}
local current_frame = nil

--

Alarm.create = function(func, time, ...)
    if not current_frame then return false end
    local future_frame = current_frame+time
    if not alarms[future_frame] then alarms[future_frame] = {} end
    alarms[future_frame][#alarms[future_frame]+1] = {
        fn = func,
        args = select(1, ...),
        src = envy.getfenv(2)["!guid"]
    }
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    local new_current_frame = gm.variable_global_get("_current_frame")
    if new_current_frame < current_frame then alarms = {} end   -- "_current_frame" resets on run start
    current_frame = new_current_frame
    if not alarms[current_frame] then return end
    for i=1, #alarms[current_frame] do
        local status, err = pcall(alarms[current_frame][i].fn, alarms[current_frame][i].args)
        if not status then
            log.error("Alarm error from "..alarms[current_frame][i].src.."\n"..err)
        end
    end
    alarms[current_frame] = nil
end)

return Alarm