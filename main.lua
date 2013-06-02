--[[
This is the main driver for the SpectraFit Lua project all other files
that need access to the State table must require"main.lua" in order to
get bring State into scope.  main is intended to handle
initialization, settings, and frontend UI.
--]]
State = {
    action = "Init" -- Holds a string that describes what is being
                    -- done right now
                    -- in the event of a crash this can be used to
                    -- find where to restart
}

State.runParam = {
    -- Spectrum parameters to be run
    -- every combination of values in these lists will be simulated
    -- populate manually, or using the paramGen() function
    Qcc = {},    -- Quadrupole coupling in Mhz
    sQcc = {},   -- Standard deviation of Qcc
    Eta = {},    -- Asymetry parameter
    sEta = {},   -- Standard deviation of Eta
    current = {  -- This table holds the glass parameters currently
        Qcc = 0, -- being calculated
        sQcc = 0,
        Eta = 0,
        sEta = 0,

        n = 0,   -- This is the n'th spectrum calculated on this run
    }
}

State.physParam = {
    -- Physical parameters of the glass
    larmor = 32.239, -- MHz
    spin = 3,
}

State.simParam = {
    -- Simulation parameters
    sampleRange = 2,-- define the range to take samples from
                    -- (i.g. 2 standard deviations from the mean)
    QccSamples = 9, -- Samples from Qcc distribution
    EtaSamples = 9, -- Samples from Eta distribution
    AldermanGrantN = 32, -- N value from Alderman-Grant algorithm
    -- Function that maps orientation and physical parameters to a
    -- frequency
    FreqFunc = function (theta, phi, ...)
        error("No frequency function assigned.")
    end
}

State.ioSettings = {
    bins = 1024, -- Number of bins in the simulated spectrum
    snapshotInterval = 1000  -- after this many spectra are
                                -- calculated the program will
                                -- take a snapshot
}
