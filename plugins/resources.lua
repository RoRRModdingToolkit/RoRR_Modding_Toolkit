-- Resources
-- SmoothSpatula

Resources = {}

-- == Section Sprites == --

Resources.sprite_load = function(path, img_num, remove_back, smoooth, x_orig, y_orig, speed)
    local sprite = gm.sprite_add(
        path, 
        (img_num ~= nil and {img_num} or {1})[1], 
        (remove_back ~= nil and {remove_back} or {false})[1], 
        (smooth ~= nil and {smooth} or {false})[1],
        (x_orig ~= nil and {x_orig} or {0})[1], 
        (y_orig ~= nil and {y_orig} or {0})[1]
    )

    if sprite == -1 then
        log.error("Couldn't load sprite"..path..". Loading default sprite instead.")
        return 0
    end

    if speed then
        gm.sprite_set_speed(sprite, speed, 1) -- always set in framespergameframe since framerate is constant
    end
    return sprite
end

Resources.sprite_duplicate = function(id, x_offset, y_offset, speed)
    local sprite = gm.sprite_duplicate(id)

    if sprite == -1 then
        log.error("Error trying to duplicate sprite. Loading default sprite instead.")
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

Resources.sfx_load = function(path)
    local sfx = gm.audio_create_stream(path)
    if sfx == -1 then 
        log.error("Couldn't load sfx "..path)
    end
    return sfx
end

return Resources