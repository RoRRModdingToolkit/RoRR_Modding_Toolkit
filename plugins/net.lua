-- Net
-- Originally in HelperFunctions by Klehrik

Net = {}

local registered = {}
local received = false



-- ========== Enums ==========

Net.TYPE = {
    single      = 0,
    host        = 1,
    client      = 2
}


Net.TARGET = {
    all         = 0,
    only        = 1,
    exclude     = 2
}



-- ========== Functions ==========

Net.get_type = function()
    local oPrePlayer = Instance.find(gm.constants.oPrePlayer)
    if oPrePlayer then
        if oPrePlayer.m_id == 1.0 then return Net.TYPE.host
        elseif oPrePlayer.m_id > 1.0 then return Net.TYPE.client
        end
    end

    local p = Player.get_client()
    if p then
        if p.m_id == 1.0 then return Net.TYPE.host
        elseif p.m_id > 1.0 then return Net.TYPE.client
        end
    end

    return Net.TYPE.single
end


Net.register = function(func_id, func, replace)
    if replace or not registered[func_id] then registered[func_id] = func end
end


Net.send = function(func_id, target, player_name, ...)
    local my_player = gm.variable_global_get("my_player")
    local message = "[RMT_NET]"..func_id.."|||"..Helper.table_to_string({...})

    if target == Net.TARGET.only or target == Net.TARGET.exclude then
        if not player_name then player_name = " " end
        message = message.."|||"..target.."|||"..player_name
    end
    
    my_player:net_send_instance_message(4, message)
end



-- ========== Hooks ==========

-- Net communication
gm.pre_script_hook(104659.0, function(self, other, result, args)
    received = true
end)

gm.pre_script_hook(gm.constants.chat_add_user_message, function(self, other, result, args)
    if received then
        received = false

        local player = args[1].value.user_name
        local text = args[2].value

        if string.sub(text, 1, 9) == "[RMT_NET]" then
            local data = gm.string_split(string.sub(text, 10, #text), "|||")

            -- Check only/exclude
            if gm.array_length(data) > 2 then
                local name = ""
                local oInit = Instance.find(gm.constants.oInit)
                if oInit then name = oInit.pref_name end

                if (gm.array_get(data, 2) == Net.TARGET.only and name ~= gm.array_get(data, 3))
                or (gm.array_get(data, 2) == Net.TARGET.exclude and name == gm.array_get(data, 3)) then
                    return false
                end
            end

            -- Run function
            local func_id = gm.array_get(data, 0)
            local func_args = Helper.string_to_table(gm.array_get(data, 1))

            if registered[func_id] then registered[func_id](table.unpack(func_args)) end

            return false
        end
    end
end)