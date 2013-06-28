settings = {
    sampleRange = 2,-- define the range to take samples from
                    -- (i.g. 2 standard deviations from the mean)
    numSamples = 9, -- How many samples to take from that range for
                    -- each parameter

    snapshotInterval = 1000,  -- after this many spectra are
                                -- calculated the program will
                                -- take a snapshot

    AldermanGrantN = 32, -- N value from Alderman-Grant algorithm
}

return settings
