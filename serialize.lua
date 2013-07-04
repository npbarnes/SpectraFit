local s = {}

-- indented write
-- prints '\t' num times and passes
-- the rest of the parameters to io.write()
local function iwrite(num, file,...)
    for i=1,num do
        file:write("\t")
    end
    if ... then
        file:write(...)
    end
end

--[[ serialize()
printes a human and lua understandable representation of numbers,
strings, and simple tables (i.e. no shared subtables, no cycles,
and none of the keys are tables).
Note 1: Shared subtables will print fine, but won't be properly
reconstructed when the resulting code is run.
Note 2: Cycles will result in an infinite loop
Note 3: Haveing tables as keys will result in an error
Note 4: Metatables are not saved
it is the programmers responsibility to be aware of these things
--]]
function s.serialize (item,file,indent)
    if type(file) == "string" then
        file = assert(io.open(file,"w"))
    end
    file = file or io.output()
    indent = indent or 0

    if type(item) == "number" then
        file:write(item)
    elseif type(item) == "string" then
        file:write(string.format("%q", item))
    elseif type(item) == "boolean" then
        file:write(tostring(item))
    elseif type(item) == "table" then -- assume no shared subtables
                                      -- and no cycles in the table
        file:write("{\n")
        for k,v in pairs(item) do
            if type(k) == "table" then
                error("Cannot serialize tables indexed by tables")
            end
            iwrite(indent,file, "\t[")
            s.serialize(k,file)
            file:write("] = ")
            s.serialize(v,file,indent+1)
            file:write(",\n")
        end
        iwrite(indent,file,"}")
    else
        error("cannot serialize a " .. type(item))
    end
end

--[[
serializes() the item with "name = " in front of it and a newline
at the end.
If file is given everything will be printed to file instead of stdout
name should be a valid lua identifier, but it doesn't have to be
--]]
function s.save (name, item, file)
    if type(file) == "string" then
        file = assert(io.open(file,"w"))
    end
    file = file or io.output()

    file:write(name, " = ")
    s.serialize(item,file)
    file:write("\n")
end

return s
