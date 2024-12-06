-- Actor Post

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    actorData = actor:get_data(nil, _ENV["!guid"])

    -- Run onPostStatRecalc
    if actorData.post_stat_recalc then
        actorData.post_stat_recalc = nil
        actor_onPostStatRecalc(actor)
        inst_onPostStatRecalc(actor)
        item_onPostStatRecalc(actor)
        equipment_onPostStatRecalc(actor)
        buff_onPostStatRecalc(actor)
    end
end)