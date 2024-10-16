#!/usr/bin/env python

import numpy as np
import os.path
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units
import matplotlib.pyplot as plt


####INPUT parameters####
variablename='T2MMAX'
varlongname='Daily Max 2 m Temperature'
units='K'
collection='statD_2d_slv_Nx'
lat1=29.5
lat2=32
lon1=-98
lon2=-95
#lat1=25
#lat2=50
#lon1=-125
#lon2=-65
region='SE Texas'
endyear=2024
endmonth=5
endday=
landonly=1
ncaregion=0
unitconversion=1

####LOAD DATA####
DS = xr.open_mfdataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_all/Y*/M05/MERRA2.' + collection + '.*.nc4')
ncaregions=xr.open_dataset('/discover/nobackup/acollow/MERRA2/NCA_regs_MERRA-2.nc')
m2constants=xr.open_dataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_all/MERRA2.const_2d_asm_Nx.00000000.nc4')
subset=DS[variablename].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))
DS2024 = xr.open_mfdataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_400/Y2024/M05/MERRA2.' + collection + '.*.nc4')
subset2024=DS2024[variablename].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))


if landonly==1:
	land=m2constants.FRLAND+m2constants.FRLANDICE
	land_subset=land.sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2)).squeeze(['time'],drop=True)
	subset=subset.where(land_subset>0.3)
	
if ncaregion>0:
	nca_subset=ncaregions['regs05'].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))
	subset=subset.where(nca_subset==ncaregion)

####Get area average####
weights=np.cos(np.deg2rad(subset.lat))
#normalizedweights=(weights - np.min(weights)) / (np.max(weights) - np.min(weights))
subset_weighted=subset.weighted(weights)
weighted_mean = unitconversion*subset_weighted.mean(("lon", "lat"))

####Compute Stats####
climo=weighted_mean.groupby("time.dayofyear").mean()
minimum=weighted_mean.groupby("time.dayofyear").min()
maximum=weighted_mean.groupby("time.dayofyear").max()
pctl15=weighted_mean.groupby('time.dayofyear').reduce(np.nanpercentile, dim='time', q=15)
pctl85=weighted_mean.groupby('time.dayofyear').reduce(np.nanpercentile, dim='time', q=85)
#print(weighted_mean.sel(time=slice(str(endyear) + "-01-01", str(endyear) + "-" + str(endmonth) + "-01")))

####Generate Figure####
xaxis=np.arange(1,32,1)
fig, ax = plt.subplots()
line1=ax.plot(np.arange(1,endmonth+1,1),weighted_mean.sel(time=slice(str(endyear) + "-01-01", str(endyear) + "-" + str(endmonth) + "-01")),'r',label=str(endyear))
line2=ax.plot(xaxis,climo,'k',label="Climo Mean")
line3=ax.fill_between(xaxis,pctl15,pctl85,color='lightgray',label="15th-85th Percentile")
ax.plot(xaxis,minimum,'k',linewidth=0.5)
line4=ax.plot(xaxis,maximum,'k',linewidth=0.5,label="Min/Max")
plt.ylabel(varlongname + ' (' + units + ')')
plt.xlabel('May')
ax.legend([str(endyear),"Climo Mean","15th-85th Percentile","Min/Max"])
#plt.xticks(ticks=np.arange(1,13,1), labels=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
plt.xlim([1,31])
#plt.title(region + ' (Lon = ' + str(lon1) + ' to ' + str(lon2) + ', Lat = ' + str(lat1) + ' to ' + str(lat2) + ')')
plt.title(region)
plt.show()

fig.savefig('%s_%s_%4d.png'%(variablename,region,endmonth))
