local SG = {}

local h = require "helpers"
local AG = require "aldermanGrant"
local Exp = require "experiment"
local Spectrum = require "spectrum"
local settings = require "settings"

--[[
    The arguments to this function are all string literals
that are passed on to _paramGen() and put into apropriate
places in the param table (i.e. State.runParam).
distributions are optional default value is '0' for each
--]]
function SG.paramGen (Qccfmt, Etafmt, sQccfmt,sEtafmt)
    -- Set distributions to a default value of 0
    sQccfmt = sQccfmt or '0'
    sEtafmt = sEtafmt or '0'
    -- Check preconditions
    if type(param) ~= "table" then
        error("Must have a parameter table. Got type: "..type(param),2)
    end
    if not Qccfmt then
        error("Qccfmt is required",2)
    end
    if not Etafmt then
        error("Etafmt is required",2)
    end

    param = {}
    -- Generate tables of parameters to be simulated
    param.Qcc  = _paramGen(Qccfmt)
    param.sQcc = _paramGen(sQccfmt)
    param.Eta  = _paramGen(Etafmt)
    param.sEta = _paramGen(sEtafmt)

    param.current = {
        Qcc = param.Qcc[1],
        Eta = param.Eta[1],
        sQcc = param.sQcc[1],
        sEta = param.sEta[1],

        n = 1
    }

    return param
end

--[[
    fmt is a string that describes the elements of the table (array)
    that is returned. it can be numbers separated by commas or instead
    of a number you may include a range of numbers in square brackets
    with the notation: [start,stop,step=1]
    example: _paramGen"1,[4,6],3,[9,14,2]" --> {1,4,5,6,3,9,11,13}
    Note: order of the elements in the returned table is not defined.

    TODO:
        Define the order,
        Make the code more readable,
        Give a more useful error message for a malformed format
        (i.e. make it look like a parser)
--]]
local function _paramGen (fmt)
    if type(fmt) ~= "string" then
        error("Format must be a string. Got type: "..type(fmt),2)
    end

    local origFmt = fmt

    local ret = {}

    -- First enter ranges with explicit step
    -- in the form '[start,stop,step]'
    for start,stop,step in string.gmatch(fmt, "%[%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*,%s*([-]?%d*%.?%d*)%s*%]") do
        for i = tonumber(start),tonumber(stop),tonumber(step) do
            table.insert(ret,i)
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
            table.insert(ret,i)
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
        -- pattern matches empty string, filter this out.
        if i ~= "" then
            table.insert(ret,tonumber(i))
        end
    end

    -- remove those values
    fmt = string.gsub(fmt,"[-]?%d*%.?%d*","")

    -- remove extra commas
    fmt = string.gsub(fmt,",%s*,",",")
    while string.sub(fmt,-1,-1) == ',' do
        fmt = string.sub(fmt,1,-2)
    end

    -- final fmt should be empty
    if fmt ~= "" then
        error("Malformed format: "..origFmt.."\n\tWith residue: "..fmt,2)
    end

    return ret
end

SG.calculate = {}
--[[
Returns a spectrum representing the result of the simulation using
parameters ... (numbers).
--]]
function SG.calculate.single(spectrumSettings,...)
    local numParam = select('#',...)

    -- Type checking
    for i,v in pairs(table.pack(...)) do
        if type(v) ~= "number" then
            error("Parameter "..i.." is not a number",2)
        end
    end

    local ret = Spectrum(spectrumSettings)
    local aldermanSettings = {
        N = settings.AldermanGrantN,
        freqFunc = error,
        intenFunc = error,
    }

    for ffunc,ifunc in Exp.specLines(...) do
        aldermanSettings.freqFunc = ffunc
        aldermanSettings.intenFunc = ifunc
        ret.add(AG.getSpectrum(aldermanSettings, spectrumSettings))
    end

    return ret
end

local function gauss(mean,std,x)
    return (1/(std*math.sqrt(2*math.pi)))*math.exp(-(x-mean)^2/(2*std^2))
end

local function isValid(constraint,v)
    local valid
    if constraint.ge then
        valid = (v >= constraint.ge) and valid
    end
    if constraint.le then
        valid = (v <= constraint.le) and valid
    end
    if constraint.gt then
        valid = (v > constraint.gt) and valid
    end
    if constraint.lt then
        valid = (v < constraint.lt) and valid
    end

    return valid
end

-- constraints is a table of tables that specify the constraints on
-- the parameters
-- example:
-- {{ge=0},{ge=0,le=1}}
-- This makes the first param greater than or equal to 0, and the
-- second between 0 and 1
-- use ge, le, gt, or lt
local function genSets(constraints,...)
    local paramSets = {}
    local numParam = select('#',...)
    for i=1,numParam/2 do
        local tmp = {}
        local mean = select(i,...)
        local numstd = settings.sampleRange
        local std = select(numParam/2+i,...)
        local numSamples = settings.numSamples

        for v=mean-numstd*std, mean+numstd*std, 2*numstd*std/numSamples do
            if isValid(constraints[i],v) then
                table.insert(tmp,{value=v, weight=gauss(mean,std,v)})
            end
        end

        table.insert(paramSets,tmp)
    end
    return paramSets
end

-- takes a table as an argument, but returns multiple values
local function find(key,tab)
    local ret = {}
    for i,v in ipairs(tab) do
        table.insert(ret,v[key])
    end
    return table.unpack(ret)
end

local function product(...)
    if ... then
        return select(1,...)*product(select(2,...))
    else
        return 1
    end
end

--[[
Returns a spectrum representing the result of the simulation using
parameters ... (numbers).

It expects an even number of those parameters first the central values
then the distributions in the same order.
--]]
function SG.calculate.distributed(spectrumSettings,constraints,...)
    -- Parameter checking
    local numParam = select('#',...)
    if numParam%2 ~= 0 then
        error("There must be an even number of parameters (central values followed by distributions.")
    end

    -- Type checking
    for i,v in pairs(table.pack(...)) do
        if type(v) ~= "number" then
            error("Parameter "..i.." is not a number")
        end
    end

    local paramSets = genSets(constraints,...)
    local ret = Spectrum(spectrumSettings)

    for params in h.combinations(paramSets) do
        local totWeight = product(find("weight",params))
        local curSpec = SG.calculate.single(spectrumSettings,find("value",params))
        curSpec.scale(totWeight)
        ret.add(curSpec)
    end

    return ret
end

--[[
returns a table of spectra from all combinations of the given
parameter lists.
--]]
function SG.calculate.all(aldermanSettings, spectrumSettings,...)
    error("calculate all is not implemented")
    local lists = table.pack(...)
    local ret = {}
    --type checking
    for i,v in pairs(lists) do
        if type(v) ~= "table" then
            error("Parameter "..i.." is not a table")
        elseif not h.arrayType(v, "number") then
            error("Parameter "..i.." is not a table of numbers")
        end
    end

    for items in h.combinations(table.pack(...)) do
        table.insert(ret,SG.calculate(aldermanSettings,spectrumSettings,table.unpack(items)))
    end
end

return SG
