local functional = {}

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

function functional.map(f,...)
    vals = table.pack(...)
    ret = {}
    for i,v in ipairs(vals) do
        table.insert(ret,f(v))
    end

    return table.unpack(ret)
end

return functional
