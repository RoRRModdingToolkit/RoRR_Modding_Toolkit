-- Alarm
-- Miguel

Alarm = Proxy.new()

local alarms = {}
local current_frame = 0

--

Alarm.create = function(func, time, ...)
    local future_frame = current_frame+time
    if not alarms[future_frame] then alarms[future_frame] = {} end
    alarms[future_frame][#alarms[future_frame]+1] = {
        fn = func,
        args = select(1, ...),
        src = envy.getfenv(2)["!guid"]
    }
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    -- "_current_frame" resets on run start, so using own counter now
    current_frame = current_frame + 1
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