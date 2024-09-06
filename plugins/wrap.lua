-- Wrap

-- This class contains static methods for wrapping and
-- unwrapping GameMaker values with the class wrappers.

Wrap = {}


Wrap.wrap = function(value)
    -- Array
    if gm.is_array(value) then
        return Array.wrap(value)
    end

    -- List
    -- NOTE: Can't really wrap this since it's just an index number,
    -- meaning that normal integer variables can get caught in the wrap as well
    -- if gm.ds_exists(value, 1) then  -- 1 is "ds_type_list"
    --     return List.wrap(value)
    -- end

    -- Instance
    if gm.typeof(value) == "struct"
    and gm.instance_exists(value) == 1.0
    and gm.object_exists(value) == 0.0 then
        return Instance.wrap(value)
    end

    return value
end


Wrap.unwrap = function(value)
    if type(value) == "table" and value.RMT_wrapper then return value.value end
    return value
end