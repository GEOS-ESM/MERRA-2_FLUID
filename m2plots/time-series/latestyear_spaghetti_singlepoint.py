#!/usr/bin/env python

import numpy as np
import os.path
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units
import matplotlib.pyplot as plt


####INPUT parameters####
variablename='T2M'
collection='tavgM_2d_slv_Nx'
latinput=39.3
loninput=-76.6
location='Baltimore, MD'
endyear=2023
endmonth=2

####LOAD DATA####
DS = xr.open_mfdataset('/discover/nobackup/projects/gmao/merra2/data/products/MERRA2_all/Y*/M*/MERRA2.' + collection + '.*.nc4')
spatialsubset=DS.sel(lon=loninput,lat=latinput,method="nearest")
climosubset=spatialsubset.sel(time=slice("1991-01-01", "2020-12-01"))
data=climosubset.T2M

####Compute Stats####
varmean=data.groupby("time.month").mean()
pctl85=data.groupby("time.month").quantile(0.85)
pctl15=data.groupby("time.month").quantile(0.15)


####Create Figure####
xaxis=np.arange(1,13,1)
fig, ax = plt.subplots()
ax.fill_between(xaxis,pctl15,pctl85,color='lightgray')
ax.plot(xaxis,varmean)
ax.plot(np.arange(1,endmonth+1,1),spatialsubset.T2M.sel(time=slice(str(endyear) + "-01-01", str(endyear) + "-" + str(endmonth) + "-01")))
plt.show()
