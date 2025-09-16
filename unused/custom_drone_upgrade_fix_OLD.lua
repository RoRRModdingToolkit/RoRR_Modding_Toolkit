-- fix for custom object drones upgrading
-- by hinyb

memory.dynamic_hook_mid("__rpc_drone_upgrade_implementation__fix", {"rdx", "[r15+8h]"}, {"RValue*", "RValue*"}, 0,
    gm.get_script_function_address(gm.constants.__rpc_drone_upgrade_implementation__):add(851), function(args)
        args[1].value = args[2].value:get_object_index_self()
    end)