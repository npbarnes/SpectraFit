local function newSpec(nbins, first, binsize)
    local ret = {}
    for i=1,nbins do
        table.insert(ret,{freq = first+(i-1)*binsize, inten = 0})
    end
    return ret
end

local meta = {
    __index = function (o, i)
        if type(i) ~= "number" then
            return nil
        else
            return o.getBin(i)
        end
    end
}

local function Spectrum(nbins,start,binsize)
    local obj = {}
    setmetatable(obj,meta)

    -- Private Fields
    local n = nbins
    local min = start
    local step = binsize
    local max = start + nbins*binsize
    local spec = newSpec(nbins, start, binsize)

    -- Public Methods
    function obj.getInten(freq)
        if freq < min or freq >= max then
            error("Frequency out of range: "..min.."-"..max)
        end

        for i=1,n do
            local currFreq = spec[i].freq
            local nextFreq = currFreq + step
            if currFreq <= freq and freq < nextFreq then
                return spec[i].inten
            end
        end
    end

    function obj.getBin(i)
        if i ~= math.floor(i) then
            error("bin index must be an integer")
        end
        return spec[i]
    end

    return obj
end

return Spectrum
