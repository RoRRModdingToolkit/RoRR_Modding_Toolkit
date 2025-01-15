### v1.2.12
* Message : Added `read`/`write` for `double`.
* Buff : Buff array extension now uses `init_actor_default` and runs only once per actor.

### v1.2.11
* Alarm : Fixed `create` args being `nil` for args past the first one.
* Skill : Now overwrites `callback_execute` `result.value` if a non-`nil` value is returned.

### v1.2.10
* Player : Removed internal callback that automatically froze default skill cooldown while an override was active.
    * Even though this is most likely desired in 99% of cases, it is better to allow the user control over it.
* Actor
    * Added `freeze_default_skill`, `freeze_active_skill`, and `freeze_other_overrides` (to aid with the above)
    * Added `override_default_skill_cooldown` and `override_active_skill_cooldown`

### v1.2.9
* Actor : `fire_` methods now default to `sNone` instead of `-1` if no sprite is provided.
    * Otherwise damage numbers do not show for clients.
* Added Global class; this is just a shortform of `GM.variable_global_get/set`.

### v1.2.8
* Callback, Callback_Raw : `add` can now accept numbers from `Callback.TYPE` enum.

### v1.2.7
* Callback
    * Previously existing class renamed to Callback_Raw.
    * Callback now passes wrapped args.

### v1.2.6
* Item, Equipment : `toggle_loot` and related methods can now modify pools while in a run.
* Instance : Getting from an invalid instance will now return `nil`.

### v1.2.5
* Item, Equipment, Buff, Instance, Actor, Player
    * Removed `onDamageCalculate` and `onDamageCalculateProc` callbacks due to errors (`hit_info` does not exist for client attacks for whatever reason).
* Resources
    * Calling `sprite_load` for an existing sprite now allows you to modify the sprite's origin.
    * Removed `sprite_duplicate` since sprites really should not be cloned that way (no namespace-identifier lookup).
    * `sfx_load` now returns the existing sound ID for a namespace-identifier that already exists.

### v1.2.4
* Difficulty : Removed all class callbacks entirely
    * Mostly redundant; just add a Callback and check with `is_active`
    * Also lack of control over `onActive`/`onInactive`

### v1.2.3
* Fixed online lobbies crashing when "Allow rule voting" was enabled with custom difficulties.
* Net : Changed internals for `get_type` (and by extension `is_single`, `is_host`, `is_client`).

### v1.2.2
* Net : Added `is_single`, `is_host`, `is_client`
* Helper : Added `sync_crate_contents`
* Item : `spawn_crate` now automatically syncs crate contents.
* Array : Added `find`

### v1.2.1
* Resources : No longer triggers a crash when a resource function is called before base game initialization.
* Object : No longer runs a callback if `inst` is actually non-existent (not sure what causes this).

### v1.2.0
* Added Attack_Info class
* Added Hit_Info class
* Added Particle class
* All class arrays : Added default `find_all` implementation
    * Item : Original `find_all` implementation removed
* Item, Equipment, Buff, Instance, Actor, Player
    * Several callbacks renamed (e.g., `onPickup` -> `onAcquired`) and rewritten.
        * Namely, callbacks that passed "`damager`" will now either pass `attack_info` or `hit_info`.
    * Added callbacks `onPickupCollected` and `onDamageCalculate`
* Item
    * Replaced `TYPE` with `STACK_KIND`; affects `actor:item_give`, etc. as well.
    * `find_all` now returns _every_ item if no filter is provided.
* Item, Equipment : Added `is_loot`
* Callback : Fixed `remove` not actually doing anything.
    * Also fixed various `remove_callbacks` that may or may not have been broken.
* Actor : `fire_` methods now have an optional `can_proc` bool argument (default `true`).
    * `fire_` methods also return the attack instance only now.
    * `buff_remove` now calls `recalculate_stats` when removing stacks.
* Helper
    * Added `is_true` and `is_false`
    * Added `read_json`
* Instance : Fixed `get_data` pulling a different table in certain circumstances.
* Array, List : `new` overload: can now supply a lua table as a single argument.
* Monster_Log : `new` now takes in `namespace, identifier` instead of a monster card.
* Alarm
    * `create` now returns the alarm table.
    * Added `destroy`
