#! /usr/local/other/python/GEOSpyD/4.8.3_py3.8/2020-08-11/bin/python

# import modules
import numpy as np
from netCDF4 import Dataset
import netCDF4
import datetime
import sys
import re
import os
import os.path
import shutil
import calendar
import matplotlib.pyplot as plt
from itertools import groupby
from os.path import exists
#print(sys.argv[1])
#print(sys.argv[2])
yr=int(sys.argv[1])
mnth=int(sys.argv[2])
refperiod=sys.argv[3]

outputdir='/discover/nobackup/projects/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'
outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(yr) + str(mnth).zfill(2) + '.nc4'
outfilenodir='MERRA2.statM_2d_edi_Nx.v2_1.' + str(yr) + str(mnth).zfill(2) + '.nc4'

#Determine Day of Year for Month
if np.remainder(yr,4) == 0:
        mnthlength=np.array([31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
else:
        mnthlength=np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
doyindex1=(datetime.datetime(yr,mnth,1,00,30).timetuple().tm_yday)-1
doyindex2=doyindex1+mnthlength[mnth-1]

#Load daily temperature data
t2mmax=np.empty([mnthlength[mnth-1],361,576]);

for d in range(mnthlength[mnth-1]):
	statDfile = Dataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_all' + '/Y' + str(yr) + '/M' + str(mnth).zfill(2) + '/MERRA2.statD_2d_slv_Nx.' + str(yr) + str(mnth).zfill(2) + str(d+1).zfill(2) + '.nc4',mode='r')
	t2mmax[d,:,:]=statDfile.variables['T2MMAX'][:,:,:]

lat=statDfile.variables['lat'][:]
lon=statDfile.variables['lon'][:]

ncfile = Dataset(outfile, mode='a')
#Compute Icing days
iced=t2mmax-273.15
iced[iced>=0]=0
iced[iced<0]=1
iced=np.nansum(iced,axis=0)
ncfile = Dataset(outfile, mode='a')
#iced_var = ncfile.createVariable('ID','i',('time','lat','lon'),fill_value=-9999)
ncfile['ID'][:]=iced
#iced_var.units = 'count'
#iced_var.long_name='Icing Days (count of days when daily maximum 2 m temperature is less than 0 degrees C)'



ncfile.VersionID='2.1'
now=datetime.datetime.utcnow().strftime("%b %d %Y %H:%M:%S")
ncfile.ProductionDateTime='File generated: ' + now + ' GMT'
ncfile.Filename=outfilenodir
ncfile.GranuleID=outfilenodir

ncfile.close()
sys.exit(1)
