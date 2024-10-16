#!/usr/bin/env python
#module load other/python/GEOSpyD/Ana2019.10_py3.7

import matplotlib.pyplot as plt
from matplotlib import cm
import matplotlib.ticker as mticker
import numpy as np
from netCDF4 import Dataset
from matplotlib.collections import LineCollection
from matplotlib.colors import ListedColormap, BoundaryNorm
import sys
import os
from mpl_toolkits.basemap import Basemap
import cmocean
import matplotlib.gridspec as gridspec
import matplotlib.colors as mcolors
import datetime
from mpl_toolkits.axes_grid1 import make_axes_locatable
from matplotlib import rcParams
import cartopy
from cartopy import util
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import cartopy.io.shapereader as shapereader
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
from matplotlib.colors import BoundaryNorm

yearchoice=int(sys.argv[1])
seaschoice=int(sys.argv[2])
refperiod=sys.argv[3]
outputdir='/discover/nobackup/projects/gmao/nca/indices/ccdi/based_on_' + refperiod[0:4] + '-' + refperiod[4:8] + '/v2.1'
outfile=outputdir + '/MERRA2.statM_2d_edi_Nx.v2_1.' + str(yearchoice) + str(seaschoice).zfill(2) + '.nc4'

fid = Dataset(outfile,'r')
r95p = fid.variables['R95P'][:, :, :]
r95d = fid.variables['R95D'][:, :, :]
wet = fid.variables['wetdays'][:, :, :]
dry = fid.variables['drydays'][:, :, :]
rx5day = fid.variables['RX5Day'][:, :, :]
rx5daycount = fid.variables['RX5Daycount'][:, :, :]
cwd = fid.variables['CWD'][:, :, :]
lon = fid.variables['lon'][:]
lat = fid.variables['lat'][:]

levels=[10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
fig = plt.figure(figsize=(12, 6))
ax1=fig.add_subplot(231, projection=map_projection)
plot_tmp_data=np.squeeze(r95p)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('R95P',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='mm/day',size=12)

levels=[0,1,2,3,4,5,6,7,8,9,10,11,12]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(232, projection=map_projection)
plot_tmp_data=np.squeeze(r95d)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('R95D',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='Count',size=12)

levels=[0,28,29,30,31,32]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(233, projection=map_projection)
plot_tmp_data=np.squeeze(wet+dry)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('Wet Days + Dry Days',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='blank map for days of month',size=12)

levels=[0,15,30,45,60,75,90,105,120,135,150,165,180,195,210,225,240,255,270,285,300]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(234, projection=map_projection)
plot_tmp_data=np.squeeze(rx5day)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('Rx5Day',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='mm per 5 days',size=12)

levels=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(235, projection=map_projection)
plot_tmp_data=np.squeeze(rx5daycount)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('Rx5DayCount',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='Count',size=12)

levels=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
cmap = cmocean.cm.rain
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(236, projection=map_projection)
plot_tmp_data=np.squeeze(cwd)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('CWD',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='Count',size=12)

fig.savefig('qcplots/qc_precipindices_'  + str(yearchoice) + str(seaschoice).zfill(2) + '.png')

tx90p = fid.variables['TX90p'][:, :, :]
tn10p = fid.variables['TN10p'][:, :, :]
hwf = fid.variables['HWF'][:, :, :]
hwm = fid.variables['HWM'][:, :, :]
lws = fid.variables['LWS'][:, :, :]
csdi = fid.variables['CSDI'][:, :, :]

levels=[0,10,20,30,40,50,60,70,80,90,100]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
fig = plt.figure(figsize=(12, 6))
ax1=fig.add_subplot(231, projection=map_projection)
plot_tmp_data=np.squeeze(tx90p)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('TX90p',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='%',size=12)

levels=[0,10,20,30,40,50,60,70,80,90,100]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(232, projection=map_projection)
plot_tmp_data=np.squeeze(tn10p)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('TN10p',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='%',size=12)

levels=[0,1,2,3,4,5]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(233, projection=map_projection)
plot_tmp_data=np.squeeze(csdi)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('CSDI',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='days',size=12)

levels=[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(234, projection=map_projection)
plot_tmp_data=np.squeeze(hwf)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('HWF',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='Count',size=12)

levels=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(235, projection=map_projection)
plot_tmp_data=np.squeeze(hwm)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('HWM',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='K',size=12)

levels=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
cmap = cmocean.cm.matter
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=False)
map_projection = ccrs.PlateCarree()
ax1=fig.add_subplot(236, projection=map_projection)
plot_tmp_data=np.squeeze(lws)
cyclic_data, cyclic_lons = cartopy.util.add_cyclic_point(plot_tmp_data, coord=lon)  #adding cyclic points
im1 = ax1.pcolormesh(cyclic_lons, lat, cyclic_data,cmap=cmap,norm=norm, transform=map_projection)
ax1.coastlines()
#ax1.set_xticks(np.linspace(-180, 180, 5), crs=map_projection)
#ax1.set_yticks(np.linspace(-90, 90, 5),   crs=map_projection)
#ax1.tick_params(axis="x", labelsize=12)
#ax1.tick_params(axis="y", labelsize=12)
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
ax1.xaxis.set_major_formatter(lon_formatter)
ax1.yaxis.set_major_formatter(lat_formatter)
ax1.set_title('LWS',fontsize=14)
ax1.set_global()
cbar1=plt.colorbar(im1, ax=ax1, orientation='horizontal', pad=0.05, extend="max")
cbar1.ax.tick_params(labelsize=12)
cbar1.set_label(label='Count',size=12)

plt.show()
fig.savefig('qcplots/qc_t2mindices_' + str(yearchoice) + str(seaschoice).zfill(2) + '.png')
