#!/bin/csh

cd /discover/nobackup/ylim/Diagnostics/Teleconnection/Scripts/M2

ifort -o eigenx eigenx-M2.f

cat >! eof.com <<ENDc
H2-DJFano19802017.d
DIR
104256 1              ; dimension of sampling stations
117                   ; number of sampling points at each station
2                     ; read   1=time index first  2=space index first
0                     ; moving average lag (0: No smoothing)
0                     ; cycle period for removing mean (0: No)
1                     ; area adjustment (0: No,  1: Yes)
0.0 0.5               ; starting latitude and increment for area adjustment
90                    ; percent variance
1                     ; EOF scaling factor
12                    ; number of EOFs to be printed
1                     ; PC normalization  (0: NO,  1: Yes)
EV-H2-DJF19802017.d
DIR
PC-H2-DJF19802017.d
DIR
ENDc
./eigenx < eof.com
mv inform.d inf-H2-DJF19802017.d
