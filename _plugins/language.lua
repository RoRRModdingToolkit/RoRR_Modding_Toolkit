-- Language

Language = {}



-- ========== Static Methods ==========

Language.translate_token = function(token)
    local text = gm.ds_map_find_value(gm.variable_global_get("_language_map"), token)
    if text then return text end
    return token
end



-- ========== Functions ==========

local function load_from_folder(folder_path)
    local lang = gm._mod_language_getLanguageName()

    local eng_file = nil
    local translated = false

    local files = path.get_files(folder_path)
    for _, file in ipairs(files) do
        local file_lang = string.sub(path.stem(file), -(#lang), -1)
        if file_lang == "english" then eng_file = file end
        if file_lang == lang then
            translated = true
            gm.translate_load_file(gm.variable_global_get("_language_map"), file)
        end
    end

    if (not translated) and eng_file then
        gm.translate_load_file(gm.variable_global_get("_language_map"), eng_file)
    end
end


local function load_from_mods()
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
    load_from_mods()
end)