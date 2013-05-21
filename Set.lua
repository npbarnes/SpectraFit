Set = {}

-- takes an array and converts it into a set
function Set:addAll (list)
    for _, l in ipairs(list) do
        self[l] = true
    end
end

function Set:add (elem)
    self[elem] = true
end

-- prints the set as a comma separated list of set elements
-- TODO: currently prints function names as well, fix this.
function Set:write()
    io.write("{")
    for index,value in pairs(self) do
        io.write(index,", ")
    end
    io.write("}\n")
end