* Array : `contains` last 2 args are now optional.
* Interactable_Object : Renamed from Interactable, and now only adds one extra callback.
* Minor optimizations in various callbacks.
* Now prevents online play if any (RMT-dependent) incompatible mods are loaded.

---

### v1.1.32
* Actor : Added `apply_dot`
* Survivor : Fixed some default sprites being wrong.
* Damager : Added `get_attack_flag`

### v1.1.31
* Item, Buff : Fixed lag related to internal change of `onStep` and `onDraw` callbacks.

### v1.1.30
* Item, Actor, Instance : Fixed networking-related error for `onHit` callbacks.
    * `onHit` and `onHitAll` now pass `hit_info` struct as another argument.

### v1.1.29
* Item : `onStep` callbacks now use `step_actor` internally.
    * Added `onPreStep` callback
* Item, Buff : `onDraw` callbacks now use `draw_actor` internally.
    * Added `onPreDraw` callbacks
* Damager : Added `ATTACK_FLAG` and `set_attack_flags`

### v1.1.28
* Instance : `exists` no longer throws an error if the argument is a string.
* Damager : Added key `instance` (when applicable) to get the attack instance creating the damager.

### v1.1.27
* Instance/Wrap : Reverted automatic wrapping of all valid IDs into Instance objects as a result of last update.

### v1.1.26
* Instance
    * The variable `id` is no longer wrapped as an Instance object when getting it from an instance.
    * Removed `is` method (redundant; extra checks now embedded within `exists`).
        * Fixed crashing when `value` argument was an invalid type.
* Minor callback optimizations for several classes.

### v1.1.25
* Actor : Fixed `fire_explosion_local` (wrong argument count).

### v1.1.24
* Instance
    * Added `get_CInstance`
    * `wrap` now accepts numerical instance IDs.

### v1.1.23
* Custom environment logs are now sorted by stage progression index.

### v1.1.22
* Buff : Fixed error in apply_buff_internal hook.
* Monster_Card : Added `SPAWN_TYPE` enum.
* Actor
    * `fire_` methods now return the actual attack instance as a second unpacked return value.
    * Added `fire_explosion_local`
* Instance : `wrap` now returns an invalid wrapped instance (value of -4) if the argument doesn't exist.
* Net : Removed most of the class except `TYPE` and `get_type()`.
* Added Packet
* Added Message

### v1.1.21
* Damager : Added `add_offset`.
* Mod : Class reference is now public (whoops again).
* Callback : `TYPE` is now populated on mod load and not during Initialize.

### v1.1.20
* Helper : Fixed specific error in `log_struct`.
* State
    * Fixed bad instance method callback name.
    * Now writes to callback_execute `return` value if the function returns a value.

### v1.1.19
* Equipment : `new` now has a `[no_log]` parameter.
* Instance : Fixed error when using `callback_exists` before any callbacks are added.

### v1.1.18
* Actor
    * `add_skill_override`
    * `remove_skill_override`
    * `refresh_skill`
* Instance : Fixed reported error in onHit callback.
* Wrap : Is now a public reference again (whoops).
* Removed accidentally-left debug logging from last patch.

### v1.1.17
* Helper
    * `log_hook` now logs struct variables if self and other are structs.
    * `log_struct` now adds borders above and below it.
* Actor : Added `set_default_skill`.
* Skill
    * Fixed onStep callback (by making custom ones; now replaced with onPreStep and onPostStep).
    * Fixed callback `args[3]` being incorrectly wrapped as a Skill object when it is a struct.

### v1.1.16
* Resources : `sprite_load` now returns the existing sprite of a given namespace-identifier if it already exists.
* `pairs` now works properly when iterating over proxy tables.
* Skill : Added `is_unlocked`, `add_achievement`, and `progress_achievement`.

### v1.1.15
* Initialize : Forgot to add the error catching to new initialize calling lmao (only the legacy support had it).
* ReturnOfModding version number change in manifest.

### v1.1.14
* Now using ENVY to make own global variables private to self, and for new class ref import methods.
* Internal restructuring to make all classes read-only (does not affect end-user functionality as listed on the docs).
    * Previously, a user could write `Item.new = "abc"` and brick every item mod for example.
