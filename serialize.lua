--[[
Code found in the Lua textbook, more general than the code
found below, but I only intend to use simple tables so I'll go with
a less general but more readable solution
--]]
--[[
function basicSerialize (value)
    if type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        return string.format("%q",value)
    else
        error("basicSerialize only handles numbers and strings", 2)
    end
end

function save (name, value, saved)
    saved = saved or {}       -- initial value
    io.write(name, " = ")
    if type(value) == "number" or type(value) == "string" then
        io.write(basicSerialize(value), "\n")
    elseif type(value) == "table" then
        if saved[value] then    -- value already saved?
            io.write(saved[value], "\n")  -- use its previous name
        else
            saved[value] = name   -- save name for next time
            io.write("{}\n")     -- create a new table
            for k,v in pairs(value) do      -- save its fields
                local fieldname = string.format("%s[%s]", name,
                basicSerialize(k))
                save(fieldname, v, saved)
            end
        end
    else
        error("cannot save a " .. type(value))
    end
end
--]]

function iwrite(num, ...)
    for i=num,1,-1 do
        io.write("\t")
    end
    if ... then
        io.write(...)
    end
end

function serialize (item,indent)
    indent = indent or 0

    if type(item) == "number" then
        io.write(item)
    elseif type(item) == "string" then
        io.write(string.format("%q", item))
    elseif type(item) == "table" then -- assume no shared subtables
                                      -- and no cycles in the table
        io.write("{\n")
        for k,v in pairs(item) do
            iwrite(indent, "\t[")
            serialize(k)
            io.write("] = ")
            serialize(v,indent+1)
            io.write(",\n")
        end
        iwrite(indent,"}")
    else
        error("cannot serialize a " .. type(item))
    end
end

function save (name, item)
    io.write(name, " = ")
    serialize(item)
    io.write("\n")
end
