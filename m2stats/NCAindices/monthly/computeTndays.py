#! /usr/bin/env python

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

outputdir='/discover/nobackup/dao_ops/m2stats/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'


#Determine Day of Year for Month
if np.remainder(yr,4) == 0:
        mnthlength=np.array([31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
else:
        mnthlength=np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
doyindex1=(datetime.datetime(yr,mnth,1,00,30).timetuple().tm_yday)-1
doyindex2=doyindex1+mnthlength[mnth-1]

#Load daily temperature data
t2mmin=np.empty([mnthlength[mnth-1],361,576]);
t2mmax=np.empty([mnthlength[mnth-1],361,576]);

for d in range(mnthlength[mnth-1]):
	statDfile = Dataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_400' + '/Y' + str(yr) + '/M' + str(mnth).zfill(2) + '/MERRA2_400.statD_2d_slv_Nx.' + str(yr) + str(mnth).zfill(2) + str(d+1).zfill(2) + '.nc4',mode='r')
	t2mmin[d,:,:]=statDfile.variables['T2MMIN'][:,:,:]
	t2mmax[d,:,:]=statDfile.variables['T2MMAX'][:,:,:]

lat=statDfile.variables['lat'][:]
lon=statDfile.variables['lon'][:]


#Create output file
outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(yr) + str(mnth).zfill(2) + '.nc4'
if not exists(outfile):
	ncfile = Dataset(outfile, mode='w', format='NETCDF4_CLASSIC')
	ncfile.createDimension('lat',361)
	ncfile.createDimension('lon',576)
	ncfile.createDimension('time',1)
	lat_var = ncfile.createVariable('lat', np.float32, ('lat',))
	lat_var.units = 'degrees_north'
	lat_var.long_name = 'latitude'
	lat_var[:]=lat
	lon_var = ncfile.createVariable('lon', np.float32, ('lon',))
	lon_var.units = 'degrees_east'
	lon_var.long_name = 'longitude'
	lon_var[:]=lon
	time_var = ncfile.createVariable('time', np.float64, ('time',))
	time_var.units = 'hours since ' + str(yr) + '-' + str(mnth).zfill(2) + '-01'
	time_var.long_name = 'time'
	time_var[:]=[0]
	ncfile.ShortName='M2SMNXEDI'
	ncfile.LongName='MERRA-2 statM_2d_edi_Nx: 2d, Single-Level, Monthly Extreme Detection Indices'
	ncfile.Title='MERRA-2 statM_2d_edi_Nx: 2d, Single-Level, Monthly Extreme Detection Indices'
	ncfile.Institution='NASA Global Modeling and Assimilation Office'
	ncfile.Contact='https://gmao.gsfc.nasa.gov'
	ncfile.Filename=outfile
	ncfile.GranuleID=outfile
	ncfile.identifier_prodict_doi_authority='http://dx.doi.org/'
	ncfile.identifier_product_doi='10.5067/QFJ13GEGDI99'
	ncfile.Source='CVS tag: GEOSadas-5_12_4'
	ncfile.ProcessingLevel='Level 4'
	ncfile.DataSetQuality='A validation of the source dataset is provided in Gelaro et al. 2017 (https://doi.org/10.1175/JCLI-D-16-0758.1)'
	ncfile.VersionID='2.1'
	ncfile.format='NetCDF-4'
	ncfile.Conventions='CF1.7'
	ncfile.SpatialCoverage='Global'
	ncfile.MapProjection='Latitude-Longitude'
	ncfile.SouthernmostLatitude='-90.0'
	ncfile.NorthernmostLatitude='90.0'
	ncfile.WesternmostLongitude='-180.0'
	ncfile.EasternmostLongitude='179.375'
	ncfile.LatitudeResolution='0.5'
	ncfile.LongitudeResolution='0.625'
	ncfile.DataResolution='0.5 x 0.625'
	ncfile.RangeBeginningDate= str(yr) + '-' + str(mnth).zfill(2) + '-01'
	ncfile.RangeBeginningTime= '00:00:00.000000'
	ncfile.RangeEndingDate= str(yr) + '-' + str(mnth).zfill(2) + '-' + str(calendar.monthrange(yr,mnth)[1])
	ncfile.RangeEndingTime='23:59:59.000000'
	now=datetime.datetime.utcnow().strftime("%b %d %Y %H:%M:%S")
	ncfile.ProductionDateTime='File generated: ' + now + ' GMT'
	ncfile.close()

#Compute Frost days
fd=t2mmin-273.15
fd[fd>=0]=0
fd[fd<0]=1
fd=np.nansum(fd,axis=0)
ncfile = Dataset(outfile, mode='a')
fd_var = ncfile.createVariable('FD','i',('time','lat','lon'),fill_value=-9999)
fd_var[:]=fd
fd_var.units = 'count'
fd_var.long_name='Frost Days (count of days when daily minimum 2 m temperature is less than 0 degrees C)'


#Compute Summer days
su=t2mmax-298.15
su[su<=0]=0
su[su>0]=1
su=np.nansum(su,axis=0)
su_var = ncfile.createVariable('SU','i',('time','lat','lon'),fill_value=-9999)
su_var[:]=su
su_var.units = 'count'
su_var.long_name='Summer Days (count of days when daily maximum 2 m temperature is greater than 25 degrees C)'


#Compute Icing days
iced=t2mmax-273.15
iced[iced>=0]=0
iced[iced<0]=1
iced=np.nansum(iced,axis=0)
ncfile = Dataset(outfile, mode='a')
iced_var = ncfile.createVariable('ID','i',('time','lat','lon'),fill_value=-9999)
iced_var[:]=iced
iced_var.units = 'count'
iced_var.long_name='Icing Days (count of days when daily maximum 2 m temperature is less than 0 degrees C)'


#Compute Tropical Nights
tr=t2mmin-293.15
tr[tr<=0]=0
tr[tr>0]=1
tr=np.nansum(tr,axis=0)
tr_var = ncfile.createVariable('TR','i',('time','lat','lon'),fill_value=-9999)
tr_var[:]=tr
tr_var.units = 'count'
tr_var.long_name='Tropical Nights (count of days when daily minimum 2 m temperature is greater than 20 degrees C)'


#Compute Diurnal Temperature Range
dtr=np.nanmean(t2mmax-t2mmin,axis=0)
dtr_var = ncfile.createVariable('DTR','f',('time','lat','lon'),fill_value=-9999)
dtr_var[:]=dtr
dtr_var.units = 'K'
dtr_var.long_name='Diurnal Temperature Range'

#Compute Tx90p, Tn90p, Tx10p, and Tn10p
def Tpcnt(minmax,pctl):
	pctlfile = Dataset('/discover/nobackup/acollow/NCAindices/ccdi/percentilefiles_CDObased/MERRA2.ydrunpctl_t2m' + minmax + str(pctl) + 'thpctl.' + refperiod + '.15daywindow.nc',mode='r')
	pctlyr = pctlfile.variables['t2m' + minmax][:]
	pctlthresh=pctlyr[doyindex1:doyindex2,:,:]
	if minmax=='max':
		t2m=t2mmax-pctlthresh
	else:
		t2m=t2mmin-pctlthresh

	if pctl==90:
		t2m[t2m<0]=0
		t2m[t2m>0]=1
	else:
		t2m[t2m>0]=0
		t2m[t2m<0]=1
		
	Tvar=(np.nansum(t2m,axis=0)/mnthlength[mnth-1])*100
	return(Tvar)


tx90p=Tpcnt('max',90)
tx90p_var = ncfile.createVariable('TX90p','f',('time','lat','lon'),fill_value=-9999)
tx90p_var[:]=tx90p
tx90p_var.units = '%'
tx90p_var.long_name='percentage of time when daily max 2-m temperature > 90th percentile'

tn90p=Tpcnt('min',90)
tn90p_var = ncfile.createVariable('TN90p','f',('time','lat','lon'),fill_value=-9999)
tn90p_var[:]=tn90p
tn90p_var.units = '%'
tn90p_var.long_name='percentage of time when daily min 2-m temperature > 90th percentile'

tx10p=Tpcnt('max',10)
tx10p_var = ncfile.createVariable('TX10p','f',('time','lat','lon'),fill_value=-9999)
tx10p_var[:]=tx10p
tx10p_var.units = '%'
tx10p_var.long_name='percentage of time when daily max 2-m temperature < 10th percentile'

tn10p=Tpcnt('min',10)
tn10p_var = ncfile.createVariable('TN10p','f',('time','lat','lon'),fill_value=-9999)
tn10p_var[:]=tn10p
tn10p_var.units = '%'
tn10p_var.long_name='percentage of time when daily min 2-m temperature < 10th percentile'


ncfile.close()
sys.exit(1)
