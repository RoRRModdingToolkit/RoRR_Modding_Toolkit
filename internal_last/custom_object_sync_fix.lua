if mods["ReturnsAPI-ReturnsAPI"] then return end

-- packet ids used for instance serialization
local packet_ids = {
	[103] = true,
	[104] = true,
	[105] = true,
}

-- patch for the server messages that serialize instances to correctly use the custom object index instead of the raw object_index
gm.pre_script_hook(gm.constants.server_message_send, function(self, other, result, args)
	if packet_ids[args[2].value] then
		args[3].value = args[5].value:get_object_index_self()
	end
end)
