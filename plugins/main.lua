-- RoRR Modding Toolkit v1.0.16

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./actor")
require("./alarm")
require("./buff")
require("./callback")
require("./class")
require("./equipment")
require("./helper")
require("./initialize")
require("./instance")
require("./item")
require("./net")
require("./object")
require("./player")
require("./resources")
require("./survivor")

-- Testing
--require("./testing")



-- ========== Initialize ==========

function __initialize()
    Class.__initialize()
    
    -- Initialize these first (callback population)
    Callback.__initialize()
    Survivor.__initialize()

    Actor.__initialize()
    Buff.__initialize()
    Instance.__initialize()
    Item.__initialize()
end
