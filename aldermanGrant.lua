--[[
information on these algorithms can be found in the following paper

1986 D.W. Alderman et al, "Methods for Analyzing Spectroscopic Line
Shapes.  NMR Solid Powder Patterns" J. Chem. Phys., Vol. 84, No. 7

the interpolation works by aproximating a sphere as an octahedron
positions on each face of that sphere are given by two numbers i, and j
where i = x/N and j = y/N and z can be determined by the equation
x+y+z = 1
--]]
local AG = {}

local h = require "helpers"
local Spectrum = require "spectrum"

-- returns distance from the origin times N
local RN = function (i,j,N)
    return math.sqrt(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2))
end

-- returns the distance from the origin
local R = function (i,j,N)
    return math.sqrt(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2))/N
end

-- returns the cos of the polar angle theta given i, and j
local cosTheta = function (i,j,N)
    return (N-i-j)/RN(i,j,N)
end

local sinTheta = function (i,j,N)
    return math.sqrt(1 - math.pow(N-i-j,2)/(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2)))
end

-- returns cos^2 of the azimuthal angle phi given i, and j
local cos2Phi = function (i,j,N)
    return ( i/RN(i,j,N) )/( sinTheta(i,j,N) )
end

-- this is a helper for aldermanGrant.lua, it gives all possible
-- indecies for the intersections on the upper half of the tetrahedron
-- that is, all integer combinations of i and j such that:
-- abs(i) <= N and
-- abs(j) <= N and
-- abs(i)+abs(j) <= N
local function intersections(n)
    local N = math.floor(n)
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

-- The move function change tri
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

-- The mirror functions return reflected triangles without changing tri
-- reflect over the X axis
local function mirrorX(tri)
    ret = tabCopy(tri)
    ret.l.j = -ret.l.j
    ret.m.j = -ret.m.j
    ret.r.j = -ret.r.j
    return ret
end

-- reflect over the Y axis
local function mirrorY(tri)
    ret = tabCopy(tri)
    ret.l.i = -ret.l.i
    ret.m.i = -ret.m.i
    ret.r.i = -ret.r.i
    return ret
end

-- reflect over both X and Y in turn
local function mirrorXY(tri)
    -- This is a bit less efficient because it makes two copies, but
    -- it reduces code duplication
    return mirrorY( mirrorX(tri) )
end

