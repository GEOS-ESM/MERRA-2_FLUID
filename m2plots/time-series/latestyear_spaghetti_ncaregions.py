#!/usr/bin/env python

import sys
import yaml
import warnings

import numpy as np
import os.path
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.image as img
from matplotlib.ticker import MaxNLocator

from m2plots import *
from userinterface import *

warnings.filterwarnings('ignore')

#------------------------------------------------------------------------------


def plot(var, region, year, month, stream, config):
    """
    Draws MERRA-2 Time-Series Plots
    
    Parameters
    ----------
    var: string
        The variable to be plotted.
    region: string
        The region to be plotted.
    year: int
        The year to be highlighted.
    month: int
        The ending month of the year to be highlighted.
    stream: string
        The stream type being used to plot.
            ops: operational
            retro: retrospective
    cfg: string
        The name of configuration file containing definitions.
    
    Returns
    -------
    None
    
    """

    yamlkey_var=var
    yamlkey_reg=region
    endyear=year
    endmonth=month
    yamlkey_stream=stream
    config_file=config
    
    ####Import yaml info####
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    region = config['region_map']
    stream = config['stream_map']
    var = config['variable_map']
    logo = config['logo']

    ####LOAD DATA####
    DS = xr.open_mfdataset('/discover/nobackup/projects/gmao/merra2/data/products/' + stream[yamlkey_stream]['streamname'] + '/Y*/M*/' + stream[yamlkey_stream]['model'] + '.' + var[yamlkey_var]['collection'] + '.*.nc4')
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
    line2=ax.plot(xaxis,climo,'k',label="Climo Mean (1980-2024)")
    line3=ax.fill_between(xaxis,pctl15,pctl85,color='lightgray',label="15th-85th Percentile")
    ax.plot(xaxis,minimum,'k',linewidth=0.5)
    line4=ax.plot(xaxis,maximum,'k',linewidth=0.5,label="Min/Max")
    plt.ylabel(var[yamlkey_var]['varlongname'] + ' (' + var[yamlkey_var]['units'] + ')', fontsize=14)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))
    ax.legend([str(endyear),"Climo Mean (1980-2024)","15th-85th Percentile (1980-2024)","Min/Max (1980-2024)"])
    plt.xticks(ticks=np.arange(1,13,1), labels=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
    plt.xlim([1,12])
    plt.title(region[yamlkey_reg]['region'], fontsize=14, fontweight='bold')
    plt.subplots_adjust(left=0.15, right=0.95, bottom=0.1, top=0.9)
    
    
    ####Add GMAO logo and version number
    image = img.imread(logo)
    image_x = 0.04  # Adjust as needed
    image_y = 0.85  # Adjust as needed
    image_width = 0.2  # Adjust as needed
    image_height = 0.2  # Adjust as needed
    ax_image = fig.add_axes([image_x, image_y, image_width, image_height])
    ax_image.imshow(image)
    ax_image.set_xticks([])
    ax_image.set_yticks([])
    plt.text(0.95,1.05,VERSION,transform=ax.transAxes)
    
    #plt.show()
    
    month = str(endmonth + 100)[1:]
    odir = stream[yamlkey_stream]['outputpath'] + 'Y{}/M{}'.format(endyear, month)
    os.makedirs(odir, mode = 0o755, exist_ok=True)
    fig.savefig(odir+'/'+'%s_%s_%4d.png'%(var[yamlkey_var]['variablename'],region[yamlkey_reg]['regionshortname'],endyear))

#------------------------------------------------------------------------------


if __name__ == "__main__":

    # Get command-line arguments

    ui = UserInterface('Time Series Plots')
    args = ui.get_args()

    plot(args.var, args.region, args.year, args.month, args.stream, args.config)
