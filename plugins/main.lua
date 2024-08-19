-- RoRR Modding Toolkit v1.0.1

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./actor")
require("./buff")
require("./callback")
require("./helper")
require("./initialize")
require("./instance")
require("./item")
require("./net")
require("./player")
<<<<<<< Updated upstream
require("./resources")
require("./survivor")

-- Testing
--require("./testing")


=======
require("./survivor")
require("./resources")
require("./alarm")
>>>>>>> Stashed changes

-- ========== Initialize ==========

function __initialize()
    Instance.__initialize()
end