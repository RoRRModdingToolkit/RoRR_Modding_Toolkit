-- Net

Net = Proxy.new()

local registered = {}
local received = false



-- ========== Enums ==========

Net.TYPE = Proxy.new({
    single      = 0,
    host        = 1,
    client      = 2
}):lock()


Net.TARGET = Proxy.new({
    all         = 0,
    only        = 1,
    exclude     = 2
}):lock()



-- ========== Functions ==========

Net.get_type = function()
    local oPrePlayer = Instance.find(gm.constants.oPrePlayer)
    if oPrePlayer:exists() then
        if oPrePlayer.m_id == 1.0 then return Net.TYPE.host
        elseif oPrePlayer.m_id > 1.0 then return Net.TYPE.client
        end
    end

    local p = Player.get_client()
    if p:exists() then
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
    if Net.get_type() == Net.TYPE.single then return end

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
            local data = Array.wrap(gm.string_split(string.sub(text, 10, #text), "|||"))

            -- Check only/exclude
            if data:size() > 2 then
                local name = ""
                local oInit = Instance.find(gm.constants.oInit)
                if oInit:exists() then name = oInit.pref_name end

                if (data:get(2) == Net.TARGET.only and name ~= data:get(3))
                or (data:get(2) == Net.TARGET.exclude and name == data:get(3)) then
                    return false
                end
            end

            -- Run function
            local func_id = data:get(0)
            local func_args = Helper.string_to_table(data:get(1))

            if registered[func_id] then registered[func_id](table.unpack(func_args)) end

            return false
        end
    end
end)



return Net