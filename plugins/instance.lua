-- Instance
-- Originally in HelperFunctions by Klehrik

Instance = {}



-- ========== Tables ==========

Instance.chests = {
    gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5,
    gm.constants.oChestHealing1, gm.constants.oChestDamage1, gm.constants.oChestUtility1,
    gm.constants.oChestHealing2, gm.constants.oChestDamage2, gm.constants.oChestUtility2,
    gm.constants.oGunchest
}


Instance.shops = {
    gm.constants.oShop1, gm.constants.oShop2
}


Instance.teleporters = {
    gm.constants.oTeleporter, gm.constants.oTeleporterEpic
}



-- ========== Functions ==========

Instance.exists = function(inst)
    return gm.instance_exists(inst) == 1.0
end


Instance.find = function(...)
    local t = {...}
    if type(t[1]) == "table" then t = t[1] end

    for _, ind in ipairs(t) do
        -- Vanilla objects
        if ind < Object.ID_encoding then
            local inst = gm.instance_find(ind, 0)
            if Instance.exists(inst) then return inst end

        -- RMT Custom objects
        else
            for i = 0, gm.instance_number(gm.constants.oCustomObject_pPickupItem) - 1 do
                local inst = gm.instance_find(gm.constants.oCustomObject_pPickupItem, i)
                if Instance.exists(inst) then
                    if inst.RMT_Object and inst.RMT_Object == ind then return inst end
                end
            end

        end
    end

    return nil
end


Instance.find_all = function(...)
    local t = {...}
    if type(t[1]) == "table" then t = t[1] end

    local insts = {}

    for _, ind in ipairs(t) do
        -- Vanilla objects
        if ind < Object.ID_encoding then
            for n = 0, gm.instance_number(ind) - 1 do
                local inst = gm.instance_find(ind, n)
                if Instance.exists(inst) then table.insert(insts, inst) end
            end

        -- RMT Custom objects
        else
            for n = 0, gm.instance_number(gm.constants.oCustomObject_pPickupItem) - 1 do
                local inst = gm.instance_find(gm.constants.oCustomObject_pPickupItem, n)
                if Instance.exists(inst) then
                    if inst.RMT_Object and inst.RMT_Object == ind then table.insert(insts, inst) end
                end
            end

        end
    end

    return insts, #insts > 0
end


Instance.number = function(index)
    -- Vanilla objects
    if index < Object.ID_encoding then return gm.instance_number(index)

    -- RMT Custom objects
    else
        local number = 0
        for n = 0, gm.instance_number(gm.constants.oCustomObject_pPickupItem) - 1 do
            local inst = gm.instance_find(gm.constants.oCustomObject_pPickupItem, n)
            if Instance.exists(inst) then
                if inst.RMT_Object and inst.RMT_Object == index - Object.ID_encoding then number = number + 1 end
            end
        end
        return number
    end
end


Instance.spawn_crate = function(x, y, tier, items, depth)
    local lang_map = gm.variable_global_get("_language_map")
    local class_item = gm.variable_global_get("class_item")

    local sprites = {gm.constants.sCommandCrateCommon, gm.constants.sCommandCrateUncommon, gm.constants.sCommandCrateRare, gm.constants.sCommandCrateEquipment, gm.constants.sCommandCrateBoss}
    local sprites_use = {gm.constants.sCommandCrateCommonUse, gm.constants.sCommandCrateUncommonUse, gm.constants.sCommandCrateRareUse, gm.constants.sCommandCrateEquipmentUse, gm.constants.sCommandCrateBossUse}
    local isi = {6.0, 8.0, 10.0, 14.0, 12.0}
    local isii = {5.0, 7.0, 9.0, 13.0, 11.0}

    -- Move downwards until on the ground
    while not gm.position_meeting(x, y, gm.constants.pBlockStatic) and y < gm.variable_global_get("room_height") do y = y + 1 end

    -- Taken from Scrappers mod
    local c = gm.instance_create_depth(x, y, depth or 0, gm.constants.oCustomObject_pInteractableCrate)

    -- Most of the following are necessary,
    -- and are not set from creating the instance directly (via gm.instance_create)
    c.active = 0.0
    c.owner = -4.0
    c.activator = -4.0
    c.buy_button_visible = 0.0
    c.can_activate_frame = 0.0
    c.mouse_x_last = 0.0
    c.mouse_y_last = 0.0
    c.mouse_hovered_last = 0.0
    c.last_move_was_mouse = false
    c.using_mouse = false
    c.last_activated_frame = -1.0
    c.cam_rect_x1 = x - 100
    c.cam_rect_y1 = y - 100
    c.cam_rect_x2 = x + 100
    c.cam_rect_y2 = y + 100
    c.contents = nil
    c.inventory = 76.0 + (tier * 2.0)
    c.flash = 0.0
    c.interact_scroll_index = isi[tier + 1]
    c.interact_scroll_index_inactive = isii[tier + 1]
    c.surf_text_cost_large = -1.0
    c.surf_text_cost_small = -1.0
    c.translation_key = "interactable.pInteractableCrate"
    c.text = gm.ds_map_find_value(lang_map, c.translation_key..".text")
    c.spawned = true
    c.cost = 0.0
    c.cost_color = 8114927.0
    c.cost_type = 0.0
    c.selection = 0.0
    c.select_cd = 0.0
    c.sprite_index = sprites[tier + 1]
    c.sprite_death = sprites_use[tier + 1]
    c.fade_alpha = 0.0
    c.col_index = tier
    c.m_id = gm.set_m_id(true)  -- I have no idea what the argument is supposed to be, but this works
    c.my_player = -4.0
    c.__custom_id = tier
    c.__object_index = 800.0 + tier
    c.image_speed = 0.06
    c.tier = tier

    -- Replace default crate items with custom set
    if items then
        c.contents = gm.array_create()
        for _, i in ipairs(items) do
            gm.array_push(c.contents, class_item[i + 1][9])
        end
    end

    -- [Host] Send spawn data to clients
    if Net.get_type() == Net.TYPE.host then Net.send("RMT.spawnCrate", Net.TARGET.all, nil, x, y, tier, items, depth) end

    return c
end



-- ========== Initialize ==========

Instance.__initialize = function()
    Net.register("RMT.spawnCrate", Instance.spawn_crate)
end