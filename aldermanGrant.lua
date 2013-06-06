--[[
information on these algorithms can be found in the following paper

1986 D.W. Alderman et al, "Methods for Analyzing Spectroscopic Line
Shapes.  NMR Solid Powder Patterns" J. Chem. Phys., Vol. 84, No. 7
--]]

require "helpers.lua"

-- A table to hold Alderman-Grant algorithms
AG = {}

local N = State.simParam.AldermanGrantN
local bins = State.ioSettings.bins
local freqFunc = freqFunc or function (cosTheta,cos2Phi,...)
    error("no freqFunc defined")
end
local Qcc = State.runParam.current.Qcc
local Eta = State.runParam.current.Eta
local larmor = State.physParam.larmor
local bins = Sate.ioSettings.bins
local I = State.physParam.spin

-- returns the list of frequencies that can then be used to create the
-- "tents" that will finally be used to create a spectrum histogram
-- frequencies will be in the form of a 2-d array indexed so that
-- freq[i][j] will give you the frequency calculated at the point
-- (i,j) on the octohedron described in the paper. freq.N will store
-- the N value used in the calculation.
-- This function should be called once for each line in the single
-- crystal spectrum.
function AG.frequencies(...)
    local freq = {}
    freq["N"] = N

    -- 'i' and 'j' are the indecies of the points on each face
    for i,j in intersections(N) do
        table[i][j] = freqFunc((N-i-j)/math.sqrt(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2)), ...)
    end
end