--[[
generator function for the iterator factory below (triangles).  It
takes advantage of the 4 fold rotational symmetry of the octahedron In
the first quadrant there are two orientations of triangles, it's
fairly strightforward to iterate through each in turn. The rest of the
triangles can be found by translations and reflections
--]]
local function triGen(N)
    local firstTri -- The first triangle defines the orientation
    local topTri   -- The first triangle in a row
    local tri      -- The current triangle under consideration

    -- Orientation 1
    firstTri = {m={i=0,j=0},l={i=1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N do
        for j=1,N-i+1 do
            coroutine.yield(tabCopy(tri)) -- First quadrant
            coroutine.yield(mirrorY(tri)) -- Second
            coroutine.yield(mirrorXY(tri))-- Third
            coroutine.yield(mirrorX(tri)) -- Fourth
            moveR(tri)
        end
        moveU(topTri)
        tri = tabCopy(topTri)
    end

    -- Orientation 2
    firstTri = {m={i=1,j=1},l={i=1,j=0},r={i=0,j=1}}
    topTri = tabCopy(firstTri)
    tri = tabCopy(firstTri)
    for i=1,N-1 do -- there are fewer triangles in this orientation
        for j=1,N-i do
            coroutine.yield(tabCopy(tri)) -- First quadrant
            coroutine.yield(mirrorY(tri)) -- Second
            coroutine.yield(mirrorXY(tri))-- Third
            coroutine.yield(mirrorX(tri)) -- Fourth
            moveR(tri)
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
local function triangles(n)
    local N = math.floor(n)
    if N ~= n then
        error("N must be an integer",2)
    end

    local co = coroutine.create(function () triGen(N) end)
    return function ()
        local code, res = assert(coroutine.resume(co))
        return res
    end
end
--[[
returns the list of frequencies that can then be used to create the
"tents" that will finally be used to create a spectrum histogram
frequencies will be in the form of a 2-d array indexed so that
freq[i][j] will give you a table in the form:
{freq = 32,inten = 3}
freq.N will store the N value used in the calculation.
This function should be called once for each line in the single
crystal spectrum.
--]]

function AG.frequencies(N, freqFunc, intenFunc)
    local freq = {}
    freq["N"] = N

    -- 'i' and 'j' are the indecies of the points on each face
    for i,j in intersections(N) do
        table[i][j] = {
            freq = freqFunc(cosTheta(i,j,N), cos2Phi(i,j,N)),
            inten = intenFunc(cosTheta(i,j,N), cos2Phi(i,j,N))
        }
    end
end

--[[
takes the return value of AG.frequencies and returns the "tents"
in the form:
{{high = 32, mid = 31.5, low = 31.3, weight = 2.1},...}
--]]
function AG.tents(freqs)
    local ret = {}
    for tri in triangles(freqs.N) do
        local freql,freqm,freqr,intenl,intenm,intenr
        freql = freqs[tri.l.i][tri.l.j].freq
        freqm = freqs[tri.m.i][tri.m.j].freq
        freqr = freqs[tri.r.i][tri.r.j].freq
        intenl = freqs[tri.l.i][tri.l.j].inten
        intenm = freqs[tri.m.i][tri.m.j].inten
        intenr = freqs[tri.r.i][tri.r.j].inten
        table.insert(ret,{
            high=math.max(freql,freqm,freqr),
            low=math.min(freql,freqm,freqr),
            -- find mid my sorting the three, then choosing the
            -- middle one
            mid = table.sort({freql,freqm,freqr})[2],
            weight = intenl/math.pow(R(tri.l.i,tri.l.j),3) +
                     intenm/math.pow(R(tri.m.i,tri.m.j),3) +
                     intenr/math.pow(R(tri.r.i,tri.r.j),3)
        })
    end

    return ret
end

--[[
Returns a spectrum with nbins, with frequencies starting at start and
a binsize of binsize
--]]
function AG.histogram(tents, nbins, start, binsize)
    local ret = Spectrum(nbins,start,binsize)

    for _, tent in ipairs(tents) do
        local maxBin, fmax = ret.findBin(tent.high)
        local midBin, fmid = ret.findBin(tent.mid)
        local minBin, fmin = ret.findBin(tent.low)
        local weight = tent.weight

        for i=minBin, maxBin do
            local flow = ret[i]
            local fhigh = ret[i] + ret.getBinsize()
            -- A
            if flow <= fmin and fmax < fhigh then
                ret.insert(weight,i)
            -- B
            elseif fhigh <= fmin then
                error("fhigh is less than (or equal to) fmin")
            -- C
            elseif flow <= fmin and fmin < fhigh and fhigh <= fmid then
                ret.insert(
                    (((fhigh-fmin)^2)/
                    ((fmax-fmin)*(fmid-fmin)))*weight,
                    i)
            -- D
            elseif fmin < flow and fhigh <= fmid then
                ret.insert(
                    (((fhigh-flow)*(fhigh+flow-2*fmin))/
                    ((fmax-fmin)*(fmid-fmin)))*weight,
                    i)
            -- E
            elseif flow <= fmin and fmid < fhigh and fhigh <= fmax then
                ret.insert(
                    ((fmid-fmin)/(fmax-fmin)) +
                    ((fhigh-fmid)*(2*fmax-fhigh-fmid)/
                    ((fmax-fmin)*(fmax-fmid)))*weight,
                    i)
            -- F
            elseif fmin < flow and flow <= fmid and fmid < fhigh and fhigh < fmax then
                ret.insert(
                    ((((fmid-flow)*(fmid+flow-2*fmin))/
                    ((fmax-fmin)*(fmid-fmin))) +
                    (((fhigh-fmid)*(2*fmax-fhigh-fmid))/
                    ((fmax-fmin)*(fmax-fmid))))*weight,
                    i)
            -- G
            elseif fmin < flow and flow <= fmid and fmax < fhigh then
                ret.insert(
                    ((((fmid-flow)*(fmid+flow-2*fmin))/
                    ((fmax-fmin)*(fmid-fmin)))+
                    ((fmax-fmid)/(fmax-fmin)))*weight,
                    i)
            -- H
            elseif fmid < flow and fhigh <= fmax then
                ret.insert(
                    (((fhigh-flow)*(2*fmax-fhigh-flow))/
                    ((fmax-fmin)*(fmax-fmid)))*weight,
                    i)
            -- I
            elseif fmid < flow and flow <= fmax and fmax < fhigh then
                ret.insert(
                    (((fmax-flow)^2)/
                    ((fmax-fmin)*(fmax-fmid)))*weight,
                    i)
            -- J
            elseif fmax < flow then
                error("fmax is less than flow")
            end
        end
    end
end

function AG.getSpectrum(N, freqFunc, intenFunc, nbins, start, binsize)
    return AG.histogram(AG.tents(AG.frequencies(N, freqFunc, intenFunc)), nbins, start, binsize)
end

return AG
