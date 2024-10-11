-- Wrap

-- This class contains static methods for wrapping and
-- unwrapping GameMaker values with the class wrappers.

Wrap = Proxy.new()



-- ========== Static Methods ==========

Wrap.wrap = function(value)
    -- Array
    if gm.is_array(value) then
        return Array.wrap(value)
    end

    -- List
    -- NOTE: Can't really wrap this automatically since it's just an index number,
    -- meaning that normal integer variables can get caught in the wrap as well
    -- if gm.ds_exists(value, 1) then  -- 1 is "ds_type_list"
    --     return List.wrap(value)
    -- end

    -- Instance
    if Instance.is(value) then
        return Instance.wrap(value)
    end

    return value
end


Wrap.unwrap = function(value)
    if type(value) == "table" and value.RMT_object then return value.value end
    return value
end