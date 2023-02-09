#!/bin/bash

# start up julia apps in subshells as a single command with presentation start
# this will kill all of the processes with ctrl-c
julia julia_dash_apps/gp_1d.jl 8001 false & \
julia julia_dash_apps/gp_1d.jl 8002 true & \
npm start