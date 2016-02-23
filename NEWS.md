# streamMetabolizer 0.8.0

## Changes

* Major interface change (renamed variable) to clarify types of time: solar.time
(mean solar time), app.solar.time (apparent solar time), local.time (time in 
local time zone). Metabolism models now accept solar.time rather than 
local.time, though it's still possible to pass in local time but just call it
solar.time (as long as you don't have daylight savings time).

# streamMetabolizer 0.7.3

## Changes

* Remove calc\_schmidt because it is never used

# streamMetabolizer 0.7.2

## Status

This package is not ready for use by many, but it does currently have:

* support for a wide range of non-hierarchical models, both Bayesian and 
MLE-based

* support for regressions of daily K versus discharge and/or velocity

* default specifications for every model

* a maturing user interface for fitting models (probably not quite fixed yet)

* convenience functions for calculating DO saturation concentrations, air 
pressure, depth, solar time, PAR, etc.

* functions for simulating data and error, for testing models with data having 
known underlying parameters

* two small datasets, courtesy of Bob Hall, for testing models with real data