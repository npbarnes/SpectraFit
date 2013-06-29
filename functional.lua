local f = {}

local function close1(f,v)
    assert(type(f) == "function", "f must be a function")

    return function (...)
        return f(v,...)
    end
end

function functional.close(f,v,...)
    assert(type(f) == "function", "f must be a function")

    if v then
        return functional.close(close1(f,v),...)
    else
        return f
    end
end

return functional
