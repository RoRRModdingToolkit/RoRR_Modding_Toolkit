-- Language

Language = {}



-- ========== Functions ==========

local function load_from_folder(folder_path)
    local lang = gm._mod_language_getLanguageName()

    local files = path.get_files(folder_path)
    for _, file in ipairs(files) do
        if string.sub(path.stem(file), -(#lang), -1) == lang then
            gm.translate_load_file(gm.variable_global_get("_language_map"), file)
        end
    end
end


Language.load_from_mods = function()
    -- Loop through all mods
    for i, mod in pairs(mods) do
        if type(mod) == "table" and string.sub(mod["!plugins_mod_folder_path"], -7, -1) ~= "plugins" then

            -- Search for a "language" folder in both root and "/plugins"
            local check_paths = {
                mod["!plugins_mod_folder_path"]
            }

            for j, check_path in ipairs(check_paths) do
                local folders = path.get_directories(check_path)
                for k, folder_path in ipairs(folders) do
                    if string.lower(string.sub(folder_path, -8, -1)) == "language" then
                        load_from_folder(folder_path)

                    -- Only check "/plugins" if the plugins folder actually exists
                    elseif string.lower(string.sub(folder_path, -7, -1)) == "plugins" then
                        table.insert(check_paths, check_path.."/plugins")
                    end
                end
            end

        end
    end
end



-- ========== Hooks and Other ==========


gm.post_script_hook(gm.constants.translate_load_active_language, function(self, other, result, args)
    -- Load on language change
    Language.load_from_mods()
end)