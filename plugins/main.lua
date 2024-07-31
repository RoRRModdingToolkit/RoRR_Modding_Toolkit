-- RoRR Modding Toolkit v1.0.0

log.info("Successfully loaded ".._ENV["!guid"]..".")
--mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

RoRR_Modding_Toolkit = true

require("instance")
require("item")
require("net")
require("player")



-- ========== Main ==========

