local function newSpec(nbins, first, binsize)
    local ret = {}
    for i=1,nbins do
        table.insert(ret,{freq = first+(i-1)*binsize, inten = 0})
    end
    return ret
end
local function Spectrum(nbins,start,binsize)
    local obj = {}

    -- Private Fields
    local n = nbins
    local min = start
    local step = binsize
    local max = start + nbins*binsize
    local spec = newSpec(nbins, first, last)

    -- Public Methods
    -- TODO

    return obj
end

return Spectrum
