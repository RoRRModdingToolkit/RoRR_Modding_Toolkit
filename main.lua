-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

-- ENVY setup
mods["MGReturns-ENVY"].auto()

require("./internal/proxy")
require("./internal/abstraction")

local classes = {
    "Array",
    "Helper",
}

for _, c in ipairs(classes) do
    require("./class/"..string.lower(c))
end



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
            log.info(a.keys_locked)
            a:lock(2)
            log.info(a.proxy_locked)
            a[3] = 5
            log.info(a[3])
            -- a[2] = 4
            log.info(a[2])
            a:lock()
            log.info(a.proxy_locked)
            a[10] = 10

        end
    end
    ImGui.End()
end)