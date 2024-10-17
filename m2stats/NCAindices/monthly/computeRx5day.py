#!/usr/bin/env python

import sys
import re
import os
import os.path
import shutil
from netCDF4 import Dataset
import netCDF4
import time
print(sys.argv[1])
print(sys.argv[2])
year=sys.argv[1]
mon=sys.argv[2]
refperiod=sys.argv[3]
print(year)

outputdir='/discover/nobackup/dao_ops/m2stats/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'

periods = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'] 
period=periods[int(mon)-1]
print(period)

seldatestr = ''
if period == 'jan':
    seldatestr =  ' -selmon,01 -selyear,' + str(year)
    meandatestr =  ' -selmon,01 -selyear,2010'  
elif period == 'feb':
    seldatestr =  ' -selmon,02 -selyear,' + str(year)
    meandatestr =  ' -selmon,02 -selyear,2010'  
elif period == 'mar':
    seldatestr =  ' -selmon,03 -selyear,' + str(year)
    meandatestr =  ' -selmon,03 -selyear,2010'  
elif period == 'apr':
    seldatestr =  ' -selmon,04 -selyear,' + str(year)
    meandatestr =  ' -selmon,04 -selyear,2010'  
elif period == 'may':
    seldatestr =  ' -selmon,05 -selyear,' + str(year)
    meandatestr =  ' -selmon,05 -selyear,2010'  
elif period == 'jun':
    seldatestr =  ' -selmon,06 -selyear,' + str(year)
    meandatestr =  ' -selmon,06 -selyear,2010'  
elif period == 'jul':
    seldatestr =  ' -selmon,07 -selyear,' + str(year)
    meandatestr =  ' -selmon,07 -selyear,2010'  
elif period == 'aug':
    seldatestr =  ' -selmon,08 -selyear,' + str(year)
    meandatestr =  ' -selmon,08 -selyear,2010'  
elif period == 'sep':
    seldatestr =  ' -selmon,09 -selyear,' + str(year)
    meandatestr =  ' -selmon,09 -selyear,2010'  
elif period == 'oct':
    seldatestr =  ' -selmon,10 -selyear,' + str(year)
    meandatestr =  ' -selmon,10 -selyear,2010'  
elif period == 'nov':
    seldatestr =  ' -selmon,11 -selyear,' + str(year)
    meandatestr =  ' -selmon,11 -selyear,2010'    
elif period == 'dec':
    seldatestr =  ' -selmon,12 -selyear,' + str(year)
    meandatestr =  ' -selmon,12 -selyear,2010'  
else:
    print('skronk') 
    sys.exit(1)

if int(year) > 2019:
    rx5dayinfile = ' /discover/nobackup/dao_ops/m2stats/tmp/MERRA2.prectot.5daytotal.' + str(year) + period + '.nc'
else:
    rx5dayinfile = ' /discover/nobackup/acollow/MERRA2/Daily/ncfiles/MERRA2.prectot.5daytotalmike.' + str(year) + '.nc'

rx5dayoutfile='/discover/nobackup/dao_ops/m2stats/tmp/MERRA2_RX5DAY_prectot_' + str(year) + '_' + period +'.nc'

cdocmd = 'cdo eca_rx5day -selvar,prectot' + seldatestr 
cdocmd = cdocmd +  rx5dayinfile + ' ' + rx5dayoutfile
print(cdocmd)
os.system(cdocmd)
time.sleep(30)

outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(year) + str(mon).zfill(2) + '.nc4'
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
