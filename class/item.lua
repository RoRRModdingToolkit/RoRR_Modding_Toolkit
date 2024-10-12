-- Item

Item = class_refs["Item"]

local has_custom_item = {}



-- ========== Enums ==========

Item.TIER = {
    common      = 0,
    uncommon    = 1,
    rare        = 2,
    equipment   = 3,
    boss        = 4,
    special     = 5,
    food        = 6,
    notier      = 7
}


Item.LOOT_TAG = {
    category_damage                 = 1 << 0,
    category_healing                = 1 << 1,
    category_utility                = 1 << 2,
    equipment_blacklist_enigma      = 1 << 3,
    equipment_blacklist_chaos       = 1 << 4,
    equipment_blacklist_activator   = 1 << 5,
    item_blacklist_engi_turrets     = 1 << 6,
    item_blacklist_vendor           = 1 << 7,
    item_blacklist_infuser          = 1 << 8
}


Item.TYPE = {
    all         = 0,
    real        = 1,
    temporary   = 2
}



-- ========== Static Methods ==========

Item.new = function(namespace, identifier, no_log)
    local item = Item.find(namespace, identifier)
    if item then return item end

    -- Create item
    local item = Item.wrap(
        gm.item_create(
            namespace,
            identifier,
            nil,
            Item.TIER.notier,
            gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
            0
        )
    )

    -- Create item log
    if not no_log then
        local log = gm.item_log_create(
            namespace,
            identifier,
            nil,
            nil,
            item.object_id
        )

        item.item_log_id = log
    end

    -- Add onPickup callback to add actor to has_custom_item table
    item:onPickup(function(actor, stack)
        if not Helper.table_has(has_custom_item, actor.value) then
            table.insert(has_custom_item, actor.value)
        end
    end)

    return item
end



return Item