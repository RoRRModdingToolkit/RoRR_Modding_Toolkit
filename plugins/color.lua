-- Color

Color = {
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
    
    ITEM_GREEN      = 5813365,
    ITEM_RED        = 4007881,
    ITEM_YELLOW     = 4312538,
    ITEM_ORANGE     = 3499737,

    TEXT_YELLOW     = 8114927,
    TEXT_BLUE       = 13802033,
    TEXT_GREEN      = 8828542,
    TEXT_RED        = 6710991,
    TEXT_LTGRAY     = 12632256,
    TEXT_LTGREY     = 12632256,
    TEXT_DKGRAY     = 8421504,
    TEXT_DKGREY     = 8421504
}



-- ========== Metatables ==========

metatable_color = {
    __newindex = function()
        log.error("Cannot modify Color constants", 2)
    end
}
setmetatable(Color, metatable_color)