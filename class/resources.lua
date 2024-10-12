-- Resources
-- SmoothSpatula

Resources = Proxy.new()


-- == Section Sprites == --

Resources.sprite_load = function(namespace, identifier, path, img_num, x_orig, y_orig, speed, bbox_left, bbox_top, bbox_right, bbox_bottom)
    local sprite = gm.sprite_add_w(
        namespace,
        identifier,
        path, 
        img_num or 1, 
        x_orig or 0, 
        y_orig or 0
    )

    if sprite == -1 then
        log.error("Couldn't load sprite "..path..". Loading default sprite instead.", 2)
        return 0
    end

    if speed then
        gm.sprite_set_speed(sprite, speed, 1) -- always set in framespergameframe since framerate is constant
    end

    if bbox_left then
        gm.sprite_collision_mask(sprite, false, 2, bbox_left + x_orig, bbox_top + y_orig, bbox_right + x_orig, bbox_bottom + y_orig, 0, 0)
    end

    return sprite
end

Resources.sprite_duplicate = function(id, x_offset, y_offset, speed)
    local sprite = gm.sprite_duplicate(id)

    if sprite == -1 then
        log.error("Error trying to duplicate sprite. Loading default sprite instead.", 2)
        return 0
    end

    if x_offset and y_offset then
        gm.sprite_set_offset(sprite, x_offset, y_offset)
    end

    if speed then
        gm.sprite_set_speed(sprite, speed, 1) -- always set in framespergameframe since framerate is constant
    end
    return sprite
end

Resources.sfx_load = function(namespace, identifier, path)
    local sfx = gm.sound_add_w(namespace, identifier, path)
    if sfx == -1 then 
        log.error("Couldn't load sfx "..path, 2)
    end
    return sfx
end


return Resources