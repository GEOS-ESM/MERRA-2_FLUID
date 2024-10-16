#!/usr/bin/env python

import sys
import re
import os
import os.path
import shutil
import time
from netCDF4 import Dataset
import netCDF4
print(sys.argv[1])
print(sys.argv[2])
year=sys.argv[1]
ssn=int(sys.argv[2])
refperiod=sys.argv[3]

outputdir='/discover/nobackup/dao_ops/m2stats/gmao/nca/indices/seasonalccdi/basedon' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'

print(outputdir)

if ssn == 1:
        period='ndj'
elif ssn == 2:
        period='djf'
elif ssn == 3:
        period='jfm'
elif ssn == 4:
        period='fma'
elif ssn == 5:
        period='mam'
elif ssn == 6:
        period='amj'
elif ssn == 7:
        period='mjj'
elif ssn == 8:
        period='jja'
elif ssn == 9:
        period='jas'
elif ssn == 10:
        period='aso'
elif ssn == 11:
        period='son'
elif ssn == 12:
        period='ond'

print(period)

if int(year)<2019:
	rx5dayinfile = ' /discover/nobackup/acollow/MERRA2/Daily/ncfiles/MERRA2.prectot.5daytotalmike.' + str(year) + '.nc'
else:
	rx5dayinfile = '/discover/nobackup/dao_ops/m2stats/tmp/MERRA2.prectot.5daytotal.uptodate.nc'
timestr = ''

if period == 'djf':
    if int(year)%4 == 0:
        print('leapyear!')
        timestr = '-seldate,' + str(int(year)-1) + '-12-01,' + str(year) + '-02-29'
    else:
        timestr = '-seldate,' + str(int(year)-1) + '-12-01,' + str(year) + '-02-28'
elif period == 'ndj':
        timestr = '-seldate,' + str(int(year)-1) + '-11-01,' + str(year) + '-01-31'		 
else:
    timestr = '-select,season=' + period + ' -selyear,' + str(year)




#RX5Day
cdocmd = 'cdo eca_rx5day ' + timestr
rx5dayoutfile='MERRA2_RX5Day_prectot_' + str(year) + '_' + period +'.nc'
cdocmd = cdocmd +  ' ' + rx5dayinfile + ' ' + rx5dayoutfile
print(cdocmd)
os.system(cdocmd)

time.sleep(30)

outfile=outputdir + '/MERRA2.statS_2d_edi_Nx.v2_1.' + str(year) + str(ssn).zfill(2) + '.nc4'
ncfile = Dataset(outfile, mode='a')
rx5dayfile=Dataset(rx5dayoutfile,mode='r')
rx5day=rx5dayfile.variables['highest_five_day_precipitation_amount_per_time_period'][:]
rx5daycount=rx5dayfile.variables['number_of_5day_heavy_precipitation_periods_per_time_period'][:]

rx5day_var = ncfile.createVariable('RX5Day','f',('time','lat','lon'),fill_value=-9999)
rx5day_var[:]=rx5day
rx5day_var.units = 'mm per 5 days'
rx5day_var.long_name='Highest precipitation amount for a five day interval'

rx5daycount_var = ncfile.createVariable('RX5Daycount','i',('time','lat','lon'),fill_value=-9999)
rx5daycount_var[:]=rx5daycount
rx5daycount_var.units = 'count'
rx5daycount_var.long_name='count of five-day heavy precipitation periods >= 50 mm'


sys.exit(1)
