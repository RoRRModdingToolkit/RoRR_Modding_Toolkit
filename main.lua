-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")


-- ENVY initial setup
mods["MGReturns-ENVY"].auto()
envy = mods["MGReturns-ENVY"]
class_refs = {}


-- Require internal files
local names = path.get_files(_ENV["!plugins_mod_folder_path"].."/internal")
for _, name in ipairs(names) do require(name) end


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


-- Extra public refs
class_refs["Proxy"] = Proxy     -- Making this public too; might be useful to someone
class_refs["Colour"] = Color

class_refs["Z_Actor_Post"] = nil    -- Hacky solution but I'm too tired to find another way rn


-- Lock public classes after finalization
for _, ref in pairs(class_refs) do
    ref:lock()
end


-- ENVY public setup
require("./envy_setup")



-- ========== Initialize ==========

function __initialize()
    initialize_class()
    
    initialize_instance()
    initialize_actor()
    initialize_player()
    
    initialize_artifact()
    initialize_buff()
    initialize_difficulty()
    initialize_equipment()
    initialize_interactable()
    initialize_item()
    initialize_skill()
end