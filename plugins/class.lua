-- Class

Class = {}



-- ========== Initialize ==========

Class.__initialize = function()
    Class.ACHIEVEMENT       = gm.variable_global_get("class_achievement")
    Class.ACTOR_SKIN        = gm.variable_global_get("class_actor_skin")
    Class.ACTOR_STATE       = gm.variable_global_get("class_actor_state")
    Class.ARTIFACT          = gm.variable_global_get("class_artifact")
    Class.BUFF              = gm.variable_global_get("class_buff")
    Class.CALLBACK          = gm.variable_global_get("class_callback")
    Class.DIFFICULTY        = gm.variable_global_get("class_difficulty")
    Class.ELITE             = gm.variable_global_get("class_elite")
    Class.ENDING_TYPE       = gm.variable_global_get("class_ending_type")
    Class.ENVIRONMENT_LOG   = gm.variable_global_get("class_environment_log")
    Class.EQUIPMENT         = gm.variable_global_get("class_equipment")
    Class.GAME_MODE         = gm.variable_global_get("class_game_mode")
    Class.INTERACTABLE_CARD = gm.variable_global_get("class_interactable_card")
    Class.ITEM              = gm.variable_global_get("class_item")
    Class.ITEM_LOG          = gm.variable_global_get("class_item_log")
    Class.MONSTER_CARD      = gm.variable_global_get("class_monster_card")
    Class.MONSTER_LOG       = gm.variable_global_get("class_monster_log")
    Class.SKILL             = gm.variable_global_get("class_skill")
    Class.STAGE             = gm.variable_global_get("class_stage")
    Class.SURVIVOR          = gm.variable_global_get("class_survivor")
    Class.SURVIVOR_LOG      = gm.variable_global_get("class_survivor_log")
end