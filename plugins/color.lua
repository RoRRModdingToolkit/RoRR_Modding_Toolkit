-- Color

Color = {}

local abstraction_color = {
    -- Constants from GML manual
    -- https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Drawing/Colour_And_Alpha/Colour_And_Alpha.htm
    AQUA            = 0xffff00,
    BLACK           = 0x000000,
    BLUE            = 0xff0000,
    DKGRAY          = 0x404040,
    DKGREY          = 0x404040,
    FUCHSIA         = 0xff00ff,
    GRAY            = 0x808080,
    GREEN           = 0x008000,
    LIME            = 0x00ff00,
    LTGRAY          = 0xc0c0c0,
    LTGREY          = 0xc0c0c0,
    MAROON          = 0x000080,
    NAVY            = 0x800000,
    OLIVE           = 0x008080,
    ORANGE          = 0x40a0ff,
    PURPLE          = 0x800080,
    RED             = 0x0000ff,
    SILVER          = 0xc0c0c0,
    TEAL            = 0x808000,
    WHITE           = 0xffffff,
    YELLOW          = 0x00ffff,
    -- item colors
    ITEM_WHITE      = 0xffffff
    ITEM_GREEN      = 0x58b475,
    ITEM_RED        = 0x3d27c9,
    ITEM_YELLOW     = 0x41cdda,
    ITEM_ORANGE     = 0x3566d9,
    ITEM_PURPLE     = 0xc76aab,
    ITEM_GRAY       = 0x555555,
    ITEM_GREY       = 0x555555,
    -- text colors
    TEXT_YELLOW     = 0x7bd2ef,
    TEXT_BLUE       = 0xd29a31,
    TEXT_GREEN      = 0x86b67e,
    TEXT_RED        = 0x6666cf,
    TEXT_LTGRAY     = 0xc0c0c0,
    TEXT_LTGREY     = 0xc0c0c0,
    TEXT_DKGRAY     = 0x808080,
    TEXT_DKGREY     = 0x808080,
}

-- ========== Static Functions (using gamemaker calls) ==========

Color.make_rgb = function(red, green, blue)
    return gm.make_colour_rgb(red, green, blue)
end

Color.make_hsv = function(hue, saturation, value)
    return gm.make_colour_hsv(hue, sat, val)
end

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

-- ========== Static Functions (no gamemaker calls) ==========

-- from rgb [0-255] to gamemaker
Color.from_rgb = function(r,g,b)
  return b*0x10000+g*0x100+r
end

-- from lua hex to gamemaker (switch most significant bit)
Color.from_hex = function(hex)
  return (hex >> 16) | (hex & 0xff00) | ((hex % 0x100) << 16)
end

-- from gamemaker to rgb
Color.to_rgb = function(col)
  return col & 0xff, (col & 0xff00) >> 8, col >> 16 --r, g, b
end

-- switch back MSB (same operation)
Color.to_hex = function(col)
  return Color.from_hex(col)
end

-- Hue [0-360[, Saturation [0-100], Value [0-100] -> r, g, b [0-255]
Color.hsv_to_rgb = function(h, s, v)
  if h > 360 or h<0 or s<0 or s > 100 or v < 0 or v > 100 then 
    log.error("Incorrect hsv values", 2)
    return nil
  end
  local h = h/360
  local s = s/100
  local v = v/100
  
  if s then
    if h == 1.0 then h = 0.0 end
    local i = math.floor(h*6.0)
    local f = h*6.0 - i
    
    local w = math.floor(255*(v * (1.0 - s)))
    local q = math.floor(255*(v * (1.0 - s * f)))
    local t = math.floor(255*(v * (1.0 - s * (1.0 - f))))
    v = math.floor(255*v)
    
    if i==0 then return v, t, w end
    if i==1 then return q, v, w end
    if i==2 then return w, v, t end
    if i==3 then return w, q, v end
    if i==4 then return t, w, v end
    if i==5 then return v, w, q end
  else 
    v = math.floor(255*v)
    return v, v, v
  end
end

-- rgb [0-255] -> Hue [0-360[, Saturation [0-100], Value [0-100]
Color.rgb_to_hsv = function(r, g, b)
  if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
    log.error("Incorrect rgb values")
    return nil
  end
  r = r/255
  g = g/255
  b = b/255
  local Cmax = math.max(r,g,b)
  local Cmin = math.min(r,g,b)
  local Delta = Cmax-Cmin
  
  -- Hue calculation
  local h = nil
  if Delta == 0 then h = 0 
  elseif Cmax == r then h = 60*(((g-b)/Delta)%6) 
  elseif Cmax == g then h = 60*((b-r)/Delta+2)
  elseif Cmax == b then h = 60*((r-g)/Delta+4) 
  end
  -- Saturation calculation
  local s = 0
  if Cmax ~= 0 then
    s = Delta/Cmax
  end
  -- Return h, s, v
  return math.floor(h), math.floor(s*100), math.floor(Cmax*100)
end

Color.from_hsv = function(h, s, v)
  return Color.from_rgb(Color.hsv_to_rgb(h,s,v))
end

Color.to_hsv = function(col)
  return Color.rgb_to_hsv(Color.to_rgb(col))
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

Colour = Color -- Colour is a reference to Color for Bri'ish localisation
