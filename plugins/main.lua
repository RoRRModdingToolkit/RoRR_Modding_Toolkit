-- RoRR Modding Toolkit v1.1.0

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./actor")
require("./alarm")
require("./array")
require("./buff")
require("./callback")
require("./class")
require("./color")
require("./equipment")
require("./helper")
require("./initialize")
require("./instance")
require("./item")
require("./list")
require("./net")
require("./object")
require("./player")
require("./resources")
require("./skill")
require("./state")
require("./survivor")
require("./wrap")



-- ========== Initialize ==========

function __initialize()
    Class.__initialize()
    
    -- Initialize these first (callback population)
    Callback.__initialize()
    -- Survivor.__initialize()

    Actor.__initialize()
    Buff.__initialize()
    -- Instance.__initialize()
    Item.__initialize()
end



-- ========== Hooks ==========

-- Write "Modded" under version number at top-left corner
gm.post_code_execute(function(self, other, code, result, flags)
    if code.name:match("oStartMenu_Draw_0") then
        gm.draw_set_alpha(0.5)
        gm.draw_text(6, gm.camera_get_view_y(gm.camera_get_active()) + 20, "Modded")
        gm.draw_set_alpha(1)
    end
end)