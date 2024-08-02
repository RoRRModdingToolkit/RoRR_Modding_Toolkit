-- RoRR Modding Toolkit v1.0.0

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./buff")
require("./callback")
require("./helper")
require("./initialize")
require("./instance")
require("./item")
require("./net")
require("./player")
require("./resources")
require("./survivor")



-- Testing
require("./testing")