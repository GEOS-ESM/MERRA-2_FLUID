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
from itertools import groupby
from os.path import exists
#print(sys.argv[1])
#print(sys.argv[2])
yr=int(sys.argv[1])
mnth=int(sys.argv[2])
refperiod=sys.argv[3]

outputdir='/discover/nobackup/dao_ops/m2stats/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'

def len_iter(items):
	return sum(1 for _ in items)

def consecutive_one(data):
	return max(len_iter(run) for val, run in groupby(data) if val==1)

def ndays(n,outfile):
	r=prectot-n
	r[r<0]=np.nan
	r[r>=0]=1
	r=np.nansum(r,axis=0)
	if n==1:
		dry=prectot-n
		dry[dry>=0]=np.nan
		dry[dry<0]=1
		dry=np.nansum(dry,axis=0)
		ncfile = Dataset(outfile, mode='a')
		dry_var = ncfile.createVariable('drydays','i',('time','lat','lon'),fill_value=-9999)
		dry_var[:]=dry
		dry_var.units = 'count'
		dry_var.long_name='count of days with precipitation < 1 mm'
		r_var = ncfile.createVariable('wetdays','i',('time','lat','lon'),fill_value=-9999)
	else:
		ncfile = Dataset(outfile, mode='a')
		r_var = ncfile.createVariable('R' + str(n) + 'mm','i',('time','lat','lon'),fill_value=-9999)

	r_var[:]=r
	r_var.units='count'
	r_var.long_name='count of days with precipitation >= ' + str(n) + 'mm'		
	ncfile.close()

def Rindex(doyindex1,doyindex2,pctl,outfile):
#Load annual percentile data
	precfile = Dataset('/discover/nobackup/acollow/NCAindices/ccdi/percentilefiles_CDObased/MERRA2.ydrunpctl_prectot' + str(pctl) + 'thpctl.' + refperiod + '.15daywindow.nc',mode='r')
	prec95pyr = precfile.variables['prectot'][:]
	prec95pyr=np.nan_to_num(prec95pyr, nan=1.0, posinf=None, neginf=None)
	prec95pyr[prec95pyr<-990]=1
	prec95p=prec95pyr[doyindex1:doyindex2,:,:]
#Compute ETCCDI
	r95=prectot-prec95p
	r95[r95<0]=np.nan
	r95[r95>=0]=1
	r95d=np.nansum(r95,axis=0)
	r95p=np.nanmean(prectot*r95,axis=0)
	r95p[np.isnan(r95p)]=-9999.0
#Write output to netCDF file
	ncfile = Dataset(outfile, mode='a')
	r95p_var = ncfile.createVariable('R' + str(pctl) + 'P','f',('time','lat','lon'),fill_value=-9999)
	r95p_var[:]=r95p
	r95p_var.units = 'mm day-1'
	r95p_var.long_name='total precipitation from days > ' + str(pctl) + 'th percentile'
	r95d_var = ncfile.createVariable('R' + str(pctl) + 'D','i',('time','lat','lon'),fill_value=-9999)
	r95d_var[:]=r95d
	r95d_var.units = 'count'
	r95d_var.long_name='count of days with precipitation > ' + str(pctl) + 'th percentile'
	ncfile.close()
	del precfile
	del r95
	del prec95pyr

