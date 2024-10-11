-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

local envy = mods["MGReturns-ENVY"]
envy.auto()

require("./internal/proxy")
require("./internal/abstraction")



-- ========== Debug ==========

gui.add_imgui(function()
    if ImGui.Begin("RMT Debug") then

        if ImGui.Button("a") then
            for k, v in pairs(public) do
                log.info(k)
            end

        elseif ImGui.Button("b") then
            local a = Proxy.new()
            a[1] = 3
            a[2] = 4
            log.info(a[1])
            log.info(a[2])
            log.info(a.proxy_locked)
            log.info(a.lock)
            a:lock()
            log.info(a.proxy_locked)
            a[3] = 5

        end
    end
    ImGui.End()
end)