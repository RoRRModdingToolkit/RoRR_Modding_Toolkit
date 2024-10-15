-- RMTtest v1.0.0
-- RoRRModdingToolkit

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

local PATH = _ENV["!plugins_mod_folder_path"]

local kill_player = nil


kill_player = function(player)
    if player.dead then return end

    player.hp = -1
    Alarm.create(kill_player, 1, player)
end

local initialize = function()

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
Initialize(initialize)


if hot_reloading then
    initialize()
end
hot_reloading = true