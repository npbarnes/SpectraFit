local SG = {}

local h = require "helpers"
local AG = require "aldermanGrant"
local Exp = require "experiment"
local Spectrum = require "spectrum"

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
    -- Parameter checking
    if numParam%2 ~= 0 then
        error("There must be an even number of parameters (central values followed by distributions.")
    end

    -- Type checking
    for i,v in pairs(table.pack(...)) do
        if type(v) ~= "number" then
            error("Parameter "..i.." is not a number")
        end
    end

    local ret = Spectrum(spectrumSettings)
    local aldermanSettings = {
        N = settings.AldermanGrantN,
        freqFunc = error,
        intenFunc = error,
    }

    -- TODO: make this work for more than two parameters
    -- TODO: Include distributed parameters
    for ffunc,ifunc in Exp.specLines(select(1,...),select(2,...)) do
        aldermanSettings.freqFunc = ffunc
        aldermanSettings.intenFunc = ifunc
        ret.add(AG.getSpectrum(aldermanSettings, spectrumSettings))
    end

    return ret
end

--[[
Returns a spectrum representing the result of the simulation using
parameters ... (numbers).

It expects an even number of those parameters first the central values
then the distributions in the same order.
--]]
function SG.calculate.distributed(spectrumSettings,...)
    error("Distributed simulation is not yet implemented.")
end

--[[
returns a table of spectra from all combinations of the given
parameter lists.
--]]
function SG.calculateAll(aldermanSettings, spectrumSettings,...)
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

    -- I had to unroll a for loop into a while to handle an arbitrary
    -- number of parameters
    iterator = h.combinations(...)
    items = table.pack(iterator())
    while items do
        table.insert(ret,SG.calculate(aldermanSettings,spectrumSettings,table.unpack(items)))
        items = table.pack(iterator())
    end
end

return SG
