-- Helper functions
local function newSpec(nbins, first, binsize)
    local ret = {}
    for i=1,nbins do
        table.insert(ret,{freq = first+(i-1)*binsize, inten = 0})
    end
    return ret
end

-- Metatable for spectrum objects
local meta = {
    __index = function (o, i)
        return o.getBin(i)
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

    -- Private Methods
    -- return an iterator to go through the bins
    local function bins()
        local i = 0
        return function()
            i = i+1
            if i>#spec then
                return nil
            else
                return i, spec[i].freq, spec[i].inten
            end
        end
    end

    -- Public Methods
    function obj.getBin(i)
        if type(i) ~= "number" then
            error("bin index must be an integer. Got: "..type(i))
        elseif i ~= math.floor(i) then
            error("bin index must be an integer. Got: "..i)
        elseif i<1 or i>#spec then
            error("bin index out of range: 1 - " .. #spec)
        end
        return spec[i]
    end

    function obj.findBin(freq)
        if type(freq) ~= "number" then
            error("number expected. Got: ".. type(freq))
        elseif freq < min or freq >= max then
            error("Frequency out of range: "..min.."-"..max)
        end

        for i=1,n do
            local currFreq = spec[i].freq
            local nextFreq = currFreq + step
            if currFreq <= freq and freq < nextFreq then
                return i, spec[i]
            end
        end
    end

    function obj.getInten(freq)
        return select(2,obj.findBin(freq)).inten
    end

    function obj.getN()
        return n
    end

    function obj.getMin()
        return min
    end

    function obj.getMax()
        return max
    end

    function obj.getBinsize()
        return step
    end

    -- add or subtract intensity from one bin
    -- isfreq is a boolean for choosing if pos should be interpreted
    -- as a bin number or a frequency
    function obj.insert(value, pos, isfreq)
        if not isfreq then
            pos = obj.findBin(pos)
        end
        spec[pos] = spec[pos] + value
    end

    -- add other to obj bin by bin
    -- they must have identical frequencies
    function obj.add(other)
        for pos,freq,inten in bins() do
            obj.insert(other[pos].inten,pos)
        end
    end

    -- Return a copy of obj
    function obj.copy()
        local ret = Spectrum(n,min,step)
        ret.add(obj)
        return ret
    end

    return obj
end

return Spectrum
