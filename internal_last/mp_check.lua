-- Multiplayer Check

text_x = nil
text_y = nil
ui_hook = 0     -- Have the hook automatically stop itself (so it doesn't make unnecessary checks later)

gm.post_code_execute("gml_Object_oStartMenu_Draw_73", function(self, other, code, result, flags)
    -- oStartMenu seems very prone to deleting itself from
    -- all means of finding it except by looping through this
    local startMenu = nil
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == gm.constants.oStartMenu then
            startMenu = Instance.wrap(inst)
            break
        end
    end

    local opacity = 1.0
    if startMenu and startMenu:exists() then
        startMenu.menu[3].disabled = true
        opacity = 1.0 - startMenu.menu_transition
    end

    ui_hook = 10
    if (not text_x) or (not text_y) then return end

    gm.draw_set_font(2.0)
    gm.draw_set_halign(1)
    gm.draw_set_valign(1)
    local col = {Color.ORANGE, Color.BLACK, Color.BLACK}
    for i = 3, 1, -1 do
        local c = col[i]
        gm.draw_text_color(text_x, text_y + i, "1 incompatible mod", c, c, c, c, opacity)
    end
end)

gm.post_script_hook(gm.constants._ui_draw_box_text, function(self, other, result, args)
    if ui_hook <= 0 then return end
    if args[5].value == Language.translate_token("ui.title.startOnline") then
        text_x = args[1].value - 20 + args[3].value/2
        text_y = args[2].value - 2 + args[4].value/2
    end
    ui_hook = ui_hook - 1
end)