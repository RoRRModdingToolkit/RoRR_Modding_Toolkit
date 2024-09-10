-- Language

Language = {}

-- EDIT: Something something WARNING recursive_directory
-- doesn't error but maybe worth checking out sometime



-- ========== Functions ==========

local function load_from_folder(folder_path)
    local lang = gm._mod_language_getLanguageName()

    local files = path.get_files(folder_path)
    for _, file in ipairs(files) do
        if string.sub(file, -(#lang + 5), -6) == lang then
            gm.translate_load_file(gm.variable_global_get("_language_map"), file)
        end
    end
end


Language.load_from_mods = function()
    -- Loop through all mods
    for i, mod in pairs(mods) do
        if type(mod) == "table" then

            -- Search for a "language" folder in both root and "/plugins"
            local check_paths = {
                mod["!plugins_mod_folder_path"],
                mod["!plugins_mod_folder_path"].."/plugins"
            }

            for j, check_path in ipairs(check_paths) do
                local folders = path.get_directories(check_path)
                for k, folder_path in ipairs(folders) do
                    if string.lower(string.sub(folder_path, -8, -1)) == "language" then
                        load_from_folder(folder_path)
                    end
                end
            end

        end
    end
end



-- ========== Hooks and Other ==========

-- Language.__initialize = function()
--     -- Load once after initial game setup
--     Language.load_from_mods()
-- end


gm.post_script_hook(gm.constants.translate_load_active_language, function(self, other, result, args)
    -- Load on language change
    Language.load_from_mods()
end)