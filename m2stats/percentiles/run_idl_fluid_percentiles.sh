#!/usr/local/bin/bash


# This script calls an IDL code (fluid_git.pro) with the parameters defined below. Both codes may be in the same directory for convenience. 
# The IDL code reads MERRA-2 data at discover and generates various outputs (climatology, anomalies, percentiles, etc) in netcdf-4 format.
# But this shell script is specifically written to generate monthly and seasonal percentile files for FLUID and GES-DISC.
# Written and maintained by Amin Dezfuli, 2015.

# ===========================================================================================================
# ================================ User changes (for routine monthly file creation) =========================
#dirOut='/path/to/store/output/ncdf/' #  Path to store nc4 outputs
dirOut='/discover/nobackup/acollow/MERRA-2_FLUID/m2stats/percentiles/'
mon_or_sea=1  # 0: for seasonal percentiles; 1: for monthly. 
              # More details ... 1: to override 'fm' and 'lm' with values from 'months', and repeat for all its values. In this case, fm=lm. 0: to set values for 'fm' and 'lm' manually below.
months=2 # Set this for monthly percentiles.
         # !!!! CAUTION !!!! ******* 0: JAN, 1: FEB, ..., 11: DEC. ********
# For seasonal set fm and lm:
fm=0 # First month (0: JAN, 1: FEB, ..., 11: DEC)
lm=2  # Last month (0: JAN, 1: FEB, ..., 11: DEC)
      # NOTE: If fm NE lm, a seasonal average will be calculated. If you want to generate files for each month separately, then MonAutoLoop=1 and set the values of interest for "months" variable.
      # In this case, nm will be set to 1, just in case the fm and lm values here have different values.
      # When fm > lm and MonAutoLoop=0, then (year-1) is used for the months between fm and Dec. E.g., in LTM calculations, if fy=1981, ly=2010, fm=11, lm=1, then the first data is for Dec-1980/Jan-1981/Feb/1981, and
      # the last one is  Dec-2009/Jan-2010/Feb/2010. Similar approach is used for percentile calculations of individual years.
      # Similarly, for routine seasonal files if we want to generate, NDJ (where Nov-2021, Dec-2021, Jan-2022) then we will set fm=10 & lm=0 & fy=2022 & ly=2022.

fy=2025 # First year
ly=2025 # Last year 
# ================================ END OF User changes (for routine monthly file creation) ==================
# ===========================================================================================================






# ===========================================================================================================
# ============================================= NO CHANGES HERE =============================================
export DIROUT=$dirOut
export MON_OR_SEA=$mon_or_sea
export MONTHS=$months
export FM=$fm
export LM=$lm
export FY=$fy
export LY=$ly

# Run IDL with command-line arguments
idl -e "percentilesforFLUID"
# ============================================= END OF NO CHANGES HERE ======================================
# ===========================================================================================================

