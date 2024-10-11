-- Class

Class = {}



-- ========== Initialize ==========

Class.__initialize = function()
    Class.ACHIEVEMENT       = Array.wrap(gm.variable_global_get("class_achievement"))
    Class.ACTOR_SKIN        = Array.wrap(gm.variable_global_get("class_actor_skin"))
    Class.ACTOR_STATE       = Array.wrap(gm.variable_global_get("class_actor_state"))
    Class.ARTIFACT          = Array.wrap(gm.variable_global_get("class_artifact"))
    Class.BUFF              = Array.wrap(gm.variable_global_get("class_buff"))
    Class.CALLBACK          = Array.wrap(gm.variable_global_get("class_callback"))
    Class.DIFFICULTY        = Array.wrap(gm.variable_global_get("class_difficulty"))
    Class.ELITE             = Array.wrap(gm.variable_global_get("class_elite"))
    Class.ENDING_TYPE       = Array.wrap(gm.variable_global_get("class_ending_type"))
    Class.ENVIRONMENT_LOG   = Array.wrap(gm.variable_global_get("class_environment_log"))
    Class.EQUIPMENT         = Array.wrap(gm.variable_global_get("class_equipment"))
    Class.GAME_MODE         = Array.wrap(gm.variable_global_get("class_game_mode"))
    Class.INTERACTABLE_CARD = Array.wrap(gm.variable_global_get("class_interactable_card"))
    Class.ITEM              = Array.wrap(gm.variable_global_get("class_item"))
    Class.ITEM_LOG          = Array.wrap(gm.variable_global_get("class_item_log"))
    Class.MONSTER_CARD      = Array.wrap(gm.variable_global_get("class_monster_card"))
    Class.MONSTER_LOG       = Array.wrap(gm.variable_global_get("class_monster_log"))
    Class.SKILL             = Array.wrap(gm.variable_global_get("class_skill"))
    Class.STAGE             = Array.wrap(gm.variable_global_get("class_stage"))
    Class.SURVIVOR          = Array.wrap(gm.variable_global_get("class_survivor"))
    Class.SURVIVOR_LOG      = Array.wrap(gm.variable_global_get("class_survivor_log"))
end