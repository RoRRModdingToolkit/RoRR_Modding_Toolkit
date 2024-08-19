-- Alarm
-- SmoothSpatula

Alarm = {}

local alarms = {}
current_frame = nil

--

Alarm.create = function(func, time,...)
    if not current_frame then return false end
    local future_frame = current_frame+time
    if not alarms[future_frame] then alarms[future_frame] = {} end
    alarms[future_frame][#alarms[future_frame]+1] = {
        fn = func,
        args = select(1, ...)
    }
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    current_frame = gm.variable_global_get("_current_frame")
    if not alarms[current_frame] then return end
    for i=1, #alarms[current_frame] do
        alarms[current_frame][i].fn(alarms[current_frame][i].args)
    end
    alarms[current_frame] = nil
end)