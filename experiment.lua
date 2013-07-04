local Spectrum = require "spectrum"
local f = require "functional"

local Exp = {
    larmor = 32.239, -- MHz
    spin = 3,
}

local mt = {
    __index = function(t,s)
        if s == "bins" then
            error("Number of bins not set, it must match the number of Experimental data points.")
        else
            error("Attempt to index field "..s.." (a nil value)")
        end
    end
}

setmetatable(Exp,mt)

-- Due to round-off errors the frequencies in the datafiles do not
-- have a consistant binsize. I'm attempting to correct this by
-- inserting values by their position, rather than frequency, and
-- calculating the appropriate frequencies.
-- This function also sets Exp.bins that should be used when fitting
function Exp.loadData(file)
    -- If it's a string, then open the file with that name
    -- otherwise it should be an open file handle
    if type(file) == "string" then
        file = assert(io.open(file))
    elseif io.type(file) ~= "file" then
        error("Argument must be an open file handle or filename")
    end

    local datastring = file:read("*a")

    local minFreq = math.huge
    local maxFreq = -math.huge
    local bincount = 0
    local bins = {}
    for freq, inten in datastring:gmatch("(%d*%.?%d*)%s+(%d*%.?%d*)\n") do
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


    spec = Spectrum{
        nbins = bincount,
        start = minFreq,
        binsize = (maxFreq-minFreq)/bincount
    }
    local i = 1
    for freq, inten in datastring:gmatch("(%S+)%s+(%S+)\n") do
        spec.insert(inten,i)
        i = i+1
    end

    -- The number of bins in the simulated spectrum should match the
    -- experiment. So export as bins.
    Exp.bins = bincount

    return spec
end

local function Vq(Qcc)
    return (3*Qcc)/(2*Exp.spin*(2*Exp.spin-1))
end

local function Beta(Qcc)
    return Vq(Qcc)/Exp.larmor
end

local function A_(m)
    return 0.5*((Exp.spin+1.5)*(Exp.spin-0.5) - 3*((m-0.5)^2))
end

local function B_(m)
    return 4*((Exp.spin+1.5)*(Exp.spin-0.5) - 6*((m-0.5)^2))
end

local function C_(m)
    return 12*Exp.spin*(Exp.spin+1)-40*m*(m-1)-27
end

local function D_(m)
    return 0.5*(3*Exp.spin*(Exp.spin+1)-5*m*(m-1)-6)
end

local function E_(m)
    return 8*Exp.spin*(Exp.spin+1)-20*m*(m-1)-15
end

local function A(m,u,l,n)
    return -(3*u^2-1+l*n-l*u*n)
end

local function C(m,u,l,n)
    return (A_(m)*((u^4)*((3-n*l)^2)+2*(u^2)*(-9+2*(n^2)-((n^2)*(l^2)))+((3+n*l)^2)) +
           (B_(m)*((u^4)*((3-n*l)^2)+(u^2)*(-9+(n^2)+(6*n*l)-(2*(n^2)*(l^2))))))
end

local function E(m,u,l,n)
    return (C_(m)*(
        u^6*(3-n*l)^3+
        u^4*(-36+3*n^2+42*n*l-n^3*l-19*n^2*l^2+3*n^3*l^3)+
        u^2*(9-4*n^2-15*n*l+2*n^3*l+11*n^2*l^2-3*n^3*l^3)+
        (n^2-n^3*l-n^2*l^2+n^3*l^3))+
        D_(m)*(
        u^6*(3-n*l)^3+
        u^4*(-63+12*n^2+33*n*l-4*n^3*l-13*n^2*l^2+3*n^3*l^3)+
        u^2*(45-4*n^2-9*n*l+4*n^3*l+n^2*l^2-3*n^3*l^3)+
        (-9+3*n*l+5*n^2*l^2+n^3*l^3))+
        E_(m)*(
        u^6*(3-n*l)^3+
        u^4*(-54+9*n^2+36*n*l-3*n^3*l-15*n^2*l^2+3*n^3*l^3)+
        u^2*(27-6*n^2-9*n*l+4*n^3*l+3*n^2*l^2-3*n^3*l^3)+
        (-3*n^2-n^3*l+3*n^2*l^2+n^3*l^3)))
end

local function freqFunc(m,Qcc,Eta,cosTheta,cos2Phi)
    return Exp.larmor +
        (Vq(Qcc)/2)*(m-0.5)*A(m,cosTheta,cos2Phi,Eta) +
        (Vq(Qcc)*Beta(Qcc)/72)*C(m,cosTheta,cos2Phi,Eta) +
        (Vq(Qcc)*(Beta(Qcc)^2)/144)*E(m,cosTheta,cos2Phi,Eta)*(m-0.5)
end

local function intenFunc(m)
    return Exp.spin*(Exp.spin+1) - (m-1)*m
end

function Exp.specLines(Qcc,Eta)
    if type(Qcc) ~= "number" then
        error("Qcc must be a number")
    elseif type(Eta) ~= "number" then
        error("Eta must be a number")
    end

    local co = coroutine.create(function ()
        -- m is the transition from m to m-1
        for m=-Exp.spin+1,Exp.spin do
           coroutine.yield(f.close(freqFunc,m,Qcc,Eta),f.close(intenFunc,m))
        end
    end)

    return function ()
        local code,ffunc,ifunc = assert(coroutine.resume(co))
        return ffunc,ifunc
    end
end

return Exp
