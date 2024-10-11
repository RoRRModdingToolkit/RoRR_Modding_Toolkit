-- Helper

Helper = Proxy.new()



-- ========== Static Methods ==========

Helper.table_has = function(t, value)
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end


Helper.table_remove = function(t, value)
    for i, v in pairs(t) do
        if v == value then
            table.remove(t, i)
            return
        end
    end
end


Helper.table_get_keys = function(t)
    local keys = {}
    for k, v in pairs(t) do
        keys:insert(k)
    end
end


Helper.table_merge = function(...)
    local new = {}
    for _, t in ipairs{...} do
        for k, v in pairs(t) do
            if tonumber(k) then
                while new[k] do k = k + 1 end
            end
            new[k] = v
        end
    end
    return new
end



return Helper