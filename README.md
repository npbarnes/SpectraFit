SpectraFit
==========

A program for fitting NMR powder patterns.

This version of SpectaFit is a complete rewrite of the program used for the paper
*SpectraFit: a new program for simulating and fitting distributed 10B NMR powder patterns - application to symmetric trigonal borons* in 2012 Physics and Chemistry of Glasses European Journal
of Glass Science and Technology part B Vol. 53 (3).
It is intended to improve code quality, stability, and extensibility.

At this time I only intend to support static solid state boron-10 NMR
of amorphous or polycrystalline samples, but it shouldn't be too hard
to extend to other systems.

Send an email or pull request if you would like to support or contribute to some other feature.

For best results run using LuaJIT 2.0+ compiled with Lua 5.2 compatability options.

For plotting, SpectraFit uses the Flot javascript library and Lua-Flot by Steve Donovan

http://www.flotcharts.org/
http://stevedonovan.github.io/lua-flot/flot-lua.html
https://github.com/stevedonovan/stevedonovan.github.com/blob/master/lua-flot/flot.lua
