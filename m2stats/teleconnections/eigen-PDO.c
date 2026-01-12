#!/bin/csh

ifort -o eigenx eigenx-SST.f

cat >! eof.com <<ENDc
HadAnoPac-remglomis.d
DIR
4185 1              ; dimension of sampling stations
1419                   ; number of sampling points at each station
2                     ; read   1=time index first  2=space index first
0                     ; moving average lag (0: No smoothing)
0                     ; cycle period for removing mean (0: No)
1                     ; area adjustment (0: No,  1: Yes)
-89.5 1.0               ; starting latitude and increment for area adjustment
90                    ; percent variance
1                     ; EOF scaling factor
4                    ; number of EOFs to be printed
1                     ; PC normalization  (0: NO,  1: Yes)
ev-PDO.d
DIR
pc-PDO.d
DIR
ENDc
./eigenx < eof.com
mv inform.d inf-PDO-DJF18702021.d