* Changed required one-line (for auto-adding class refs) and initialize call.
    * Legacy support : If `__initialize` or `__post_initialize` are detected, then the classes will be automatically added to the mod's `_G`.
* Initialize : Will now print a message to console if a mod's initialize/post_initialize fails to run.
    * They will also now run in mod load order.
* Added wrappers for remaining classes in the global `class_` arrays.
* Added Proxy class.
* Language : Fallback to english.json if the language file in a mod doesn't exist for the current language.
    * Added `register_autoload` (automatically called if importing with `.auto()`).
* Difficulty : `allow_blight_spawns` renamed to `set_allow_blight_spawns` to avoid name conflict with class_array property.
* Stage : `set_index` cap is now equal to the size of `stage_progression_order`.
* Player : Added `remove_callback` and `callback_exists`.
* Alarm
    * If an error is thrown from an alarm function, the source of the alarm will now be logged.
    * Fixed errors arising from starting a new run before previously added alarms were executed.

### v1.1.13
* Instance : get_data tables and Instance callbacks are no longer instantly deleted for players on-death.
* Player : Added add_callback, which automatically assigns Instance callbacks to the local player on run start.
* Stage : clear_rooms now removes environment logs properly.
* Language : translate_token now returns the input if the associated text cannot be found.

### v1.1.12
* Instance : Added callback system for an individual instance.
    * Callbacks are removed on the instance's destruction.

### v1.1.11
* Added Difficulty class
* Added Ending class
* Added Gamemode class
* Actor : Added callback_exists
* Stage : Added clear_rooms
* Initialize : Other mod __initialize calls will no longer be affected by one failing.

### v1.1.10
* [!] Interactable class will be changed or deprecated soon.
* Added Mod class
* Added Interactable_Card class
* Added Monster_Card class
* Added Stage class

### v1.1.9
* Object : `create` now defaults to position (0, 0) if none is specified.
* Skill : Now wraps and unwraps when getting/setting properties.
* Survivor_Log : Now wraps and unwraps when getting/setting properties.
* Fixed error when pressing the equipment use key without an equipment item.

### v1.1.8
* Return values from GM class are now wrapped when applicable.

### v1.1.7
* Actor : Added tracer argument to fire_bullet
* Damager : Added TRACER enum
* Resources : Added namespace and identifier arguments to sfx_load
* Added GM class
    * Allows for calling gm functions with wrapped arguments, which will automatically unwrap.
    * Additionally, can call with `:` syntax using wrapped Instance objects (e.g., `actor:skill_util_unlock_cooldown(skill)`, with `actor` being a wrapped Actor object).
        * Basically there is no longer a need to do `.value`.
    * Removed dedicated `actor:recalculate_stats`.

### v1.1.6
* Fixed Survivor add_skin and add_skill
* Changed Survivor set_stats_* functions' arguments to a table.
* Fixed another sfx issue related to setting maxshield in onPostStatRecalc.
    * onPostStatRecalc should now run on the same frame as onStatRecalc now instead of the next one.
* Fixed small error with internal require and some classes.

### v1.1.5
* Fixed Survivor clear_callbacks removing the automatic onInit callback used for setup.

### v1.1.4
* Fixed some internal stuff in Actor.
    * fire_direct now has optional x and y arguments.
