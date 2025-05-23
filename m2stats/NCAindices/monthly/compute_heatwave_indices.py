# !/usr/bin/env python

# Computes heat wave indices for month of choice
#  Heat wave defined as T2MMEAN exceeding the 90th percentile for at least 3 days
#  For the month, computes and writes to file:
#    1. HWN: Number of heat wave events (# events)
#    2. HWD: Length of longest heat wave (# days)
#    3. HWF: Total number of heat wave days (# days)
#    4. HWA: Temperature on the hottest day of the hottest heat wave (K)
#    5. HWM: Average temperature on all heat wave days (K)
#
# Also computes
#    1. WSDI: warm spell duration index
#    2. CSDI: cold spell duration index
#    3. LWS: longest warm spell
#    4. LCS: longest cold spell
#
#  Inputs: 
#   yearchoice = year to compute heatwave indices;
#   monchoice = month to compute heatwave indices;
#   refperiod = reference period for percentiles/climatology 
#               (19812010 or 19912020)

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

import sys
import re
import os
import numpy as np
import math
import datetime
import netCDF4
import calendar

yearchoice=int(sys.argv[1])
monchoice=int(sys.argv[2])
refperiod=sys.argv[3]
outputdir='/discover/nobackup/dao_ops/m2stats/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'
print(outputdir)


# load calendar day temperature percentiles and climatology
f1 = netCDF4.Dataset('/discover/nobackup/acollow/NCAindices/ccdi/percentilefiles_CDObased/MERRA2.ydrunpctl_t2mmean90thpctl.'+refperiod+'.15daywindow.nc','r')
tmean90alldays = f1.variables['t2mmean'][:, :, :]

f2 = netCDF4.Dataset('/discover/nobackup/acollow/NCAindices/ccdi/percentilefiles_CDObased/MERRA2.ydrunpctl_t2mmax90thpctl.'+refperiod+'.15daywindow.nc','r')
tmax90alldays = f2.variables['t2mmax'][:, :, :]

f3 = netCDF4.Dataset('/discover/nobackup/acollow/NCAindices/ccdi/percentilefiles_CDObased/MERRA2.ydrunpctl_t2mmin10thpctl.'+refperiod+'.15daywindow.nc','r')
tmin10alldays = f3.variables['t2mmin'][:, :, :]

f4 = netCDF4.Dataset('/discover/nobackup/npthomas/MERRA2/dailyavgs/daily_climatology/temperature_climatology_'+refperiod+'.nc','r')
tclimalldays = f4.variables['t2mmeanclim'][:,:,:]

