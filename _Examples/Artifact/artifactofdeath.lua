-- RMTtest v1.0.0
-- RoRRModdingToolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")

mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            Artifact = m.Artifact
            Instance = m.Instance
            Resources = m.Resources
            break
        end
    end
end)

if hot_reloading then
    __initialize()
end
hot_reloading = true

local PATH = _ENV["!plugins_mod_folder_path"]

local kill_player = nil

kill_player = function(player)
    if player.dead then return end

    player.hp = -1
    Alarm.create(kill_player, 1, player)
end

__initialize = function()

    local artifact_death = Artifact.new("RMT", "death")

    artifact_death:set_text("Death", "Artifact Of Death", "When one player dies, everyone dies. Enable only if you want to truly put your teamwork and individual skill to the ultimate test.")

    artifact_death:onDeath(function(self, other, result, args)
        if not artifact_death.active then return end

        if self.object_name ~= "oP" then return end

        local players = Instance.find_all(gm.constants.oP)

        for _, player in ipairs(players) do
            if not player.dead then
                kill_player(player)
            end
        end
    end)
end