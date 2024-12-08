-- Skin

Skin = class_refs["Skin"]



-- ========== Static Methods ==========

Skin.new = function(namespace, identifier)
    -- Check if skin already exist
    local skin = Skin.find(namespace, identifier)
    if skin then return skin end

    -- Create skin
    skin = gm.actor_skin_create(
        namespace,      -- Namespace
        identifier      -- Identifier
    )

    -- Make skin abstraction
    local abstraction = Skin.wrap(skin)

    return abstraction

end



-- ========== Instance Methods ==========

methods_skin = {
    -- CHECK WHAT THOSE DO
    
    -- actor_skin_set_custom_palette_swap_apply_func
    -- actor_skin_get_default_palette_swap
    -- actor_skin_get_providence
    -- actor_skin_draw_inactive_default
    -- actor_skin_draw_selected_default
    -- actor_skin_skinnable_set_skin
    -- actor_skin_skinnable_draw_self
    -- actor_skin_draw_portrait
    -- actor_skin_get_portrait_sprite
    -- actor_skin_draw_loadout_sprite
    -- ACTOR_SKIN_TYPE_INDEX_pal_swap
    -- actor_skin_type_set_colour_override
    -- actor_skin_type_set_sprite_override
    -- actor_skin_get_id

}



-- ========== Metatables ==========

metatable_class["Skin"] = {

    __index = function(table, key)
        -- Methods
        if methods_skin[key] then
            return methods_skin[key]
        end

        -- Pass to next metatable
        return metatable_class_gs["Skin"].__index(table, key)
    end,
    

    __newindex = function(table, key, value)
        metatable_class_gs["Skin"].__newindex(table, key, value)
    end,


    __metatable = "Skin"
}

return Skin