-- Alarm
-- Miguel

Alarm = Proxy.new()

local alarms = {}
local current_frame = 0

--

Alarm.create = function(func, time, ...)
    local future_frame = current_frame+time
    if not alarms[future_frame] then alarms[future_frame] = {} end
    local alarm = {
        fn = func,
        args = {...},
        src = envy.getfenv(2)["!guid"],
        frame = future_frame
    }
    table.insert(alarms[future_frame], alarm)
    return alarm
end

Alarm.destroy = function(alarm)
    if type(alarm) ~= "table" then return end
    if not alarms[alarm.frame] then return end
    Helper.table_remove(alarms[alarm.frame], alarm)
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    -- "_current_frame" resets on run start, so using own counter now
    -- Also only increments when not paused in a run, just like before
    if not gm.variable_global_get("pause") then current_frame = current_frame + 1 end
    if not alarms[current_frame] then return end
    for i=1, #alarms[current_frame] do
        local status, err = pcall(alarms[current_frame][i].fn, table.unpack(alarms[current_frame][i].args))
        if not status then
            log.error("Alarm error from "..alarms[current_frame][i].src.."\n"..err)
        end
    end
    alarms[current_frame] = nil
end)

return Alarm