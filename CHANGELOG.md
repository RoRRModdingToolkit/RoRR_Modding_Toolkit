### v1.0.0
* Initial release

### v1.0.1 (unreleased and docs not updated)
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
* Item.set_tier : Now positions the log in the correct tier group when viewing in Logs and Unlockables.
* Added Item.spawn_drop