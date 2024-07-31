-- Instance

Instance = {}



-- ========== Enums ==========





-- ========== Functions ==========

Instance.exists = function(inst)
    return gm.instance_exists(inst) == 1.0
end


Instance.find = function(index)
    local inst = gm.instance_find(index, 0)
    if not Instance.exists(inst) then return nil end
    return inst
end


Instance.find_all = function(index)
    local insts = {}
    for i = 0, gm.instance_number(index) - 1 do
        table.insert(insts, gm.instance_find(index, i))
    end
    return insts, #insts > 0
end