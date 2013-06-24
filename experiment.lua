local Exp = {}

local Spectrum = require "spectrum"

function Exp.loadData(file)
    local oldfile = io.input()
    io.input(file)
    local datastring = io.read("*all")

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

    -- Due to round-off errors the frequencies in the datafiles do not
    -- have a consistant binsize. I'm attempting to correct this by
    -- inserting values by their position, rather than frequency
    spec = Spectrum(bincount,minFreq,(maxFreq-minFreq)/bincount)
    local i = 1
    for freq, inten in datastring:gmatch("(%S+)%s+(%S+)\n") do
        spec.insert(inten,i)
        i = i+1
    end

<<<<<<< HEAD
    return spec
=======
>>>>>>> c8a8552683f0174aacf4b86d30f57666e7c36df5
end
