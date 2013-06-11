local helpers = {}
local function incPos (pos,sizes)
    -- increment the first pos
    pos[1] = pos[1] + 1
    for i,size in ipairs(sizes) do
        -- if the pos is larger then the size, carry to the next pos
        if pos[i] > size then
            pos[i] = 1
            pos[i+1] = pos[i+1] + 1
        end
    end
end

function helpers.combinations(...)
    local arg = table.pack(...)

    -- First check for nil arguments
    for i=1,arg.n do
        if arg[i] == nil then
            error("All arguments must be tables or one table of tables. Got nil at position: "..i,2)
        end
    end

    -- if there is only one argument, then it should be a table of
    -- tables, and the combinations of those will be found
    if arg.n == 1 then
        arg = arg[1]
    end

    -- error/type checking
    for i,v in ipairs(arg) do
        if type(v) ~= "table" then
            error("All arguments must be tables or one table of tables. Got "..type(v).." at position: "..i,2)
        end
        if type(v) == "table" and #v == 0 then
            error("All tables must have nonzero length. Table "..i.." has length zero",2)
        end
    end

    local positions = {}
    local sizes = {}
    for i,v in ipairs(arg) do
        positions[i] = 1
        sizes[i] = #arg[i]
    end

    -- as soon as the iterator is called this will be incremented back
    -- up to 1
    positions[1] = 0

    -- return the iterating closure
    return function ()

        -- if all positions are at their size then we are done
        local done = true
        for i,v in ipairs(sizes) do
            if positions[i] ~= v then
                done = false
                break
            end
        end

        -- if we are done return nil, else increment and return the
        -- combination
        if done then
            return nil
        else
            -- increment to the next combination
            incPos(positions,sizes)

            -- collect the combination in a table
            local ret = {}
            for i,v in ipairs(arg) do
                table.insert(ret,v[positions[i]])
            end

            -- return the combinations as separate values
            return table.unpack(ret)
        end
    end
end

-- arrayType checks the that the type of every element of array is ty
-- (uses ipairs so it is ok to have other fields)
function helpers.arrayType(array,ty)
    for i,v in ipairs(array) do
        if type(v) ~= ty then
            return false
        end
    end
    return true
end

-- copy tables
local function tabCopy(t,seen)
    seen = seen or {}
    if t == nil then return nil end
    if seen[t] then return seen[t] end

    local nt = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            nt[k] = tabCopy(v,seen)
        else
            nt[k] = v
        end
    end
    seen[t] = nt
    return nt
end
helpers.tabCopy = tabCopy

-- this is a helper for aldermanGrant.lua, it gives all possible
-- indecies for the intersections on the upper half of the tetrahedron
-- that is, all integer combinations of i and j such that:
-- abs(i) <= N
-- abs(j) <= N
-- abs(i)+abs(j) <= N
function helpers.intersections(n)
    N = math.floor(n)
    if n ~= N then
        error("n must be an integer",2)
    end

    local i = -N-1
    local j = 0
    return function ()
        if i >= N then
            return nil
        elseif j < N-math.abs(i) then
            j = j+1
            return i,j
        else
            i = i+1
            j = -(N-math.abs(i))
            return i,j
        end
    end
end

--[[
functions for moving between nodes on the triangle graph
triangles are represented in the form:
{m={i=0,j=0},l={i=0,j=1},r={i=1,j=0}}
--]]

local function moveU(tri)
    tri.m.j = tri.m.j + 1
    tri.l.j = tri.l.j + 1
    tri.r.j = tri.r.j + 1
end
local function moveD(tri)
    tri.m.j = tri.m.j - 1
    tri.l.j = tri.l.j - 1
    tri.r.j = tri.r.j - 1
end

local function moveR(tri)
    tri.m.i = tri.m.i + 1
    tri.l.i = tri.l.i + 1
    tri.r.i = tri.r.i + 1
end
local function moveL(tri)
    tri.m.i = tri.m.i - 1
    tri.l.i = tri.l.i - 1
    tri.r.i = tri.r.i - 1
end

local function mirror(tri)
    ret = tabCopy(tri)
    ret.l.i = -ret.l.i
    ret.l.j = -ret.l.j
    ret.m.i = -ret.m.i
    ret.m.j = -ret.m.j
    ret.r.i = -ret.r.i
    ret.r.j = -ret.r.j
    return ret
end

--[[
generator function for the iterator factory below (triangles).  there
are four triangle orientations with two orientations occupying each
face of the octahedron such that opposite quadrants have the same two
orientations.
--]]
local function triGen(N)
    local firstTri -- The first triangle defines the orientation
    local topTri   -- The first triangle in a row
    local tri      -- The current triangle under consideration
    -- First and third quadrants
    -- Orientation 1
    firstTri = {m={i=0,j=0},l={i=1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N do
        for j=1,N-i+1 do
            coroutine.yield(tabCopy(tri))-- First quadrant
            coroutine.yield(mirror(tri)) -- Third quadrant
            moveR(tri)
        end
        moveU(topTri)
        tri = tabCopy(topTri)
    end
    -- Orientation 2
    firstTri = {m={i=1,j=1},l={i=1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N-1 do -- there are fewer triangles in these orientations
        for j=1,N-i do
            coroutine.yield(tabCopy(tri))-- First quadrant
            coroutine.yield(mirror(tri)) -- Thrid quadrant
            moveR(tri)
        end
        moveU(topTri)
        tri = tabCopy(topTri)
    end

    -- Second and fourth quadrants
    -- Orientation 3
    firstTri = {m={i=0,j=0},l={i=-1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N do
        for j=1,N-i+1 do
            coroutine.yield(tabCopy(tri))-- Second
            coroutine.yield(mirror(tri)) -- Fourth
            moveL(tri) -- moving left now
        end
        moveU(topTri)
        tri = tabCopy(topTri)
    end
    -- Orientation 4
    firstTri = {m={i=-1,j=1},l={i=-1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N-1 do -- there are fewer triangles in these orientations
        for j=1,N-i do
            coroutine.yield(tabCopy(tri))-- Second
            coroutine.yield(mirror(tri)) -- Fourth
            moveL(tri) -- moving left
        end
        moveU(topTri)
        tri = tabCopy(topTri)
    end
end

--[[
an iterator factory that takes a number N, that is the Alderman-Grant
N parameter. The iterator iterates through all of the triangles in the
upper half of the octahedron.
triangles are represented in the form:
{m={i=0,j=0},l={i=0,j=1},r={i=1,j=0}}
--]]
function helpers.triangles(N)
    local co = coroutine.create(function () triGen(N) end)
    return function ()
        local code, res = coroutine.resume(co)
        return res
    end
end

return helpers
