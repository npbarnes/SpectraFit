-- indented write
-- prints '\t' num times and passes
-- the rest of the parameters to io.write()
function iwrite(num, ...)
    for i=1,num do
        io.write("\t")
    end
    if ... then
        io.write(...)
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
it is the programmers responsibility to be aware of these things
--]]
function serialize (item,indent)
    indent = indent or 0

    if type(item) == "number" then
        io.write(item)
    elseif type(item) == "string" then
        io.write(string.format("%q", item))
    elseif type(item) == "boolean" then
        io.write(tostring(item))
    elseif type(item) == "table" then -- assume no shared subtables
                                      -- and no cycles in the table
        io.write("{\n")
        for k,v in pairs(item) do
            if type(k) == "table" then
                error("Cannot serialize tables indexed by tables")
            end
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

--[[
serializes() the item with "name = " in front of it and a newline
at the end.
If file is given everything will be printed to file instead of stdout
name should be a valid lua identifier, but it doesn't have to be
--]]
function save (name, item, file)
    local currFile = io.output()
    -- if file is nil then this line does nothing
    io.output(file)

    io.write(name, " = ")
    serialize(item)
    io.write("\n")

    io.output(currFile)
end
