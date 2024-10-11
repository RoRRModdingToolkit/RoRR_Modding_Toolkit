-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")


-- ENVY initial setup
mods["MGReturns-ENVY"].auto()
envy = mods["MGReturns-ENVY"]
class_refs = {}


-- Require internal files
local names = path.get_files(_ENV["!plugins_mod_folder_path"].."/internal")
for _, name in ipairs(names) do require(name) end


function capitalize_class_name(class)
    local final = ""
    local arr = gm.string_split(class, "_")
    for i = 0, gm.array_length(arr) - 1 do
        local part = gm.array_get(arr, i)
        part = part:sub(1, 1):upper()..part:sub(2, #part)
        if i > 0 then final = final.."_" end
        final = final..part
    end
    return final
end


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


-- Lock public classes (after initialization)
for _, ref in pairs(class_refs) do
    ref:lock()
end


-- ENVY public setup
require("./envy_setup")



-- ========== Initialize ==========

function __initialize()
    
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
            log.info(a[2])
            a[2] = 5
            -- a.keys_locked = "Abc"

            -- a[1] = 3
            -- a[2] = 4
            -- log.info(a[1])
            -- log.info(a[2])
            -- log.info(a.proxy_locked)
            -- log.info(a.lock)
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

        end
    end
    ImGui.End()
end)