-- RoRR Modding Toolkit v1.0.0

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
require("./resources")
require("./survivor")

function __initialize()
    Net.register("RMT.spawnCrate", Instance.spawn_crate)
end



-- Testing
--require("./testing")