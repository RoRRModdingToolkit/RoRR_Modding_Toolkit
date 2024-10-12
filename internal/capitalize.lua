-- Capitalize

function capitalize_class_name(class)
    if class == "gm" then return "GM" end   -- Edge case

    local final = ""
    local arr = gm.string_split(class, "_")
    for i = 0, gm.array_length(arr) - 1 do
        local part = gm.array_get(arr, i)
        part = part:sub(1, 1):upper()..part:sub(2, #part)
        if i > 0 then final = final.."_" end
        final = final..part
    end
    return final
end