#Determine Day of Year for Month
if np.remainder(yr,4) == 0:
        mnthlength=np.array([31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
else:
        mnthlength=np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
doyindex1=(datetime.datetime(yr,mnth,1,00,30).timetuple().tm_yday)-1
doyindex2=doyindex1+mnthlength[mnth-1]

#Load precip data and compute daily mean
prectot=np.empty([mnthlength[mnth-1],361,576]);

counter=0
for d in range(mnthlength[mnth-1]):
	flxfile = Dataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_400' + '/Y' + str(yr) + '/M' + str(mnth).zfill(2) + '/MERRA2_400.tavg1_2d_flx_Nx.' + str(yr) + str(mnth).zfill(2) + str(d+1).zfill(2) + '.nc4',mode='r')
	prectot[counter,:,:]=86400*np.nanmean(flxfile.variables['PRECTOT'][:,:,:],axis=0)
	
	counter=counter+1
lat=flxfile.variables['lat'][:]
lon=flxfile.variables['lon'][:]


#precfile=Dataset('tempdailyprecip.nc', mode='w', format='NETCDF4_CLASSIC')
#ncfile.createDimension('lat',361)
#ncfile.createDimension('lon',576)
#ncfile.createDimension('time',1)
#lat_var = ncfile.createVariable('lat', np.float32, ('lat',))
#lat_var.units = 'degrees_north'
#lat_var.long_name = 'latitude'
#lat_var[:]=lat
#lon_var = ncfile.createVariable('lon', np.float32, ('lon',))
#lon_var.units = 'degrees_east'
#lon_var.long_name = 'longitude'
#lon_var[:]=lon
#time_var = ncfile.createVariable('time', np.float64, ('time',))
#time_var.units = 'hours since ' + str(yr) + '-' + str(mnth).zfill(2) + '-01'
#time_var.long_name = 'time'
#time_var[:]=[0]
#prec_var = ncfile.createVariable('prectot','f',('time','lat','lon'))
#prec_var[:]=prectot

#Create output file
outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(yr) + str(mnth).zfill(2) + '.nc4'
outfilenodir='MERRA2.statM_2d_edi_Nx.v2_1.' + str(yr) + str(mnth).zfill(2) + '.nc4'
if not exists(outfile):
	ncfile = Dataset(outfile, mode='w', format='NETCDF4_CLASSIC')
	ncfile.createDimension('lat',361)
	ncfile.createDimension('lon',576)
	ncfile.createDimension('time',1)
	lat_var = ncfile.createVariable('lat', np.float32, ('lat',))
	lat_var.units = 'degrees_north'
	lat_var.long_name = 'latitude'
	lat_var.standard_name = "latitude"
	lat_var[:]=lat
	lon_var = ncfile.createVariable('lon', np.float32, ('lon',))
	lon_var.units = 'degrees_east'
	lon_var.long_name = 'longitude'
	lon_var.standard_name = "longitude"
	lon_var[:]=lon
	time_var = ncfile.createVariable('time', np.float64, ('time',))
	time_var.units = 'hours since ' + str(yr) + '-' + str(mnth).zfill(2) + '-01'
	time_var.long_name = 'time'
	time_var[:]=[0]
	ncfile.ShortName='M2SMNXEDI'
	ncfile.LongName='MERRA-2 statM_2d_edi_Nx: 2d, Single-Level, Monthly Extreme Detection Indices based on 1991-2020'
	ncfile.Title='MERRA-2 statM_2d_edi_Nx: 2d, Single-Level, Monthly Extreme Detection Indices'
	ncfile.Institution='NASA Global Modeling and Assimilation Office'
	ncfile.Contact='https://gmao.gsfc.nasa.gov'
	ncfile.Filename=outfilenodir
	ncfile.GranuleID=outfilenodir
	ncfile.identifier_product_doi_authority='http://dx.doi.org/'
	ncfile.identifier_product_doi='10.5067/O8AX56DO60MI'
	ncfile.Source='CVS tag: GEOSadas-5_12_4'
	ncfile.ProcessingLevel='Level 4'
	ncfile.DataSetQuality='A validation of the source dataset is provided in Gelaro et al. 2017 (https://doi.org/10.1175/JCLI-D-16-0758.1)'
	ncfile.VersionID='2.1'
	ncfile.Format='NetCDF-4'
	ncfile.Conventions='CF-1.7'
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
	ncfile.comment='Based on a climatology period of ' + refperiod[0:4] + '-' + refperiod[4:8]
	ncfile.close()
#Compute R90d, R95d, R99d, R90p, R95p, and R99p
for pctl in [90, 95, 99]:
	Rindex(doyindex1,doyindex2,pctl,outfile)

#Compute wetdays, drydays, Rx10mm, Rx20mm
for n in [1, 10, 20]:
	ndays(n,outfile)

rx1d=np.nanmax(prectot,axis=0)
ncfile = Dataset(outfile, mode='a')
rx1d_var = ncfile.createVariable('RX1Day','f',('time','lat','lon'),fill_value=-9999)
rx1d_var[:]=rx1d
rx1d_var.units = 'mm day-1'
rx1d_var.long_name='maximum one-day precipitation amount'

#Compute consecutive wet days
wetdays=prectot+0
wetdays[wetdays<1]=np.nan
wetdays[wetdays>=1]=1
cwd=np.empty([361,576])
for lons in range(576):
	for lats in range(361):
		#print(np.nanmax(wetdays[:,lats,lons]))
		if np.nanmax(wetdays[:,lats,lons])>0:
			cwd[lats,lons]=consecutive_one(wetdays[:,lats,lons])
		else:
			cwd[lats,lons]=0
cwd_var = ncfile.createVariable('CWD','i',('time','lat','lon'),fill_value=-9999)
cwd_var[:]=cwd
cwd_var.units = 'count'
cwd_var.long_name='Consecutive Wet Days (maximum number of consecutive days when precipitation >= 1 mm)'

#Compute SDII
sdii=np.nansum(wetdays*prectot,axis=0)/np.nansum(wetdays,axis=0)
sdii[np.isnan(sdii)]=-9999.0
sdii_var = ncfile.createVariable('SDII','f',('time','lat','lon'),fill_value=-9999)
sdii_var[:]=sdii
sdii_var.units = 'mm day-1'
sdii_var.long_name='Simple Daily precipitation Intensity Index (ratio of the total precipitation on wet days to the number of wet days)'

#Compute consecutive dry days
drydays=prectot-1
drydays[drydays>0]=0
drydays[drydays<0]=1
cdd=np.empty([361,576])
for lons in range(576):
	for lats in range(361):
		if np.nanmax(drydays[:,lats,lons])>0:
			cdd[lats,lons]=consecutive_one(drydays[:,lats,lons])
		else:
			cdd[lats,lons]=0
cdd_var = ncfile.createVariable('CDD','i',('time','lat','lon'),fill_value=-9999)
cdd_var[:]=cdd
cdd_var.units = 'count'
cdd_var.long_name='Consecutive Dry Days (maximum number of consecutive days when precipitation < 1 mm)'



ncfile.close()
sys.exit(1)
