require "Set"

Parameters = {
    -- Spectrum parameters to be run
    -- every combination of values in these Sets will be simulated
    -- populate manually, or using the paramGen() function
    Qcc = {},    -- Quadrupole coupling in Mhz
    sQcc = {},   -- Standard deviation of Qcc
    Eta = {},    -- Asymetry parameter
    sEta = {},   -- Standard deviation of Eta

    -- Physical parameters
    larmor = 32.329, -- Mhz
    spin = 3,

    -- Simulation parameters
    bins = 1024, -- Number of bins in the simulated spectrum
    QccSamples = 9, -- Samples from Qcc distribution
    EtaSamples = 9, -- Samples from Eta distribution
    AldermanGrantN = 32, -- N value from Alderman-Grant algorithm
    snapshotInterval = 1000000  -- after this many spectra are
                                -- calculated the program will
                                -- take a snapshot
}

--[[
    The arguments to this function are all string literals
that are passed on to _paramGen() and put into apropriate
places in the param table
distributions are optional default value is '0' for each
--]]
function paramGen (param, Qccfmt, Etafmt, sQccfmt,sEtafmt)
    sQccfmt = sQccfmt or '0'
    sEtafmt = sEtafmt or '0'
    param.Qcc  = _paramGen(Qccfmt)
    param.sQcc = _paramGen(sQccfmt)
    param.Eta  = _paramGen(Etafmt)
    param.sEta = _paramGen(sEtafmt)
end

--[[
    fmt is a string that lists each element (all numbers) of a set
that is returned as well as ranges denoted by square brackets with the
notation of [start, end, step = 1]
example: "1,[4,6],3,[9,14,2]" --> Set.create{1,4,5,6,3,9,11,13}
--]]
function _paramGen (fmt)
    if type(fmt) ~= "string" then
        error("Format must be a string",2)
    end

    local set = {}

    -- First enter ranges with explicit step
    -- in the form '[start,stop,step]'
    for start,stop,step in string.gmatch(fmt, "%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]") do
        for i = tonumber(start),tonumber(stop),tonumber(step) do
            Set.add(set,i)
        end
    end

    -- remove those ranges
    fmt = string.gsub(fmt,"%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]","")

    -- remove extra commas
    fmt = string.gsub(fmt,",%s*,",",")
    while string.sub(fmt,-1,-1) == ',' do
        fmt = string.sub(fmt,1,-2)
    end

    -- now ranges with implicit step of 1
    -- form: '[start,stop]'
    for start,stop in string.gmatch(fmt, "%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]") do
        local step = 1
        for i = tonumber(start),tonumber(stop),tonumber(step) do
            Set.add(set,i)
        end
    end

    -- remove those ranges
    fmt = string.gsub(fmt,"%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]","")

    -- remove extra commas
    fmt = string.gsub(fmt,",%s*,",",")
    while string.sub(fmt,-1,-1) == ',' do
        fmt = string.sub(fmt,1,-2)
    end

    -- add singular values to the array
    -- form is single numbers
    for i in string.gmatch(fmt, "[-]?%d*%.?%d*") do
        if i ~= "" then
            Set.add(set,tonumber(i))
        end
    end

    -- remove those values
    fmt = string.gsub(fmt,"%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]","")

    -- remove extra commas
    fmt = string.gsub(fmt,",%s*,",",")
    while string.sub(fmt,-1,-1) == ',' do
        fmt = string.sub(fmt,1,-2)
    end

    -- final fmt should be empty
    if fmt ~= "" then
        error("Malformed format: "..fmt,2)
    end

    return set
end

--[[
    Returns a spectrum representing the result of the simulation using
parameters Qcc, Eta, sQcc, and sEta (numbers).  sQcc and sEta
defualt to zero.
--]]
function calculate(Qcc,Eta,sQcc,sEta)
    -- set default values
    sQcc = sQcc or 0
    sEta = sEta or 0

    -- type checking
    if type(Qcc) ~= "number" then
        error("Qcc must be a number",2)
    end
    if type(Eta) ~= "number" then
        error("Eta must be a number",2)
    end
    if type(sQcc) ~= "number" then
        error("sQcc must be a number",2)
    end
    if type(sEta) ~= "number" then
        error("sEta must be a number",2)
    end
end

