#!/usr/bin/env python

import numpy as np
import os.path
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units
import matplotlib.pyplot as plt
import matplotlib.image as img
import yaml
import warnings
warnings.filterwarnings('ignore')
import sys

#Required command line inputs in order are 1) the variable to be plotted, 2) the region, 3) the year to be highlighted, and 4) the ending month of the year to be highlighted. 
#Example usage: ./latestyear_spaghetti_ncaregions.py t2m ne 2023 12
yamlkey_var=sys.argv[1]
yamlkey_reg=sys.argv[2]
endyear=int(sys.argv[3])
endmonth=int(sys.argv[4])

####INPUT parameters####
#yamlkey_var='t2m'
#yamlkey_reg='ne'
#endyear=2023
#endmonth=12
########################


variable_map = """
wspd10m:
  variablename: 'wspd10m'
  varlongname: '10 m Wind Speed'
  units: '$\mathregular{m\ s^{-1}}$'
  unitconversion: 1

wspd50m:
  variablename: 'wspd50m'
  varlongname: '50 m Wind Speed'
  units: '$\mathregular{m\ s^{-1}}$'
  unitconversion: 1


"""

####Import yaml info####
var = yaml.safe_load(variable_map)
with open('regionmap.yaml') as f:
        region = yaml.safe_load(f)


####LOAD DATA####
DS = xr.open_mfdataset('/discover/nobackup/projects/gmao/merra2/data/pub/supplemental/climatestatistics/wspd/MERRA2_mon_wspd_*.nc')
lon1=region[yamlkey_reg]['lon1']
lon2=region[yamlkey_reg]['lon2']
lat1=region[yamlkey_reg]['lat1']
lat2=region[yamlkey_reg]['lat2']


####Subset for Selected Region####
subset=DS[var[yamlkey_var]['variablename']].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))
ncaregions=xr.open_dataset('/discover/nobackup/acollow/MERRA2/NCA_regs_MERRA-2.nc')
if region[yamlkey_reg]['landonly']==1:
        m2constants=xr.open_dataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_all/MERRA2.const_2d_asm_Nx.00000000.nc4')
        land=m2constants.FRLAND+m2constants.FRLANDICE
        land_subset=land.sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2)).squeeze(['time'],drop=True)
        subset=subset.where(land_subset>0.3)
	
if region[yamlkey_reg]['regionnumber']>0 and region[yamlkey_reg]['regionnumber']<10:
        nca_subset=ncaregions['regs05'].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))
        subset=subset.where(nca_subset==region[yamlkey_reg]['regionnumber'])
elif region[yamlkey_reg]['regionnumber']==10:
        nca_subset=ncaregions['regs05'].sel(lon=slice(lon1,lon2),lat=slice(lat1,lat2))
        subset=subset.where(nca_subset>0)

####Get area average####
weights=np.cos(np.deg2rad(subset.lat))
subset_weighted=subset.weighted(weights)
weighted_mean = var[yamlkey_var]['unitconversion']*subset_weighted.mean(("lon", "lat"))

####Compute Stats####
stats_subset=weighted_mean.sel(time=slice("1980-01-01","2024-12-01"))
climo=stats_subset.groupby("time.month").mean()
minimum=stats_subset.groupby("time.month").min()
maximum=stats_subset.groupby("time.month").max()
pctl15=stats_subset.groupby('time.month').reduce(np.nanpercentile, dim='time', q=15)
pctl85=stats_subset.groupby('time.month').reduce(np.nanpercentile, dim='time', q=85)
#print(weighted_mean.sel(time=slice(str(endyear) + "-01-01", str(endyear) + "-" + str(endmonth) + "-01")))

####Generate Figure####
xaxis=np.arange(1,13,1)
fig, ax = plt.subplots()
ax.tick_params(axis='both', which='major', labelsize=14)
line1=ax.plot(np.arange(1,endmonth+1,1),weighted_mean.sel(time=slice(str(endyear) + "-01-01", str(endyear) + "-" + str(endmonth) + "-01")),'r',label=str(endyear))
line2=ax.plot(xaxis,climo,'k',label="Climo Mean")
line3=ax.fill_between(xaxis,pctl15,pctl85,color='lightgray',label="15th-85th Percentile")
ax.plot(xaxis,minimum,'k',linewidth=0.5)
line4=ax.plot(xaxis,maximum,'k',linewidth=0.5,label="Min/Max")
plt.ylabel(var[yamlkey_var]['varlongname'] + ' (' + var[yamlkey_var]['units'] + ')', fontsize=14)
#ax.legend([str(endyear),"Climo Mean","15th-85th Percentile","Min/Max"])
ax.legend([str(endyear),"Climo Mean (1980-2024)","15th-85th Percentile (1980-2024)","Min/Max (1980-2024)"])
plt.xticks(ticks=np.arange(1,13,1), labels=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
plt.xlim([1,12])
plt.title(region[yamlkey_reg]['region'], fontsize=14, fontweight='bold')
plt.subplots_adjust(left=0.15, right=0.95, bottom=0.1, top=0.9)

####Add GMAO logo and version number
image = img.imread('GMAO-logo-blue-no-text.png')
image_x = 0.04  # Adjust as needed
image_y = 0.85  # Adjust as needed
image_width = 0.2  # Adjust as needed
image_height = 0.2  # Adjust as needed
ax_image = fig.add_axes([image_x, image_y, image_width, image_height])
ax_image.imshow(image)
ax_image.set_xticks([])
ax_image.set_yticks([])
with open("VERSION", "r") as f:
        VERSION = f.read().strip()  # strip will remove leading and trailing whitespace
plt.text(0.95,1.05,VERSION,transform=ax.transAxes)

#plt.show()

month = str(endmonth + 100)[1:]
odir = '/discover/nobackup/dao_ops/m2plots/Y{}/M{}'.format(endyear, month)
oname = '%s_%s_%4d.png'%(var[yamlkey_var]['variablename'],region[yamlkey_reg]['regionshortname'],endyear)
opathname = os.path.join(odir, oname)
os.makedirs(odir, mode = 0o755, exist_ok=True)
fig.savefig(opathname)
