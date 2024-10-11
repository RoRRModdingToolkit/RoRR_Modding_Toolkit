-- Helper

Helper = Proxy.new()



-- ========== Static Methods ==========

Helper.table_get_keys = function(t)
    local keys = {}
    for k, v in pairs(t) do
        keys:insert(k)
    end
end



-- ========== Lock proxy after setup ==========

Helper:lock()