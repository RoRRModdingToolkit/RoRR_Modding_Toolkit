-- RoRR Modding Toolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

RoRR_Modding_Toolkit = true

Classes = {
    "Achievement",
    "Actor",
    "Alarm",
    "Array",
    "Artifact",
    "Buff",
    "Callback",
    "Class",
    "Color",
    "Damager",
    "Equipment",
    "Helper",
    "Initialize",
    "Instance",
    "Interactable",
    "Item",
    "Language",
    "List",
    "Net",
    "Object",
    "Player",
    "Resources",
    "Skill",
    "State",
    "Survivor",
    "Survivor_Log",
    "Wrap",

    "Actor_Post"
}

for _, c in ipairs(Classes) do
    require("./"..string.lower(c))
end



-- ========== Initialize ==========

function __initialize()
    Class.__initialize()
    
    -- Initialize these first (callback population)
    Callback.__initialize()
    -- Survivor.__initialize()

    Actor.__initialize()
    Artifact.__initialize()
    Buff.__initialize()
    Equipment.__initialize()
    -- Instance.__initialize()
    Interactable.__initialize()
    Item.__initialize()
    
    -- Language.__initialize()
end



-- ========== Hooks ==========

-- Write "Modded" under version number at top-left corner
-- gm.post_code_execute(function(self, other, code, result, flags)
--     if code.name:match("oStartMenu_Draw_0") then
--         gm.draw_set_alpha(0.5)
--         gm.draw_text(6, gm.camera_get_view_y(gm.camera_get_active()) + 20, "Modded")
--         gm.draw_set_alpha(1)
--     end
-- end)