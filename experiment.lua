local Spectrum = require "spectrum"

local Exp = {
    larmor = 32.239, -- MHz
    spin = 3,
}

local mt = {
    __index = function(t,s)
        if s == "bins" then
            error("Number of bins not set, it must match the number of Experimental data points.")
        end
    end
}

setmetatable(Exp,mt)

-- Due to round-off errors the frequencies in the datafiles do not
-- have a consistant binsize. I'm attempting to correct this by
-- inserting values by their position, rather than frequency, and
-- calculating the appropriate frequencies.
-- This function also sets Exp.bins that should be used when fitting
function Exp.loadData(file)
    -- If it's a string, then open the file with that name
    -- otherwise it should be an open file handle
    if type(file) == "string" then
        file = assert(io.open(file))
    elseif io.type(file) ~= "file" then
        error("Argument must be an open file handle or filename")
    end

    local datastring = file:read("*a")

    local minFreq = math.huge
    local maxFreq = -math.huge
    local bincount = 0
    local bins = {}
    for freq, inten in datastring:gmatch("(%S+)%s+(%S+)\n") do
        freq = tonumber(freq)
        inten = tonumber(inten)
        if freq < minFreq then
            minFreq = freq
        end
        if freq > maxFreq then
            maxFreq = freq
        end
        bincount = bincount + 1
    end

    spec = Spectrum(bincount,minFreq,(maxFreq-minFreq)/bincount)
    local i = 1
    for freq, inten in datastring:gmatch("(%S+)%s+(%S+)\n") do
        spec.insert(inten,i)
        i = i+1
    end

    -- The number of bins in the simulated spectrum should match the
    -- experiment. So export as bins.
    Exp.bins = bincount

    return spec
end

return Exp
