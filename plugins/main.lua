-- RoRR Modding Toolkit v1.0.0

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

require("./modules/helper")
require("./modules/instance")
require("./modules/item")
require("./modules/net")
require("./modules/player")



-- ========== Testing ==========

-- log.info(Helper.table_to_string)
-- log.info(Net.get_type())

function test(a, b, ...)
    return {...}
end

log.info(test(1, 2, 3, 4, 5)[2])