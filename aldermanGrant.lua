--[[
information on these algorithms can be found in the following paper

1986 D.W. Alderman et al, "Methods for Analyzing Spectroscopic Line
Shapes.  NMR Solid Powder Patterns" J. Chem. Phys., Vol. 84, No. 7
--]]

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
function AG.frequencies()
    local frequencies = {}

    -- for each transition (i.e. each spectral line)
    -- m represents the transition from the magnetic quantum number m
    -- to m-1
    for m = -(I-1),I do
        -- 'i' and 'j' are the indecies of the points on each face
        for i=-N, N do
            for j=-(N-math.abs(i)), N-math.abs(i) do
            end
        end
    end
end
