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
    snapshotInterval = 1000  -- after this many spectra are
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

    -- Generate tables of parameters to be simulated
    param.Qcc  = _paramGen(Qccfmt)
    param.sQcc = _paramGen(sQccfmt)
    param.Eta  = _paramGen(Etafmt)
    param.sEta = _paramGen(sEtafmt)
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
function _paramGen (fmt)
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

