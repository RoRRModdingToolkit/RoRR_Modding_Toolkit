-- Stage

Stage = class_refs["Stage"]

local populate_biome = {}



-- ========== Static Methods ==========

Stage.new = function(namespace, identifier, no_log)
    local stage = Stage.find(namespace, identifier)
    if stage then return stage end

    local stage = Stage.wrap(
        gm.stage_create(
            namespace,      -- Namespace
            identifier      -- Identifier
        )
    )

    -- Create environment log
    if not no_log then
        stage.log_id = gm.environment_log_create(namespace, identifier)
    end

    return stage
end



-- ========== Instance Methods ==========

methods_stage = {    

    set_index = function(self, ...)
        local order = Array.wrap(gm.variable_global_get("stage_progression_order"))

        -- Remove from existing list(s)
        for _, i in ipairs(order) do
            local list = List.wrap(i)
            for n, s in ipairs(list) do
                if s == self.value then
                    list:delete(n - 1)
                    break
                end
            end
        end
        
        -- Add to target list(s)
        local t = {...}
        if type(t[1]) == "table" then t = t[1] end

        for _, index in ipairs(t) do
            local cap = #order
            if type(index) ~= "number" or index < 1 or index > cap then
                log.error("Stage index should be between 1 and "..cap.." (inclusive)", 2)
            end
            gm._mod_stage_register(index, self.value)
        end


        -- Remove previous environment log position
        local env_log_order = List.wrap(gm.variable_global_get("environment_log_display_list"))
        local pos = env_log_order:find(self.log_id)
        if pos then env_log_order:delete(pos) end
        
        -- Set new environment log position
        local pos = 0
        for i, log_id in ipairs(env_log_order) do
            local log_ = Class.ENVIRONMENT_LOG:get(log_id)
            local iter_env = Stage.find(log_:get(0), log_:get(1))

            local tier = 0
            for t, n in ipairs(order) do
                local list = List.wrap(n)
                for _, s in ipairs(list) do
                    if s == iter_env.value then
                        tier = t
                        break
                    end
                end
            end

            if tier > t[1] then
                pos = i
                break
            end
        end
        env_log_order:insert(pos - 1, self.log_id)
    end,


    add_room = function(self, ...)
        local list = List.wrap(self.room_list)

        local t = {...}
        if type(t[1]) == "table" then t = t[1] end

        for _, path in ipairs(t) do
            local num = #list

            local room = gm.stage_load_room(self.namespace, self.identifier.."_"..math.floor(num + 1), path)
            list:add(room)

            -- Associate environment log
            if self.log_id ~= -1.0 then
                local display_room_ids = Class.ENVIRONMENT_LOG:get(self.log_id):get(5)
                display_room_ids:push(room)
                gm.room_associate_environment_log(room, self.log_id, num)
            end
        end
    end,


    get_room = function(self, variant)
        local list = List.wrap(self.room_list)

        if variant < 1 or variant > #list then
            log.error("Variant must be between 1 and variant count (inclusive)", 2)
            return
        end

        return list[variant]
    end,


    clear_rooms = function(self)
        local list = List.wrap(self.room_list)
        list:clear()

        local display_room_ids = Class.ENVIRONMENT_LOG:get(self.log_id):get(5)
        display_room_ids:clear()
    end,


    add_interactable = function(self, ...)
        local list = List.wrap(self.spawn_interactables)

        local t = {...}
        if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

        for _, card in ipairs(t) do
            if type(card) == "string" then card = Interactable_Card.find(card) end
            list:add(Wrap.unwrap(card))
        end
    end,


    add_interactable_loop = function(self, ...)
        local list = List.wrap(self.spawn_interactables_loop)

        local t = {...}
        if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

        for _, card in ipairs(t) do
            if type(card) == "string" then card = Interactable_Card.find(card) end
            list:add(Wrap.unwrap(card))
        end
    end,


    clear_interactables = function(self, loop)
        local list = List.wrap(self.spawn_interactables)
        if loop then list = List.wrap(self.spawn_interactables_loop) end
        list:clear()
    end,


    add_monster = function(self, ...)
        local list = List.wrap(self.spawn_enemies)

        local t = {...}
        if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

        for _, card in ipairs(t) do
            if type(card) == "string" then card = Monster_Card.find(card) end
            list:add(Wrap.unwrap(card))
        end
    end,


    add_monster_loop = function(self, ...)
        local list = List.wrap(self.spawn_enemies_loop)

        local t = {...}
        if type(t[1]) == "table" and (not t[1].RMT_object) then t = t[1] end

        for _, card in ipairs(t) do
            if type(card) == "string" then card = Monster_Card.find(card) end
            list:add(Wrap.unwrap(card))
        end
    end,


    clear_monsters = function(self, loop)
        local list = List.wrap(self.spawn_enemies)
        if loop then list = List.wrap(self.spawn_enemies_loop) end
        list:clear()
    end,


    set_log_icon = function(self, sprite)
        if self.log_id == -1.0 then
            log.error("This stage has no environment log", 2)
            return
        end
        
        Class.ENVIRONMENT_LOG:get(self.log_id):set(15, sprite)
    end,


    set_log_view_start = function(self, x, y)
        local log = Class.ENVIRONMENT_LOG:get(self.log_id)
        log[7], log[9] = x, x
        log[8], log[10] = y, y
    end,


    set_log_hidden = function(self, bool)
        if bool == nil then return end
        Class.ENVIRONMENT_LOG:get(self.log_id):set(14, bool)
        
        -- Move environment log position to end
        local env_log_order = List.wrap(gm.variable_global_get("environment_log_display_list"))
        local pos = env_log_order:find(self.log_id)
        if pos then env_log_order:delete(pos) end
        env_log_order:add(self.log_id)
    end,


    set_title_screen_properties = function(self, ground_strip, obj_sprites, force_draw_depth)
        local id = self.namespace.."-"..self.identifier
        if not populate_biome[id] then populate_biome[id] = {} end
        populate_biome[id] = {
            ground_strip = ground_strip,
            obj_sprites = obj_sprites or nil,
            force_draw_depth = force_draw_depth or nil
        }
    end

}



-- ========== Metatables ==========

metatable_class["Stage"] = {
    __index = function(table, key)
        -- Methods
        if methods_stage[key] then
            return methods_stage[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Stage"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Stage"].__newindex(table, key, value)
    end,


    __metatable = "Stage"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callable_call, function(self, other, result, args)
    if #args ~= 3 then return end

    for id, t in pairs(populate_biome) do
        local stage = Stage.find(id)
        if args[1].value == stage.populate_biome_properties then
            local struct = args[3].value

            struct.ground_strip = t.ground_strip

            if t.obj_sprites then
                local array = Array.wrap(struct.obj_sprites)
                array:clear()
                for _, spr in ipairs(t.obj_sprites) do
                    array:push(spr)
                end
            end

            if t.force_draw_depth then
                for _, v in ipairs(t.force_draw_depth) do
                    struct.force_draw_depth[tostring(math.floor(v))] = true
                end
            end

            break
        end
    end
end)



return Stage