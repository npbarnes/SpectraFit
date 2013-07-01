--[[
spectrumSettings is a table in the form:
{nbins = ##, start = ##, binsize = ##}
--]]
local s = require "serialize"
local h = require "helpers"

-- Helper functions
local function newSpec(spectrumSettings)
    local nbins = spectrumSettings.nbins
    local start = spectrumSettings.start
    local binsize = spectrumSettings.binsize

    local ret = {}
    for i=1,nbins do
        table.insert(ret,{freq = start+(i-1)*binsize, inten = 0})
    end
    return ret
end

-- Metatable for spectrum objects
local meta = {
    __index = function (o, i)
        return o.getBin(i)
    end
}

local function Spectrum(spectrumSettings)
    local obj = {}
    setmetatable(obj,meta)

    -- Private Fields
    -- Default values are provided, but if the constructor is called
    -- without arguments it's expected that you run obj.load() or
    -- obj.tableLoad()
    -- TODO: send defaults to newSpec if needed
    local n = spectrumSettings.nbins or 1
    local min = spectrumSettings.start or 1
    local step = spectrumSettings.binsize or 1
    local max = min + n*step
    local spec = newSpec(spectrumSettings)

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
    --getbin takes an index
    function obj.getBin(i)
        if type(i) ~= "number" then
            error("bin index must be an integer. Got: "..type(i))
        elseif i ~= math.floor(i) then
            error("bin index must be an integer. Got: "..i)
        elseif i<1 or i>#spec then
            error("bin index out of range: 1 - " .. #spec)
        end
        return spec[i].freq, spec[i].inten
    end

    --findbin takes a frequency
    function obj.findBin(freq)
        if type(freq) ~= "number" then
            error("number expected. Got: "..type(freq))
        elseif freq < min or freq >= max then
            error("Frequency "..freq.." out of range: ["..min..","..max..")")
        end

        local i = math.floor((freq-start)/step)+1
        return i, spec[i].freq, spec[i].inten
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
        spec[pos].inten = spec[pos].inten + value
    end

    -- add other to obj bin by bin
    -- they must have identical frequencies
    function obj.add(other)
        for pos,freq,inten in bins() do
            if freq ~= other[pos] then
                error("frequencies do not match")
            end
            obj.insert(select(2,other[pos]),pos)
        end
    end

    -- Return a copy of obj
    function obj.copy()
        local ret = Spectrum(n,min,step)
        ret.add(obj)
        return ret
    end

    -- load spectrum from a file saved using obj.save()
    function obj.load(file)
        file = file or io.input()
        if type(file) == "string" then
            file = assert(io.open(file,'r'))
        elseif io.type(file) ~= "file" then
            error("Argument must be an open file handle or filename")
        end

        local datastring = file:read("*a")

        obj.tableLoad(load(datastring)())

        -- Return self
        return obj
    end

    function obj.tableLoad(tab)
        spec = tab.spec
        n = tab.n
        min = tab.min
        max = tab.max
        step = tab.step
    end

    function obj.save(file)
        local tab = {}
        tab.spec = h.tabCopy(spec)
        tab.n = n
        tab.min = min
        tab.max = max
        tab.step = step

        file = file or io.output()
        if type(file) == "string" then
            file = assert(io.open(file,"w"))
        elseif io.type(file) ~= "file" then
            error("Argument must be an open file handle or filename")
        end

        file:write("return ")
        s.serialize(tab,file)

        file:close()

    end

    return obj
end

return Spectrum