#find month length 
if np.remainder(yearchoice,4) == 0:
  mnthlength=np.array([31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
else: 
  mnthlength=np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);

#load data - monthchoice + last (first) 3 days of month before (after)
indir='/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_400'
tmean=np.empty([mnthlength[monchoice-1]+6,361,576])
tmax=np.empty([mnthlength[monchoice-1]+6,361,576])
tmin=np.empty([mnthlength[monchoice-1]+6,361,576])

# identify months to load
y1 = yearchoice;
m1 = monchoice-1;
y2 = yearchoice;
m2 = monchoice;
y3 = yearchoice;
m3 = monchoice+1;
if monchoice==1: #for january, previous month is december of previous year
  m1 = 12
  y1 = yearchoice-1
elif monchoice==12: #for december, next month is jan of next year
  m3 = 1
  y3 = yearchoice+1


#m1, y1
if (monchoice==1)&(yearchoice==1980): #for January1980, pad "preceding month" with all zeros
  tmean[0:3,:,:]=0;
  tmax[0:3,:,:]=0;
  tmin[0:3,:,:]=0;
  daycount=3
else:
  daycount=0
  for didx in range(mnthlength[m1-1]-2,mnthlength[m1-1]+1): #day loop
    f=netCDF4.Dataset(indir +'/Y' + str(y1) + '/M' + str(m1).zfill(2) + '/MERRA2_400.statD_2d_slv_Nx.' + str(y1) + str(m1).zfill(2) + str(didx).zfill(2) + '.nc4','r')
    tmean[daycount,:,:]=f.variables['T2MMEAN'][:,:,:]
    tmax[daycount,:,:]=f.variables['T2MMAX'][:,:,:]
    tmin[daycount,:,:]=f.variables['T2MMIN'][:,:,:]
    daycount=daycount+1;

#m2, y2
for didx in range(mnthlength[m2-1]): #day loop
  f=netCDF4.Dataset(indir +'/Y' + str(y2) + '/M' + str(m2).zfill(2) + '/MERRA2_400.statD_2d_slv_Nx.' + str(y2) + str(m2).zfill(2) + str(didx+1).zfill(2) + '.nc4','r')
  tmean[daycount,:,:]=f.variables['T2MMEAN'][:,:,:]
  tmax[daycount,:,:]=f.variables['T2MMAX'][:,:,:]
  tmin[daycount,:,:]=f.variables['T2MMIN'][:,:,:]
  daycount=daycount+1;

#m3, y3
for didx in range(3): #day loop
  f=netCDF4.Dataset(indir +'/Y' + str(y3) + '/M' + str(m3).zfill(2) + '/MERRA2_400.statD_2d_slv_Nx.' + str(y3) + str(m3).zfill(2) + str(didx+1).zfill(2) + '.nc4','r')
  tmean[daycount,:,:]=f.variables['T2MMEAN'][:,:,:]
  tmax[daycount,:,:]=f.variables['T2MMAX'][:,:,:]
  tmin[daycount,:,:]=f.variables['T2MMIN'][:,:,:]
  daycount=daycount+1;
lat=f.variables['lat'][:]
lon=f.variables['lon'][:]

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Subset percentile data to just month of choice + surrounding 3 days
# find indices of start dates of each month - use 1980 since percentile files have 366 days
doyindex1=(datetime.datetime(y1,m1,mnthlength[m1-1]-2,00,30).timetuple().tm_yday)-1
doyindex2=(datetime.datetime(y2,m2,1,00,30).timetuple().tm_yday)-1
doyindex3=(datetime.datetime(y3,m3,1,00,30).timetuple().tm_yday)-1

tpc1=tmean90alldays[doyindex1:doyindex1+3,:,:]
tpc2=tmean90alldays[doyindex2:doyindex2+mnthlength[m2-1],:,:]
tpc3=tmean90alldays[doyindex3:doyindex3+3,:,:]
tmean90pc=np.concatenate((tpc1, tpc2, tpc3))

tpc1=tmax90alldays[doyindex1:doyindex1+3,:,:]
tpc2=tmax90alldays[doyindex2:doyindex2+mnthlength[m2-1],:,:]
tpc3=tmax90alldays[doyindex3:doyindex3+3,:,:]
tmax90pc=np.concatenate((tpc1, tpc2, tpc3))

tpc1=tmin10alldays[doyindex1:doyindex1+3,:,:]
tpc2=tmin10alldays[doyindex2:doyindex2+mnthlength[m2-1],:,:]
tpc3=tmin10alldays[doyindex3:doyindex3+3,:,:]
tmin10pc=np.concatenate((tpc1, tpc2, tpc3))

tclim1=tclimalldays[doyindex1:doyindex1+3,:,:]
tclim2=tclimalldays[doyindex2:doyindex2+mnthlength[m2-1],:,:]
tclim3=tclimalldays[doyindex3:doyindex3+3,:,:]
tclim=np.concatenate((tclim1, tclim2, tclim3))

#Tmean greater than 90th percentile - for heat wave indices
tpcex90mean=tmean-tmean90pc
tpcex90mean[tpcex90mean>=0]=1
tpcex90mean[tpcex90mean<0]=0
tanom=tmean-tclim

#Tmax greater than 90th percentile - for WSDI and LWS
tpcex90max=tmax-tmax90pc
tpcex90max[tpcex90max>=0]=1
tpcex90max[tpcex90max<0]=0

#Tmin less than 10th percentile - for CSDI and LCS
tpcex10min=tmin-tmin10pc
tpcex10min[tpcex10min>=0]=0
tpcex10min[tpcex10min<0]=1

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Loop through all grid points to find percentile exceedance days for these 3 months

tpcex90mean3=np.zeros([mnthlength[monchoice-1]+6,361,576]); #t2mmean exceeeds 90th percentile for 3 days
tpcex90max6=np.zeros([mnthlength[monchoice-1]+6,361,576]); #t2mmax exceds 90th percentile for 6 days
tpcex10min6=np.zeros([mnthlength[monchoice-1]+6,361,576]); #t2mmin is below 10th percentile for 6 days

for xidx in range(576):
  for yidx in range(361):
    pctemp1=tpcex90mean[:,yidx,xidx]
    pctemp2=tpcex90max[:,yidx,xidx]
    pctemp3=tpcex10min[:,yidx,xidx]
    #Diff function - will be equal to 1 on first day of warm period
    #and equal to -1 on last day of warm period
    #start will give indices of first day of warm period
    #stop will give indices of last day of warm period
    difftemp1=np.diff(pctemp1,axis=0)
    difftemp2=np.diff(pctemp2,axis=0)
    difftemp3=np.diff(pctemp3,axis=0)
    start1=np.where(difftemp1==1)[0]+1
    stop1=np.where(difftemp1==-1)[0]+1
    start2=np.where(difftemp2==1)[0]+1
    stop2=np.where(difftemp2==-1)[0]+1
    start3=np.where(difftemp3==1)[0]+1
    stop3=np.where(difftemp3==-1)[0]+1
    #If the first day of the period is a warm day, need to make the first entry of 'start' 0
    #If the last day of the period is a warm day, need to make the last entry of 'stop' equal to the length of the period
    # Heat Waves 
    if pctemp1[0]==1:
      start1=np.insert(start1,0,0)
    if pctemp1[-1]==1:
      if stop1.size==0:
        stop1=[int(np.size(difftemp1))]
      else:
        stop1=np.append(stop1,int(np.size(difftemp1)))
    # Warm Spells 
    if pctemp2[0]==1:
      start2=np.insert(start2,0,0)
    if pctemp2[-1]==1:
      if stop2.size==0:
        stop2=[int(np.size(difftemp2))]
      else:
        stop2=np.append(stop2,int(np.size(difftemp2)))
    # Cold Spells
    if pctemp3[0]==1:
      start3=np.insert(start3,0,0)
    if pctemp3[-1]==1:
      if stop3.size==0:
        stop3=[int(np.size(difftemp3))]
      else:
        stop3=np.append(stop3,int(np.size(difftemp3)))
    #subtract stop from start - this will give the length of each warm period
    #find where this is greater than or equal to the length of heat wave definition
    dur1=stop1-start1
    dur2=stop2-start2
    dur3=stop3-start3
    good1=np.where(dur1>=3)
    good1=good1[0]
    good2=np.where(dur2>=6)
    good2=good2[0]
    good3=np.where(dur3>=6)
    good3=good3[0]
    #For each warm period which passes the heat wave definition, set all values
    #within the warm period equal to 1
    #Heat Waves
    if np.size(good1)!=0:
      for fillidx in range(np.size(good1)):
        tpcex90mean3[start1[good1[fillidx]]:stop1[good1[fillidx]],yidx,xidx]=1
    #Warm Spells
    if np.size(good2)!=0:
      for fillidx in range(np.size(good2)):
        tpcex90max6[start2[good2[fillidx]]:stop2[good2[fillidx]],yidx,xidx]=1
    # Cold Spells
    if np.size(good3)!=0:
      for fillidx in range(np.size(good3)):
        tpcex10min6[start3[good3[fillidx]]:stop3[good3[fillidx]],yidx,xidx]=1

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Loop through all grid points to find heat wave indices for just month of choice

HWF=np.empty([361,576])
HWD=np.empty([361,576])
HWN=np.empty([361,576])
HWA=np.empty([361,576])
HWM=np.empty([361,576])
WSDI=np.empty([361,576])
CSDI=np.empty([361,576])
LCS=np.empty([361,576])
LWS=np.empty([361,576])

for xidx in range(576):
  for yidx in range(361):
      hwtemp=tpcex90mean3[3:-3,yidx,xidx]
      wstemp=tpcex90max6[3:-3,yidx,xidx]
      cstemp=tpcex10min6[3:-3,yidx,xidx]
      t2mtemp=tmean[3:-3,yidx,xidx]
      tanomtemp=tanom[3:-3,yidx,xidx]
      HWF[yidx,xidx]=sum(hwtemp);
      wscount=sum(wstemp);
      cscount=sum(cstemp);
      if HWF[yidx,xidx]==0: #no heat wave days
        HWD[yidx,xidx]=-9999.0
        HWN[yidx,xidx]=0
        HWA[yidx,xidx]=-9999.0
        HWM[yidx,xidx]=-9999.0
      else:
        hwfind=np.where(hwtemp==1)
        hwfind=hwfind[0]
        HWA[yidx,xidx]=np.max(t2mtemp[hwfind])
        HWM[yidx,xidx]=np.mean(tanomtemp[hwfind])
        datadiff=np.diff(hwtemp)
        startev=np.where(datadiff==1)
        startev=startev[0]+1
        stopev=np.where(datadiff==-1)
        stopev=stopev[0]+1
        if hwtemp[-1]==1:
          stopev=np.append(stopev,int(np.size(hwtemp)))
        if hwtemp[0]==1:
          startev=np.insert(startev,0,0)
        dur=stopev-startev
        dur=dur[np.where(dur>=3)];
        if dur.size==0:
          HWN[yidx,xidx]=0
          HWD[yidx,xidx]=-9999.0
        else:
          HWN[yidx,xidx]=len(dur)
          HWD[yidx,xidx]=max(dur)

      if wscount==0: #no warm spell days
        WSDI[yidx,xidx]=0
        LWS[yidx,xidx]=-9999.0
      else:
        datadiff=np.diff(wstemp)
        startev=np.where(datadiff==1)
        startev=startev[0]+1
        stopev=np.where(datadiff==-1)
        stopev=stopev[0]+1
        if wstemp[-1]==1:
          stopev=np.append(stopev,int(np.size(wstemp)))
        if wstemp[0]==1:
          startev=np.insert(startev,0,0)
        dur=stopev-startev
        dur=dur[np.where(dur>=6)];
        if dur.size==0:
          LWS[yidx,xidx]=-9999.0
          WSDI[yidx,xidx]=0
        else:
          WSDI[yidx,xidx]=len(dur)
          LWS[yidx,xidx]=max(dur)
      
      if cscount==0: #no cold spell days 
        CSDI[yidx,xidx]=0
        LCS[yidx,xidx]=-9999.0
      else:
        datadiff=np.diff(cstemp)
        startev=np.where(datadiff==1)
        startev=startev[0]+1
        stopev=np.where(datadiff==-1)
        stopev=stopev[0]+1
        if cstemp[-1]==1:
          stopev=np.append(stopev,int(np.size(cstemp)))
        if cstemp[0]==1:
          startev=np.insert(startev,0,0)
        dur=stopev-startev
        dur=dur[np.where(dur>=6)];
        if dur.size==0:
          LCS[yidx,xidx]=-9999.0
          CSDI[yidx,xidx]=0
        else:
          CSDI[yidx,xidx]=len(dur)
          LCS[yidx,xidx]=max(dur)

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Write to file
outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(yearchoice) + str(monchoice).zfill(2) + '.nc4'
ncfile = netCDF4.Dataset(outfile, mode='a')

#ncfile = netCDF4.Dataset(outfile, mode='w', format='NETCDF4_CLASSIC')
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
#time_var.units = 'hours since ' + str(yearchoice) + '-' + str(monchoice).zfill(2) + '-01'
#time_var.long_name = 'time'
#time_var[:]=[0]

HWN_var = ncfile.createVariable('HWN','i',('time','lat','lon'),fill_value=-9999)
HWN_var[:]=HWN
HWN_var.units = 'count'
HWN_var.long_name='Heatwave Number (count of events satisfying the heatwave criteria of at least three consecutive days above the 90th percentile)'

HWD_var = ncfile.createVariable('HWD','f',('time','lat','lon'),fill_value=-9999)
HWD_var[:]=HWD
HWD_var.units = 'days'
HWD_var.long_name='Heatwave Duration (length of the longest number of consecutive days satisfying the heatwave criteria of at least three consecutive days above the 90th percentile)'

HWF_var = ncfile.createVariable('HWF','i',('time','lat','lon'),fill_value=-9999)
HWF_var[:]=HWF
HWF_var.units='count'
HWF_var.long_name='Heatwave Frequency (count of days satisfying the heatwave criteria of at least three consecutive days above the 90th percentile)'

HWA_var = ncfile.createVariable('HWA','f',('time','lat','lon'),fill_value=-9999)
HWA_var[:]=HWA
HWA_var.units='K'
HWA_var.long_name='Heatwave Amplitude (daily mean 2-m temperature on hottest day satisfying the heatwave criteria of at least three consecutive days above the 90th percentile)'

HWM_var = ncfile.createVariable('HWM','f',('time','lat','lon'),fill_value=-9999)
HWM_var[:]=HWM
HWM_var.units='K'
HWM_var.long_name='Heatwave Magnitude (average 2-m temperature K anomaly on days satisfying the heatwave criteria of at least three consecutive days above the 90th percentile)'

WSDI_var = ncfile.createVariable('WSDI','i',('time','lat','lon'),fill_value=-9999)
WSDI_var[:]=WSDI
WSDI_var.units='count'
WSDI_var.long_name='warm spell duration index (count when at least 6 consecutive days of max 2-m temperature > 90th percentile)'

LWS_var = ncfile.createVariable('LWS','f',('time','lat','lon'),fill_value=-9999)
LWS_var[:]=LWS
LWS_var.units='days'
LWS_var.long_name='length of longest warm spell of at least 6 consecutive days above the 90th percentile'

CSDI_var = ncfile.createVariable('CSDI','i',('time','lat','lon'),fill_value=-9999)
CSDI_var[:]=CSDI
CSDI_var.units='count'
CSDI_var.long_name='cold spell duration index (count when at least 6 consecutive days of min 2-m temperature < 10th percentile)'

LCS_var = ncfile.createVariable('LCS','f',('time','lat','lon'),fill_value=-9999)
LCS_var[:]=LCS
LCS_var.units='days'
LCS_var.long_name='length of longest cold spell of at least 6 consecutive days below the 10th percentile'

#ncfile.format='NetCDF-4'
#ncfile.Conventions='CF1.7'
#ncfile.SpatialCoverage='Global'
#ncfile.MapProjection='Latitude-Longitude'
#ncfile.SouthernmostLatitude='-90.0'
#ncfile.NorthernmostLatitude='90.0'
#ncfile.WesternmostLongitude='-180.0'
#ncfile.EasternmostLongitude='179.375'
#ncfile.LatitudeResolution='0.5'
#ncfile.LongitudeResolution='0.625'
#ncfile.DataResolution='0.5 x 0.625'
ncfile.close()

