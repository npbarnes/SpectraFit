local Exp = {}

local Spectrum = require "spectrum"

-- Due to round-off errors the frequencies in the datafiles do not
-- have a consistant binsize. I'm attempting to correct this by
-- inserting values by their position, rather than frequency, and
-- calculating the appropriate frequencies.
function Exp.loadData(file)
    local oldfile = io.input()
    io.input(file)
    local datastring = io.read("*all")
    io.input(oldfile)

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

    return spec
end
