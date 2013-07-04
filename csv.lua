local h = require "helpers"

-- Helper
local function findCols(tab)
    local ret = {}
    for i,v in ipairs(tab) do
        table.insert(ret,#v)
    end
    return ret
end

local function csv (tab)
    local self = {}

    -- Private variables
    local table = h.tabCopy(tab)
    local rows = #table
    local cols = findCols(table)

    -- Public methods
    function self.insert(value,row,col)
        if row > rows then
            for i=rows+1,row do
                table[i] = {}
                cols[i] = 0
            end
            rows = row
        end
        if col > cols[row] then
            for i=cols[row]+1,col do
                table[row][i] = ""
            end
            cols[row] = col
        end

        table[row][col] = value
    end

    function self.save(file)
        if type(file) == "string" then
            file = assert(io.open(file,'w'))
        end
        if io.type(file) ~= "file" then
            error("file not open")
        end

        for i,row in ipairs(table) do
            for j,cell in ipairs(row) do
                file:write(cell,',')
            end
            file:write("\n")
        end
    end

    function self.load(file)
        if type(file) == "string" then
            file = assert(io.open(file,'r'))
        end
        if io.type(file) ~= "file" then
            error("file not open")
        end

        local str = file:read("*a")
        local table = {{}}

        local rownum = 1
        for row in string.gmatch(str,"(.)\n") do
            for cell in string.gmatch(row,"([^,]*),") do
                table.insert(table[rownum],tonumber(cell))
            end
            rownum = rownum + 1
            table[rownum] = {}
        end
    end

    function self.getTable()
        return table
    end

    return self
end

return csv
