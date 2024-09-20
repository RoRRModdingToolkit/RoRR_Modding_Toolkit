-- Interactable

Interactable = {}

local abstraction_data = setmetatable({}, {__mode = "k"})

local callbacks = {}



-- ========== Enums ==========

Interactable.ARRAY = {
    spawn_cost                      = 2,
    spawn_weight                    = 3,
    object_id                       = 4,
    required_tile_space             = 5,
    spawn_with_sacrifice            = 6,
    is_new_interactable             = 7,
    default_spawn_rarity_override   = 8,
    decrease_weight_on_spawn        = 9
}



-- ========== Static Methods ==========

Interactable.new = function(namespace, identifier)
    if Object.find(namespace, identifier) then return nil end

    -- Create interactable and its card
    local obj = Interactable.wrap(gm.object_add_w(namespace, identifier, gm.constants.pInteractable))
    gm.interactable_card_create(namespace, identifier)

    -- Set interactable values
    obj.object_id = obj.value
    obj.obj_depth = 1

    return obj
end


Interactable.wrap = function(interactable_id)
    local abstraction = {}
    abstraction_data[abstraction] = {
        RMT_object = "Interactable",
        value = interactable_id
    }
    setmetatable(abstraction, metatable_interactable)
    return abstraction
end



-- ========== Instance Methods ==========

methods_interactable = {

    add_callback = function(self, callback, func, state)

        if callback == "onActivate" then
            if not callbacks[callback] then callbacks[callback] = {} end
            table.insert(callbacks[callback], {self.value, func})
    
        elseif callback == "onStateStep"
            or callback == "onStateDraw"
            then
                if not callbacks[callback] then callbacks[callback] = {} end
                table.insert(callbacks[callback], {self.value, func, state})

        else self:add_callback_obj_actual(callback, func)

        end
    end,


    get_card = function(self)
        for i, intc in ipairs(Class.INTERACTABLE_CARD) do
            if self.namespace == intc:get(0)
            and self.identifier == intc:get(1) then
                return intc, i - 1
            end
        end
    end,


    add_to_stage = function(self, namespace, identifier)
        if identifier then namespace = namespace.."-"..identifier end

        local card_array, id = self:get_card()
        local list = List.wrap(Class.STAGE:get(gm.stage_find(namespace)):get(6))
        list:add(id)
    end

}


methods_interactable_callbacks = {

    onActivate          = function(self, func) self:add_callback("onActivate", func) end,
    onStateStep         = function(self, func, state) self:add_callback("onStateStep", func, state) end,
    onStateDraw         = function(self, func, state) self:add_callback("onStateDraw", func, state) end

}


methods_interactable_instance = {

    get_state = function(self)
        local state = self.value.active
        if state > 0 then state = state - 2 end
        return state
    end,


    set_state = function(self, state)
        if state > 0 then state = state + 2 end
        self.value.active = state
    end

}



-- ========== Metatables ==========

metatable_interactable = {
    __index = function(table, key)
        -- Return interactable card value
        local index = Interactable.ARRAY[key]
        if index then
            local intc_array = table:get_card()
            return intc_array:get(index)
        end

        -- Methods
        if methods_interactable[key] then
            return methods_interactable[key]
        end

        -- Pass to callback methods
        if methods_interactable_callbacks[key] then
            return methods_interactable_callbacks[key]
        end

        -- Allow getting but not setting these
        if key == "value" then return abstraction_data[table].value end
        if key == "RMT_object" then return abstraction_data[table].RMT_object end

        -- Pass to next metatable
        return metatable_object.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        -- Set interactable card value
        local index = Interactable.ARRAY[key]
        if index then
            local intc_array = table:get_card()
            intc_array:set(index, value)
            return
        end

        -- Pass to Object setter
        metatable_object_gs.__newindex(table, key, value)
    end
}


metatable_interactable_instance = {
    __index = function(table, key)
        -- Methods
        if methods_interactable_instance[key] then
            return methods_interactable_instance[key]
        end

        -- Pass to next metatable
        return metatable_instance.__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_instance_gs.__newindex(table, key, value)
    end
}



-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    local override = false
    if callbacks["onActivate"] then
        for _, c in ipairs(callbacks["onActivate"]) do
            if c[1] == args[1].value.__object_index then
                override = true
                c[2](Instance.wrap(args[1].value), Instance.wrap(args[2].value)) -- Interactable, Actor
            end
        end
    end
    if override then
        args[1].value.activator = args[2].value
        return false
    end
end)



-- ========== Callbacks ==========

local function interactable_instance_onStep(self, other, result, args)
    if gm.variable_global_get("pause") then return end
    
    if callbacks["onStateStep"] then
        local cust_ints = Instance.find_all(gm.constants.oCustomObject_pInteractable)
        for n, inst in ipairs(cust_ints) do
            for _, c in ipairs(callbacks["onStateStep"]) do
                local active = c[3]
                if active > 0 then active = active + 2 end
                if c[1] == inst.__object_index and active == inst.active then
                    c[2](inst) -- Interactable
                end
            end
        end
    end
end


local function interactable_instance_onDraw(self, other, result, args)
    if gm.variable_global_get("pause") then return end

    if callbacks["onStateDraw"] then
        local cust_ints = Instance.find_all(gm.constants.oCustomObject_pInteractable)
        for n, inst in ipairs(cust_ints) do
            for _, c in ipairs(callbacks["onStateDraw"]) do
                if c[1] == inst.__object_index and c[3] == inst.active then
                    c[2](inst) -- Interactable
                end
            end
        end
    end
end



-- ========== Initialize ==========

Interactable.__initialize = function()
    Callback.add("preStep", "RMT.interactable_instance_onStep", interactable_instance_onStep, true)
    Callback.add("postHUDDraw", "RMT.interactable_instance_onDraw", interactable_instance_onDraw, true)
end