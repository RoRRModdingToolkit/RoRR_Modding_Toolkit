### v1.0.0
* Initial release

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

### v1.0.3
* Added hitbox system for custom objects
    * Object.set_hitbox
    * Object.is_colliding
    * Object.get_collisions
    * Object.get_collision_box