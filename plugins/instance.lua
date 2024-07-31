-- Instance

Instance = {}



-- ========== Tables ==========

Instance.chests = {
    gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5,
    gm.constants.oChestHealing1, gm.constants.oChestDamage1, gm.constants.oChestUtility1,
    gm.constants.oChestHealing2, gm.constants.oChestDamage2, gm.constants.oChestUtility2,
    gm.constants.oGunchest
}


Instance.shops = {
    gm.constants.oShop1, gm.constants.oShop2
}


Instance.teleporters = {
    gm.constants.oTeleporter, gm.constants.oTeleporterEpic
}



-- ========== Functions ==========

Instance.exists = function(inst)
    return gm.instance_exists(inst) == 1.0
end


Instance.find = function(index)
    if type(index) ~= "table" then index = {index} end

    for _, ind in ipairs(index) do
        local inst = gm.instance_find(ind, 0)
        if Instance.exists(inst) then return inst end
    end

    return nil
end


Instance.find_all = function(index)
    if type(index) ~= "table" then index = {index} end

    local insts = {}

    for _, ind in ipairs(index) do
        for n = 0, gm.instance_number(ind) - 1 do
            table.insert(insts, gm.instance_find(ind, n))
        end
    end

    return insts, #insts > 0
end