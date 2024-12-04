-- Particle

Particle = Proxy.new()



-- ========== Static Methods ==========

Particle.new = function(namespace, identifier)
    local part = Particle.find(namespace, identifier)
    if part then return part end

    local part = gm.part_type_create_w(namespace, identifier)
    return Particle.wrap(part)
end


Particle.find = function(namespace, identifier)
    if not identifier then
        local array = GM.string_split(namespace, "-")
        namespace, identifier = array[1], array[2]
        if not identifier then
            log.warning("Particle identifier not provided", 2)
            return nil
        end
    end

    local lookup = gm.variable_global_get("ResourceManager_particleTypes").__namespacedAssetLookup
    if not lookup[namespace] then return nil end
    if not lookup[namespace][identifier] then return nil end
    return Particle.wrap(lookup[namespace][identifier])
end


Particle.find_all = function(namespace)
    local lookup = gm.variable_global_get("ResourceManager_particleTypes").__namespacedAssetLookup
    if not lookup[namespace] then return {}, 0 end

    local parts = {}
    local names = GM.variable_struct_get_names(lookup[namespace])
    for _, name in ipairs(names) do
        table.insert(parts, Particle.wrap(lookup[namespace][name]))
    end
    return parts, #parts > 0
end


Particle.wrap = function(value)
    return make_wrapper(value, "Particle", metatable_particle, lock_table_particle)
end



-- ========== Instance Methods ==========

methods_particle = {

    create = function(self, x, y, count, system)
        GM.part_particles_create(system or 0, x, y, self, count or 1)
    end,


    set_sprite = function(self, sprite, animate, stretch, random)
        GM.part_type_sprite(self, sprite, animate, stretch, random)
    end,

}
lock_table_particle = Proxy.make_lock_table({"value", "RMT_object", table.unpack(Helper.table_get_keys(methods_particle))})



-- ========== Metatables ==========

metatable_particle = {
    __index = function(table, key)
        -- Methods
        if methods_particle[key] then
            return methods_particle[key]
        end
        return nil
    end,
    

    __newindex = function(table, key, value)
        -- Setter
        log.error("Particle has no properties to set; use methods instead", 2)
    end,


    __metatable = "particle"
}



return Particle