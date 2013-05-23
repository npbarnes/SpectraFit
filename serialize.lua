function basicSerialize (name, value)
    file:write(name, " = ")
    if type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        return string.format("%q",value)
    else
        error("basicSerialize only handles numbers and strings", 2)
    end
end

-- this implementation will only work for tables whose indecies are
-- all strings or numbers and whose subtables (and subsubtables...)
-- meet the same criteria
function tableSerialize(name,value,saved)
    if type(value) ~= "table" then
        error("tableSerialize is only for tables",2)
    end

    local ret = name .. " = "

    -- the `saved' table is indexed by table references
    if saved[value] then -- if this subtable has been saved
        ret = ret .. saved[value] .. "\n"
    else
        saved[value] = name
        ret = ret .. "{}\n"
        for k,v in pairs(value) do -- save its fields
            -- this line is why you can't serialize tables
            -- indexed with tables (see basicSerialize)
            local fieldname =
                    string.format("%s[%s]",name,basicSerialize(k))
            ret = ret .. serialize(fieldname,v,saved)
        end
    end

    return ret
end

function serialize(name,value,saved)
    saved = saved or {}     -- initial value
    if type(value) == "number" or type(value) == "string" then
        return basicSerialize(name, value) .. "\n"
    elseif type(value) == "table" then
        return tableSerialize(name, value, saved) .. "\n"
    else
        error("cannot serialize a " .. type(value))
    end
end


function save (name,value,file)
    file = file or io.stdio
    file:write( serialize(name,value),"\n")
end
