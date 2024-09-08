-- Color

Color = {}

local abstraction_color = {
    -- Constants from GML manual
    -- https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Drawing/Colour_And_Alpha/Colour_And_Alpha.htm
    AQUA            = 16776960,
    BLACK           = 0,
    BLUE            = 16711680,
    DKGRAY          = 4210752,
    DKGREY          = 4210752,
    FUCHSIA         = 16711935,
    GRAY            = 8421504,
    GREEN           = 32768,
    LIME            = 65280,
    LTGRAY          = 12632256,
    LTGREY          = 12632256,
    MAROON          = 128,
    NAVY            = 8388608,
    OLIVE           = 32896,
    ORANGE          = 4235519,
    PURPLE          = 8388736,
    RED             = 255,
    SILVER          = 12632256,
    TEAL            = 8421376,
    WHITE           = 16777215,
    YELLOW          = 65535,

    ITEM_WHITE      = 16777215,
    ITEM_GREEN      = 5813365,
    ITEM_RED        = 4007881,
    ITEM_YELLOW     = 4312538,
    ITEM_ORANGE     = 3499737,
    ITEM_PURPLE     = 13068971,
    ITEM_GRAY       = 5592405,
    ITEM_GREY       = 5592405,

    TEXT_YELLOW     = 8114927,
    TEXT_BLUE       = 13802033,
    TEXT_GREEN      = 8828542,
    TEXT_RED        = 6710991,
    TEXT_LTGRAY     = 12632256,
    TEXT_LTGREY     = 12632256,
    TEXT_DKGRAY     = 8421504,
    TEXT_DKGREY     = 8421504
}



-- ========== Static Functions ==========

Color.make_hex = function(hex)
    if type(hex) ~= "string" or #hex ~= 6 then
        log.error("Not a valid color hex code", 2)
        return nil
    end

    local r = gm.real(gm.ptr( string.sub(hex, 1, 2) ))
    local g = gm.real(gm.ptr( string.sub(hex, 3, 4) ))
    local b = gm.real(gm.ptr( string.sub(hex, 5, 6) ))
    return Color.make_rgb(r, g, b)
end


Color.make_rgb = function(red, green, blue)
    return gm.make_colour_rgb(red, green, blue)
end


Color.make_hsv = function(hue, saturation, value)
    return gm.make_colour_hsv(hue, sat, val)
end



-- ========== Metatables ==========

metatable_color = {
    -- Create color by calling Color(hex_string)
    __call = function(table, hex)
        return Color.make_hex(hex)
    end,


    __index = function(table, key, value)
        local col = abstraction_color[key]
        if col then return col end
        log.error("Non-existent Color constant", 2)
        return nil
    end,


    __newindex = function(table, key, value)
        log.error("Cannot modify Color constant", 2)
    end
}
setmetatable(Color, metatable_color)