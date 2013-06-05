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

-- returns the list of "tents" as described in the paper below that
-- can then be converted into a spectrum histogram
-- 1986 D.W. Alderman et al, "Methods for Analyzing Spectroscopic Line
-- Shapes.  NMR Solid Powder Patterns" J. Chem. Phys., Vol. 84, No. 7
function aldermanGrant()
    -- Initialize the spectrum to be returned
    -- keys are frequencies (left side of bin inclusive), values are
    -- intensities in an arbitrary scale
    local tents = {}

    -- for each transition (i.e. each spectral line)
    -- m represents the transition from the magnetic quantum number m
    -- to m-1
    for m = -(I-1),I do
    end

end
