--[[
This is the main driver for the Powder-Fit Lua project. Main is
intended to handle initialization, settings, and frontend UI.

Program Organization:

-Main
    -Experiment
        -Data
        -Theory

    -Fitting
        -Optimize
            -Compass
            -Grid
            -Simplex

    -SpectraGen
        -AldermanGrant

--]]

do
    local wd = assert(os.getenv("PWD")) .. "/"

    package.path = package.path .. ";"..wd.."experiment/?.lua"
    package.path = package.path .. ";"..wd.."fitting/?.lua"
    package.path = package.path .. ";"..wd.."fitting/optimize/?.lua"
    package.path = package.path .. ";"..wd.."generation/?.lua"
    package.path = package.path .. ";"..wd.."utility/?.lua"
end

local SF = require "spectrafit"
local Exp = require "experiment"
