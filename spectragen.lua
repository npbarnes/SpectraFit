require"main.lua"

--[[
    The arguments to this function are all string literals
that are passed on to _paramGen() and put into apropriate
places in the param table (i.e. State.runParam).
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

    --TODO: finish this function
end

--[[
returns a table of spectra from all combinations of the items in the
lists of numbers Qcc,Eta,sQcc,and sEta. sQcc, and sEta default to {0}
--]]
function calculateAll(Qcc,Eta,sQcc,sEta)
    -- default values
    sQcc = sQcc or {0}
    sEta = sEta or {0}

    --type checking
    if type(Qcc) ~= "table" then
        error("Qcc must be a table",2)
    end
    if type(Eta) ~= "table" then
        error("Eta must be a table",2)
    end
    if type(sQcc) ~= "table" then
        error("sQcc must be a table",2)
    end
    if type(sEta) ~= "table" then
        error("sEta must be a table",2)
    end

    for i,v in ipairs(Qcc) do
        if type(v) ~= "number" then
            error("All values in Qcc (treated as an array) must be numbers",2)
        end
    end
    for i,v in ipairs(Eta) do
        if type(v) ~= "number" then
            error("All values in Eta (treated as an array) must be numbers",2)
        end
    end
    for i,v in ipairs(sQcc) do
        if type(v) ~= "number" then
            error("All values in sQcc (treated as an array) must be numbers",2)
        end
    end
    for i,v in ipairs(sEta) do
        if type(v) ~= "number" then
            error("All values in sEta (treated as an array) must be numbers",2)
        end
    end


    for Q,E,sQ,sE in combinations(Qcc,Eta,sQcc,sEta) do
        save(Q.."_"..E.."_"..sQ.."_"..sE..".txt",calculate(Q,E,sQ,sE),State.ioSettings.filename)
    end
end