* All `.new()` methods (that didn't already do this) will now return the existing custom content if they already exist, instead of nil.

### v1.1.3
* Actor class
    * fire_direct now has an optional direction argument.
    * Callbacks now require an ID, and can be removed.
    * Fixed onSkillUse not seeming to work properly (idk if this was an issue previously or not).
* Added clear_callbacks method to:
    * Item
    * Equipment
    * Buff
    * Object
    * Survivor
    * Skill
    * State
* General Callbacks can now be removed.

### v1.1.2
* Changed RMT's required line of code so that manually updating is no longer required.

### v1.1.1
* Added Object.PARENT enum
* Survivor class
    * Fixed some instances of Survivor get_skill and add_skill not being changed to 0-based.
    * Fixed callbacks not wrapping return arguments.
* Actor class
    * Replaced take_damage with fire_direct.
    * Reduced argument counts for Actor fire_ methods.
* Added Damager class
    * Moved all Actor enums to Damager.

### v1.1.0
* Rewrote most of the code base
* Rewrote the Survivor module
    * Added Skill, State, Survivor Log modules for Survivor creation
* Added Color module
* Complete rewrite of the wiki
    * Added a custom sidebar
    * Changed the changelog to show latest releases first

---

### v1.0.16
* Fixed Actor.damage displaying "0" for damage number.
* Fixed potential memory leak in Net module.

### v1.0.15
* Fixed Actor.find_skill_id throwing an error at skill 186 when looping (which seems to be invalid).
* Fixed memory leaks in several places caused by iterating over GameMaker arrays with ipairs, as well as accessing them with lua syntax.
    * For anyone reading this, get array sizes with gm.array_length and access elements with gm.array_get instead.
* Added Class module, containing references to the global class arrays.

### v1.0.14
* Added alarm module
   * Added Alarm.create, in an early state
* Fixed Survivor module

### v1.0.13
* Added Item.toggle_loot
* Added Equipment.toggle_loot

### v1.0.12
* Item.spawn_drop now works correctly with vanilla items.

### v1.0.11
* Fixed callback tables not populating correctly in certain circumstances and crashing.

### v1.0.10
* Optimized onStep/onDraw callback lag for real.
* Added 2 more projectiles to the Instance.projectiles table.
* Fixed literal memory leak with Buff.find when calling it a lot.
* RMT will now run its own __initialize before all other mods (not sure why this wasn't already the case).

### v1.0.9
* Added Helper.log_toolkit_stats
* Changed how onStep/onDraw callbacks work internally for several modules, heavily reducing lag.
    * EDIT: Once again I prematurely released a patch.

### v1.0.8
* Added achievement functions for Equipment
    * Equipment.add_achievement
    * Equipment.progress_achievement
* Custom Equipment item logs now appear after all the vanilla ones.

### v1.0.7
* Added Item callbacks
    * onHeal
    * onShieldBreak
* Item onBasicUse callback now works with Sniper's Snipe properly.
* Added achievement functions for Item
    * Item.add_achievement
    * Item.progress_achievement
* Added Actor callback system
* Added Actor.find_skill_id
* Added Equipment module
    * Equipment.find
    * Equipment.create
    * Equipment.set_sprite
    * Equipment.set_cooldown
    * Equipment.set_loot_tags
    * Equipment.add_callback

### v1.0.6
* Fixed apply_buff_internal error for custom buffs when an actor turned into another one (e.g., Lemurian rider being dismounted).
* Added Buff onChange callback

### v1.0.5
* Fixed Item onAttack callback error for real.
    * Item.get_stack_count will now return "0" if the actor is invalid or not a child of pActor.
* Object.is_colliding : Now works with a custom RMT Object instance as "other".
* Object.get_collisions : Now works with a custom RMT Object as "index".

### v1.0.4
* Added Instance.projectiles table
* Fixed Item onAttack callback throwing error sometimes.

### v1.0.3
* Added hitbox system for custom objects
    * Object.set_hitbox
    * Object.is_colliding
    * Object.get_collisions
    * Object.get_collision_box

### v1.0.2
* Added Actor.fire_explosion
* Added Buff onDraw callback
* Buff.get_stack_count : Now returns "0" if it returned "nil" previously
* Item.spawn_drop : Now returns the dropped instance, and spawns on the exact y position
* Added Object module
    * Object.find
    * Object.create
    * Object.spawn
    * Object.add_callback
* Instance.find, Instance.find_all : Now work with custom RMT Objects
* Added Instance.number

### v1.0.1
* Buff.remove : Can now remove a specified number of stacks.
* Buff.PROPERTY.stack_number_col : Now defaults to a size 1 array with the color 16777215 (pure white).
* Helper.log_hook
    * Fixed error when self/other was nil.
    * result now shows expanded arrays/structs.
* Added Actor module
    * Actor.fire_bullet
    * Actor.damage
    * Actor.heal
    * Actor.add_barrier
    * Actor.set_barrier
* Item.set_tier : Now positions the log at the end of the correct tier group when viewing in Logs and Unlockables.
* Added Item.spawn_drop

### v1.0.0
* Initial release