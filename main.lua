-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")


-- ENVY initial setup
mods["MGReturns-ENVY"].auto()
envy = mods["MGReturns-ENVY"]
class_refs = {}


-- Require internal files
local names = path.get_files(_ENV["!plugins_mod_folder_path"].."/internal")
for _, name in ipairs(names) do require(name) end

class_refs["Proxy"] = Proxy     -- Making this public too; might be useful to someone


-- Require public classes (these first)
local names = path.get_files(_ENV["!plugins_mod_folder_path"].."/class_first")
for _, name in ipairs(names) do
    local class = capitalize_class_name(path.filename(name):sub(1, -5))
    class_refs[class] = require(name)
end


-- Require public classes
local names = path.get_files(_ENV["!plugins_mod_folder_path"].."/class")
for _, name in ipairs(names) do
    local class = capitalize_class_name(path.filename(name):sub(1, -5))
    class_refs[class] = require(name)
end


-- Lock public classes after finalization
for _, ref in pairs(class_refs) do
    ref:lock()

    -- Lock enums and stuff
    for k, v in ipairs(ref) do
        if type(v) == "table" and getmetatable(v) == "proxy" then
            v:lock()
        end
    end
end


-- ENVY public setup
require("./envy_setup")



-- ========== Initialize ==========

function __initialize()
    initialize_callback()
    
    initialize_instance()
    initialize_actor()
    
    initialize_item()
end



-- ========== Debug ==========

gui.add_imgui(function()
    if ImGui.Begin("RMT Debug") then

        if ImGui.Button("a") then
            for k, v in pairs(public) do
                log.info(k)
            end

            log.info(Array.new)

        elseif ImGui.Button("b") then
            local a = Proxy.new()
            a[1] = 3
            a[2] = 4
            a:lock(2)
            a.lock = "abc"
            -- log.info(a[2])
            a[2] = 5
            -- a.keys_locked = "Abc"

            -- a[1] = 3
            -- a[2] = 4
            -- log.info(a[1])
            -- log.info(a[2])
            -- log.info(a.proxy_locked)
            -- log.info(a:lock)
            -- log.info(a.keys_locked)
            -- a:lock(2)
            -- log.info(a.proxy_locked)
            -- a[3] = 5
            -- log.info(a[3])
            -- -- a[2] = 4
            -- log.info(a[2])
            -- a:lock()
            -- log.info(a.proxy_locked)
            -- a[10] = 10

        elseif ImGui.Button("c") then
            local a = Proxy.new()
            a:lock()
            getmetatable(a)
            -- setmetatable(a, nil)
            a.value = 127
            log.info(a.value)

        end
    end
    ImGui.End()
end)