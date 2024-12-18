-- Multiplayer Lobby Difficulty Fix
-- by Kris

gm.post_script_hook(gm.constants.game_lobby_start, function(self, other, result, args)
    local vote_count = gm.variable_global_get("__game_lobby").rulebook.vote_count
    for i = 11, gm.variable_global_get("count_difficulty") do
        vote_count["d:"..tostring(i)] = 0
    end
end)