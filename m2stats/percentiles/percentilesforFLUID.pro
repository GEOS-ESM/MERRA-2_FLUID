PRO fluid_git
FORWARD_FUNCTION TIME_SER, DATES_MON


; This program reads MERRA-2 data at discover and generates various outputs (climatology, anomalies, percentiles, etc) in netcdf-4 format.
; Written and contineously modified by Amin Dezfuli



; -------------------------- set up for common cases: ------------------------
; MONTHLY:
; To create MERRA2.tavgC_3d_ltm_Np.1981MM_2010MM.nc4, set combVarYN=1; FixPer=3; subSet=0; ncdfYN= 1; force2D=0; MonAutoLoop= 1
;                                                  var_indAll= [0, 1, 2, 3, 4, 5, 6, 9]; Xprs= [1000., 925., 850., 700., 600., 500., 400., 300., 200., 100., 30., 10.]
; To create MERRA2.tavgC_2d_ltm_Nx.1981MM_2010MM.nc4, set combVarYN=1; FixPer=3; subSet=0; ncdfYN= 1; force2D=1; MonAutoLoop= 1
;                                                  var_indAll= [14, 15, 16, 23]; Xprs=[20000, 20000, 20000, 20000]
; To create MERRA2.statM_2d_pct_Nx.YYYYMM.nc4, set ltmPer=1; combVarYN=1; FixPer=2; subSet=0; ncdfYN= 1; force2D=1; MonAutoLoop= 1
;                                                  var_indAll= [14, 15, 16, 23]; Xprs=[20000, 20000, 20000, 20000]
; SEASONAL:                                                 
; To create MERRA2.tavgS_2d_ltm_Nx.1981MM_2010MM.nc4, set combVarYN=1; FixPer=3; subSet=0; ncdfYN= 1; force2D=1; MonAutoLoop= 0
;                                                  var_indAll= [14, 15, 16, 23]; Xprs=[20000, 20000, 20000, 20000]
;                                                  Note: fm=0, lm=2 used for JFM, ..., fm=11, lm=1 for DJF. Each of this 12 cases should be set separately. The file name includes the last month of the season, e.g.,
;                                                  MERRA2.tavgS_2d_ltm_Nx.198101_201001.nc4 for NDJ, where for 1981, Nov and Dec are taken from 1980 and Jan from 1981. For, JFM, ..., OND data from the same year, i.e., 1981 is used. 
; To create MERRA2.statS_2d_pct_Nx.YYYYMM.nc4, set ltmPer=1; combVarYN=1; FixPer=2; subSet=0; ncdfYN= 1; force2D=1; MonAutoLoop= 0
;                                                  var_indAll= [14, 15, 16, 23]; Xprs=[20000, 20000, 20000, 20000]                                            
;                                                  Note: fm=0, lm=2 used for JFM, ..., fm=11, lm=1 for DJF. Each of this 12 cases should be set separately. The file name includes the last month of the season, e.g.,
;                                                  MERRA2.statM_2d_pct_Nx.200001.nc4 for Nov(1999)-Dec(1999)-Jan(2000), but for *200003.nc4, the seasonal mean JFM 2000 is used.
; ----------------------------------------------------------------------------

dirOut = getenv('DIROUT')
MonAutoLoop = fix(getenv('MON_OR_SEA'))
months = fix(getenv('MONTHS'))
fm = fix(getenv('FM'))
lm = fix(getenv('LM'))
fy = fix(getenv('FY'))
ly = fix(getenv('LY'))

PRINT, dirOut
PRINT, 'MonAutoLoop:', MonAutoLoop
PRINT, 'Months:', months
PRINT, 'fm:', fm, ' lm:', lm
PRINT, 'fy:', fy, ' ly:', ly

;stop


;; ===========================================================================================================
;; ================================ User changes (for routine monthly file creation) =========================
; Path to store nc4 outputs:
;dirOut= '/discover/nobackup/adezfuli/tmp/'
;dirOut= '/discover/nobackup/adezfuli/pub/M2pctMon_based_on_1981-2010_GESDISC/'

;MonAutoLoop=1 ; 0: for seasonal percentiles; 1: for monthly. 
;              ; NOTE, 1: to override 'fm' and 'lm' with values from 'months', and repeat for all its values. In this case, fm=lm. 0: to set values for 'fm' and 'lm' manually below.
;months= 1 ; Set this for monthly percentiles.
;          ; ******* 0: JAN, 1: FEB, ..., 11: DEC. ********
;          ; This can be a single value (e.g., month=[0]) or an array (month=[0, 2, 7]), used for 'fm' and 'lm'.
;fm=11 & lm=1 ; Set this for seasonal percentiles. See examples below.
;             ; NOTE: If fm NE lm, a seasonal average will be calculated. If you want to generate files for each month separately, then MonAutoLoop=1 and set the values of interest for "months" variable.
;             ; In this case, nm will be set to 1, just in case the fm and lm values here have different values.
;             ; When fm > lm and MonAutoLoop=0, then (year-1) is used for the months between fm and Dec. E.g., in LTM calculations, if fy=1981, ly=2010, fm=11, lm=1, then the first data is for Dec-1980/Jan-1981/Feb/1981, and
;             ; the last one is  Dec-2009/Jan-2010/Feb/2010. Similar approach is used for percentile calculations of individual years.
;             ; Similarly, for routine seasonal files if we want to generate, NDJ (where Nov-2021, Dec-2021, Jan-2022) then we will set fm=10 & lm=0 & fy=2022 & ly=2022.
;fy=2025 & ly=2025 ; First/last month/year of the baseline period for statistics calculations (e.g., PDF).
;; If number of months is greater than one, the percentile calculations will be done using the average of seasonal precipitation.
;; Percentiles vary over [0, 1).
;; ================================ END OF User changes (for routine monthly file creation) ==================
;; ===========================================================================================================




; ===========================================================================================================
; ================================ User changes (less frequent, just needed for major updates) ==============
ltmPer=1     ; 0: to use 1981-2010 period for calculation of monthly/seasonal percentiles and anomalies. 
             ; 1: to use 1991-2020 period ...

combVarYN=1  ; 0: To generate one percentile file for each variable/year/month. Set 1 to put all variables in one file.

FixPer=2     ; 0: To calculate the actual values, anomalies and percentiles for a period defined by fy, ly, fm, lm. The outputs are similar to those of FixPer=2, 
             ;    but calculated online based on a user-defiend period rather than the baseline period (1981-2010 or 1991-2020). The actual values are directly read from MERRA-2 collections on Discover.
             ; 1: To calculate the LTM, SD and percentiles for a fixed baseline period (1981-2010 or 1991-2020). LTM and SD are stored in one file (e.g., clim_1981_2010_xx), 
             ;    and percentiles and their corresponding values in another file (e.g., perc_1981_2010_xx). 
             ; 2: To calculate the actual values, anomalies and percentiles for a given month/year by comparing it to the values "already" stored in a file resulted from FixPer=1 or FixPer=. 
             ;    The percentile for any new year (e.g., 2022) will be computed by linear interpolation using the nearest values of the variable
             ;    in the baseline period. If the new value is less than (or equal to) the 0th percentile, it will be set to 0, and if it is greater than the
             ;    maximum percentile value (e.g., corresponding to 96.67%) it will be set to 100%. Values GT than perc(i) and LE perc(i+1) will be set to perc(i+1).
             ;    The actual values are directly read from MERRA-2 collections on Discover; anomalies are calculated using LTM from climatology files created before using FixPer=1.
             ; 3: To calculate the LTM and SD for a fixed baseline period (1981-2010 or 1991-2020). It's similar to FixPer=1, but different in that the file contains different pressure levels and multiple variables.
             ;    There will be one file for each month, similar to MERRA-2 format.   

subSet=0 ; set 1 to subset a number of variables defiend in var_indAll, and store them in a netcdf file. When set 1, then FixPer will be ignored. For daily data, there will be one file for each year for all variables. 
         ; It's been tested with MonAutoLoop=1, so months and years are defined by 'months', 'fy', and 'ly'. For now it works only with force2D=1.

ncdfYN= 1 ; 1: to create NetCDF-4 files for storing the outputs.

var_indAll= [14, 15, 16, 23] ; [0, 1, 2, 3, 4, 5, 6, 9]; [0, 1, 6, 0, 1, 6, 0, 1, 6, 23, 24, 28, 29, 30, 31, 100, 96, 97, 98, 17, 18, 19, 20, 21, 22, 10, 11, 12, 14, 15, 16, 39, 42] ; [13, 14, 15, 23, 24, 30, 64] ;[0, 1, 6, 0, 1, 6, 0, 1, 6, 23, 24, 28, 29, 30, 31, 100, 96, 97, 98, 17, 18, 19, 20, 21, 22, 10, 11, 12, 14, 15, 16, 39, 42];[0, 1, 2, 3, 4, 5, 6, 9]; for 3D ; Index of variable of interest to be read from MERRA2 files. List of available variables can be obtained by setting showListVars=1.
           ; [0, 1, 2, 3, 4, 5, 6, 9] for 3D with Xprs= [1000., 925., 850., 700., 600., 500., 400., 300., 200., 100., 30., 10.]
           ;[0, 1, 6, 0, 1, 6, 0, 1, 6, 23, 24, 28, 29, 30, 31, 100, 96, 97, 98, 17, 18, 19, 20, 21, 22, 10, 11, 12, 14, 15, 16, 39, 42] ; for 2D with Xprs=[replicate(850,3), replicate(500,3), replicate(200,3), replicate(20000., 24)]
           ; [14, 15, 16, 23]
           ; [14, 15, 16, 23, 24]
           ;[14, 23, 24] ; for current version of FLUID monthly precentile updates (one file per variable/year)
           ; 0:U, 1:V, 2:OMEGA, 3:T, 4:QV, 5:RH, 6:H, 7:Var_T, 8:Var_U, 9:Var_V, 10:SLP, 11:PS, 12:TS, 13:T2MWET, 14:T2MMEAN, 15:T2MMAX, 16:T2MMIN,
           ; 17:U2M, 18:V2M, 19:U10M, 20:V10M, 21:U50M, 22:V50M, 23:PRECTOT, 24:PRECTOTCORR, 25:PRECCON, 26:PRECCUCORR, 27:GWETPROF, 28:GWETROOT, 29:GWETTOP, 30:EVAP, 31:EVLAND,
           ; 32:LWGAB, 33:LWGABCLR, 34:LWGABCLRCLN, 35:LWGEM, 36:LWGNT, 37:LWGNTCLR, 38:LWGNTCLRCLN, 39:LWTUP, 40:LWTUPCLR, 41:LWTUPCLRCLN, 42:SWGDN, 43:SWGDNCLR, 44:SWGNT, 45:SWGNTCLN, 46:SWGNTCLR,
           ; 47:SWGNTCLRCLN, 48:SWTDN, 49:SWTNT, 50:SWTNTCLN, 51:SWTNTCLR, 52:SWTNTCLRCLN, 53:DTDTLWR, 54:DTDTLWRCLR, 55:DTDTSWR, 56:DTDTSWRCLR, 57:DTDTSWLWRCLR, 58:DUCMASS, 59:DUEXTTAU, 60:DUSCATAU, 61:DUCMASS25,
           ; 62:DUEXTT25, 63:DUSCAT25, 64:DUSMASS, 65:DUFLUXU, 66:DUFLUXV, 67:BCCMASS, 68:BCEXTTAU, 69:BCSCATAU, 70:BCSMASS, 71:BCFLUXU, 72:BCFLUXV, 73:OCCMASS, 74:OCEXTTAU, 75:OCSCATAU, 76:OCSMASS,
           ; 77:OCFLUXU, 78:OCFLUXV, 79:SO4CMASS, 80:SUEXTTAU, 81:SUSCATAU, 82:SO4SMASS, 83:SUFLUXU, 84:SUFLUXV, 85:SSCMASS, 86:SSEXTTAU, 87:SSSCATAU, 88:SSCMASS25, 89:SSEXTT25, 90:SSSCAT25, 91:SSSMASS,
           ; 92:SSFLUXU, 93:SSFLUXV, 94:TOTEXTTAU, 95:TOTSCATAU, 96:UFLXQV, 97:VFLXQV, 98:TQV, 99:wind10m, 100:EMP, 101:wspd10m

;;;[99, 19, 20];100, 30, 23];14, 23];
;Xprs= [1000., 925., 850., 700., 600., 500., 400., 300., 200., 100., 30., 10.] ; Pressure level(s) for 3D variables. Set 20000 for 2D variables. If more than one level is chosen (e.g., Xprs=[850, 500]), the NetCDF output file would include data for each level, separately (i.e., no averaging over levels).
      ;[replicate(850.,3), replicate(500.,3), replicate(200.,3), replicate(20000., 24)] ; for 2D
Xprs= [20000, 20000, 20000, 20000];, 20000, 20000, 20000] 
           ; All pressure levels in MERRA-2:
           ; [1000.0000, 975.00000, 950.00000, 925.00000, 900.00000, 875.00000, 850.00000, 825.00000, 800.00000, 775.00000, 750.00000, 725.00000, 700.00000, 650.00000]
           ;  600.00000, 550.00000, 500.00000, 450.00000, 400.00000, 350.00000, 300.00000, 250.00000, 200.00000, 150.00000, 100.00000, 70.000000, 50.000000, 40.000000, $
           ;  30.000000, 20.000000, 10.000000, 7.0000000, 5.0000000, 4.0000000, 3.0000000, 2.0000000, 1.0000000, .69999999, .50000000, .40000001, .30000001, .10000000]

force2D=1 ; Set 1 if you need to include 3D variables on a single level and thus store them as 2D (e.g., U850, H500, etc). Then there should be a one-to-one corresponding between Xprs and var_indAll. For example, if you want
          ; to have a 2D file that includes U850, H500, PRECTOT, and T2MMEAN, then var_indAll=[0, 6, 23, 14], Xprs=[850, 500, 20000, 20000], and force2D=1.



_day_mon= 'mon' ; Set 'day' or 'mon' to calculate the percentiles based on daily or monthly values, respectively. Set 'ensoMon' for El Nino/La Nina cases using monthly data, and 'ensoDay' 
                 ; for using daily data. For _day_mon= 'ensoMon', set fy=1980 & ly=2016, and either fm=9 & lm=11 for OND or fm=0 & lm=2 for JFM. The entire period is used for LTM and sd calculations.

showListVars=0 ; Set 1 to see the list of variables. Useful when you don't know the name of variables. Set 0, when you already know the name of variable of interest.

thresh= 1. ; .1 ; A threshold (mm/hr) used to count dry days. Daily rainfall rate less than or equal to this are considered as nearly no rain days. 
           ; This is defined here in mm/hr for convinience, but will be converted to "kg m-2 s-1" when compared with MERRA precip data. 

validValPerThr=75 ; If more than validValPerThr percent of years have valid values then take this grid as a valid value and later do averaging etc on the those values, otherwise fill this grid with missing value.
                 ; Give a value between 0 and 100, e.g., 25 for 25%. 
; ================================ END OF User changes =======================================================
; ===========================================================================================================







; ============================================================================================================
; ================================ No changes ================================================================
;amon= ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
amon= ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
amon1= ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
amon2=['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']


n_prs = N_ELEMENTS(Xprs)
month_len= [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] ; number of days in each month

ny= ly-fy+1 ; Number of years
IF fm LE lm THEN nm=lm-fm+1 ELSE nm=13-fm+lm ; Number of month
yrs=indgen(ny)+fy

seaName=''
FOR im=0, nm-1 DO IF im+fm LT 12 THEN seaName=seaName+amon2[im+fm] ELSE seaName=seaName+amon2[im+fm-12]

IF _day_mon EQ 'ensoMon' OR _day_mon EQ 'ensoDay' THEN BEGIN
  ; List of ENSO events that are identified based on ERSST during ONDJFM season, over Nino 3.4 region.
  ; http://origin.cpc.ncep.noaa.gov/products/analysis_monitoring/ensostuff/ONI_v5.php
  elninoYrs= [1982, 1986, 1987, 1991, 1994, 1997, 2002, 2004, 2006, 2009, 2014, 2015] ; List of El Nino years. Each year represents an event that starts in OND and continues to JFM of the next year.
                                                                                      ; For example, 1982 represents the 1982-1983 El Nino.                                                                                    
  laninaYrs= [1983, 1984, 1988, 1995, 1998, 1999, 2000, 2005, 2007, 2008, 2010, 2011] ; List of La Nina years.
  
;  elninoYrs= [1982, 1991, 1997, 2009, 2015] ; List of STRONG El Nino years. Each year represents an event that starts in OND and continues to JFM of the next year.
;  ; For example, 1982 represents the 1982-1983 El Nino.
;  laninaYrs= [1988, 1998, 1999, 2007, 2010] ; List of STRONG La Nina years.

  IF NOT(fy EQ 1980 AND ly EQ 2016 AND ((fm EQ 9 AND lm EQ 11) OR (fm EQ 0 AND lm EQ 2))) THEN BEGIN
    print, '********** Are you sure the dates are correctly set for ENSO cases? **********' & stop
  ENDIF
  
  n_elninoYrs=n_elements(elninoYrs)
  n_laninaYrs=n_elements(laninaYrs)
  
  elninoYrsInd=intarr(n_elninoYrs)
  laninaYrsInd=intarr(n_laninaYrs)
  
  FOR iEl=0, n_elninoYrs-1 DO elninoYrsInd[iEl]=where(yrs EQ elninoYrs[iEl])
  FOR iLa=0, n_laninaYrs-1 DO laninaYrsInd[iLa]=where(yrs EQ laninaYrs[iLa])
  
  IF fm EQ 0 AND lm EQ 2 THEN BEGIN
    elninoYrsInd=elninoYrsInd+1 & laninaYrsInd=laninaYrsInd+1 ; Because JFM uses the months of the following year defined in elninoYrs and laninaYrs.
    _ond_jfm= 'JFM'
  ENDIF ELSE _ond_jfm= 'OND'
ENDIF


; Path to read MERRA2 data
dirMain= '/discover/nobackup/projects/gmao/merra2/data/products/'

; Path to read my stored nc4 files:
dirNC4= '/discover/nobackup/adezfuli/pub/'
;dirNC4= '/discover/nobackup/adezfuli/'

IF ltmPer EQ 0 THEN BEGIN ; to use 1981-2010 period for calculation of monthly/seasonal percentiles and anomalies. 
  fyFnLTMread='1981' & lyFnLTMread='2010'
ENDIF ELSE BEGIN ; to use 1991-2020 ...
  fyFnLTMread='1991' & lyFnLTMread='2020'
ENDELSE


; ------------------------------------------ List of MERRA-2 variables -----------------------------------------------------------
; Some variables such as 'wind10m' are calculated using other variabl(s) in MERRA-2, and thus are named in this script. The rest use names given in MERRA-2 collections (e.g., 'U', T2M', 'H', etc).  
; Names of radiation variables in MERRA-2:
RadVars=['LWGAB', 'LWGABCLR', 'LWGABCLRCLN', 'LWGEM', 'LWGNT', 'LWGNTCLR', 'LWGNTCLRCLN', 'LWTUP', 'LWTUPCLR', 'LWTUPCLRCLN', 'SWGDN', 'SWGDNCLR', 'SWGNT', 'SWGNTCLN', 'SWGNTCLR', $
         'SWGNTCLRCLN', 'SWTDN', 'SWTNT', 'SWTNTCLN', 'SWTNTCLR', 'SWTNTCLRCLN']

; Names of temperature tendency variables:
tempTend=['DTDTLWR', 'DTDTLWRCLR', 'DTDTSWR', 'DTDTSWRCLR', 'DTDTSWLWRCLR'] ; seems these are available only on 3D files and not 2D (surface).

; Names of aerosols variables:
AerVars=['DUCMASS', 'DUEXTTAU', 'DUSCATAU', 'DUCMASS25', 'DUEXTT25', 'DUSCAT25', 'DUSMASS', 'DUFLUXU', 'DUFLUXV', 'BCCMASS', 'BCEXTTAU', 'BCSCATAU', 'BCSMASS', $
         'BCFLUXU', 'BCFLUXV', 'OCCMASS', 'OCEXTTAU', 'OCSCATAU', 'OCSMASS', 'OCFLUXU', 'OCFLUXV', 'SO4CMASS', 'SUEXTTAU', 'SUSCATAU', 'SO4SMASS', 'SUFLUXU', $
         'SUFLUXV', 'SSCMASS', 'SSEXTTAU', 'SSSCATAU', 'SSCMASS25', 'SSEXTT25', 'SSSCAT25', 'SSSMASS', 'SSFLUXU', 'SSFLUXV', 'TOTEXTTAU', 'TOTSCATAU']

; Names of Vertically Integrated Diagnostics (VID) variables from tavg1_2d_int_Nx (M2T1NXINT): (seems these are available at 1-hourly only and not monthly)
vidVars=['UFLXQV', 'VFLXQV'] ; !!!!! UPDATE strarr(14) IN var_name IF MORE VARIABLES ARE ADDED !!!!!

; Names of 2M variables:
vars2M=['T2MMEAN', 'T2MMAX', 'T2MMIN']
         
         
var_name= ['U', 'V', 'OMEGA', 'T', 'QV', 'RH', 'H', 'Var_T', 'Var_U', 'Var_V', 'SLP', 'PS', 'TS', 'T2MWET', vars2M, 'U2M', 'V2M', 'U10M', 'V10M', 'U50M', 'V50M', $
           'PRECTOT', 'PRECTOTCORR', 'PRECCON', 'PRECCUCORR', 'GWETPROF', 'GWETROOT', 'GWETTOP', 'EVAP', 'EVLAND', $
           RadVars, tempTend, AerVars, vidVars, 'TQV', 'wind10m', 'EMP', 'wspd10m']

; ---------- List of MERRA-2 2D variables ---------       
list2DVars=['PS', 'TS', 'T2MWET', vars2M, 'U2M', 'V2M', 'U10M', 'V10M', 'U50M', 'V50M', $
            'PRECTOT', 'PRECTOTCORR', 'PRECCON', 'PRECCUCORR', 'GWETPROF', 'GWETROOT', 'GWETTOP', 'EVAP', 'EVLAND', $
            RadVars, AerVars, vidVars]

;------------ Long-name of variables -------------------------------------------------------------
; Names used in long_name attributes of NetCDF outputs. These MUST correspond to entries in Var_Name.
varLongNames=[strarr(13), '2m-temperature', strarr(4), '10m-U wind', '10m-V wind', '50m-U wind', '50m-V wind', 'precipitation', 'precipitation', 'precipitation', 'precipitation', $
              strarr(73), '10m-wind', 'evaporation minus precipitation', 'wspd 10m using sub-daily data'] 


;---------
IF force2D EQ 1 THEN XprsTmp=Xprs

nm_NCDF= n_elements(months) ; number of months to be looped for NetCDF 4 files generation.
iMonLoop=0

IF MonAutoLoop EQ 1 THEN BEGIN
  DO_LOOP_mon: $

  fm= months[iMonLoop]
  lm= months[iMonLoop]
  nm=1 ; Force nm=1 so it won't average over a season defined by the original fm and lm at the top of the script.
ENDIF


IF MonAutoLoop EQ 1 OR fm EQ lm THEN BEGIN ; write the months in 2-digit format between 1-12.
  IF fm LT 9 THEN mo0= string('0', fm+1, format='(a1, i1)') ELSE mo0= string(fm+1, format='(i2)')
  C_or_S='C_' ; to be used for reading/writing 'ltm' and 'pct' monthly vs. seasonal files. 
ENDIF ELSE IF MonAutoLoop EQ 0 THEN BEGIN ; for seasonal files
  IF lm LT 9 THEN mo0= string('0', lm+1, format='(a1, i1)') ELSE mo0= string(lm+1, format='(i2)')
  C_or_S='S_'
ENDIF
;---------




;---------------------------
nVar=n_elements(var_indAll)
iVar=0
DO_LOOP_var: $
var_ind=var_indAll[iVar]

varName=var_name[var_ind] ; variable name

ndaysAll=0

IF force2D EQ 1 THEN BEGIN
  Xprs=XprsTmp[iVar]
  n_prs=n_elements(Xprs)
  prsChrLen=strlen(Xprs[0])
  ipr1=0 & WHILE fix(Xprs[0]/10^ipr1) NE 0. DO ipr1++ & prsChrLen=ipr1
  prs2D=string(Xprs[0], format='(i'+string(prsChrLen, format='(i1)')+')')
  IF Xprs[0] NE 20000 THEN varNameOut=var_name[var_ind]+prs2D ELSE varNameOut=varName
ENDIF ELSE varNameOut=varName
;---------------------------

verb0=varLongNames[var_ind]

; ---------- Determine collection of variable -----
iAerVar= where(var_name[var_ind] EQ AerVars)
iRadVar= where(var_name[var_ind] EQ RadVars)
iTTVar= where(var_name[var_ind] EQ tempTend)
ividVar= where(var_name[var_ind] EQ vidVars)
i2mVar= where(var_name[var_ind] EQ vars2M)
i2Dvars=where(var_name[var_ind] EQ list2DVars)

IF i2Dvars GE 0 OR (n_prs EQ 1 AND Xprs[0] EQ 20000) THEN _2d_3d='2d' ELSE _2d_3d='3d' ; is it 2D or 3D?
print, '***** Variable: ', varName, ' *****'


; ----------- Assign group, freq, etc of the variable to be used in finding the right file name --------------------
IF _2d_3d EQ '2d' THEN BEGIN
  IF i2mVar GE 0 THEN _time= 'stat' ELSE _time= 'tavg' ; tavg (time-average), cnst (time-independent), inst (instantaneous), stat (statistics). Choose 'tavg' for precip, 'stat' for T2M.
  _HV='Nx'
  
  IF _day_mon EQ 'mon' OR _day_mon EQ 'ensoMon' THEN _freq='M' ELSE IF i2mVar GE 0 THEN _freq='D' ELSE _freq='1'
  IF iAerVar GE 0 THEN _group='aer' ELSE IF (var_name[var_ind] EQ 'PRECTOT' OR var_name[var_ind] EQ 'PRECTOTCORR' OR var_name[var_ind] EQ 'PRECCON' OR var_name[var_ind] EQ 'PRECCUCORR' OR $
    var_name[var_ind] EQ 'EVAP' OR var_name[var_ind] EQ 'EMP') THEN _group='flx' ELSE IF iRadVar GE 0 THEN _group='rad' ELSE IF (ividVar GE 0 OR var_name[var_ind] EQ 'IVT_tot_2D') THEN _group='int' $
    ELSE IF (var_name[var_ind] EQ 'GWETPROF' OR var_name[var_ind] EQ 'GWETROOT' OR var_name[var_ind] EQ 'GWETTOP' OR var_name[var_ind] EQ 'EVLAND') THEN _group='lnd' $
    ELSE IF (i2mVar GE 0) THEN _group='slv' ELSE _group='slv' 
                       ; Group of collections, e.g., ana (direct analysis products), asm (assimilated state variables), flx (surface turbulent fluxes and related
                       ; quantities), slv (single level), lnd(land surface variables), gas (aerosol optical depth), ... Choose 'flx' for precip, 'slv' for T2M.    
ENDIF ELSE BEGIN  
  IF iTTVar GE 0 THEN _time='tavg' ELSE _time= 'inst'
  _HV='Np'

  IF _day_mon EQ 'mon' OR _day_mon EQ 'ensoMon' THEN _freq='M' ELSE _freq='3'
  IF iTTVar GE 0 THEN _group='rad' ELSE _group='asm'
ENDELSE
; ---------------------------------------------------------------------------------------------------------------------

IF varName EQ 'PRECTOTCORR' THEN BEGIN
  verb1='bias corrected total '
  nLowName='nZero'
  ;;;;_group='flx'
ENDIF ELSE BEGIN
  verb1=' '
  nLowName='n10th'
  ;;;;_group='slv'  
ENDELSE
;------------


IF fm EQ lm THEN a0=string(amon[fm], format='(a3)') ELSE a0=string(amon[fm], '-', amon[lm], format='(a3,a1,a3)')
a1=string(fy, '-', ly, format='(i4,a1,i4)')
IF fm EQ lm THEN a01=string(amon1[fm], format='(a)') ELSE a01=string(amon1[fm], '-', amon1[lm], format='(a,a1,a)')
; ================================ END OF No changes ========================================================
; ===========================================================================================================








; ============================================================================================================
; ================================ Read MERRA2 files =========================================================
ida=0
nday=9999 ; a dummy number to pass the IF condition for retrieving attributes.
lDayYr=0 ; Index of last day of each month (or season) of each year. This is set to account for the fact that Feb of leap years has 29 days.
FOR iyr=0, ny-1 DO BEGIN
  yr=fy+iyr
  ;;;subDir=string('MERRA2_', fix((yr-1980)/10+1), '00', format='(a7, i1, a2)') ; define MERRA2 sub-dir: 100, 200, 300, 400
  
  FOR imo=0, nm-1 DO BEGIN
    mo=fm+imo
    
    IF mo LT 12 AND MonAutoLoop EQ 0 AND fm GT lm THEN BEGIN
      yr0=string(yr-1, format='(i4)')
    ENDIF ELSE IF mo GE 12 THEN BEGIN
      mo=mo-12
      yr0=string(yr, format='(i4)')
    ENDIF ELSE yr0=string(yr, format='(i4)')
    
    IF yr0 GE 1980 AND yr0 LT 1992 THEN subDir0='100' ELSE IF yr0 GE 1992 AND yr0 LT 2001 THEN subDir0='200' $
      ELSE IF yr0 GE 2001 AND yr0 LT 2011 THEN subDir0='300' ELSE IF yr0 GE 2011 AND yr0 LE 2025 THEN subDir0='400'
    subDir= 'MERRA2_' + subDir0
    
    IF mo LT 9 THEN mo0= string('0', mo+1, format='(a1, i1)') ELSE mo0= string(mo+1, format='(i2)') ; write the months in 2-digit format between 1-12.      
    dirIn= dirMain+subDir+string('/Y', yr0, '/M', mo0, '/', format='(a2, i4, a2, a2, a1)') ; full path to MERRA2 data directory for yr and mo of interest.
    fn0=dirIn+subDir+'.'+_time+_freq+'_'+_2d_3d+'_'+_group+'_'+_HV+'.'+yr0+mo0

    IF(yr MOD 4 EQ 0 AND mo EQ 1) THEN month_len[1]= 29 ELSE month_len[1]= 28; number of days in Feb for a leap year!


    IF _day_mon EQ 'mon' OR _day_mon EQ 'ensoMon' THEN BEGIN
      fn= fn0 + '.nc4' ; file name to read
      fileID = H5F_OPEN(fn) ; -------------------------------- Open monthly File.
      print, fn
      IF showListVars EQ 1 THEN GOTO, GOTO_showListVars
      
      IF varName EQ 'wind10m' THEN BEGIN
        ; ......................
        dataName='U10M' ; Open just to get lon, lat and levels. Note U10M is not read here; it will at line: dataNameU10M='U10M'.
        dataID=H5D_OPEN(fileID, dataName)
                  
        IF iyr EQ 0 AND imo EQ 0 THEN GOTO, selLonLatLev ; select lon, lat and levels
        GoBack_toMonthly_W10: $
          
        IF _2d_3d EQ '3d'THEN BEGIN
          count= [nlon, nlat, dur_pres_ind, 1] & offset = [0, 0, min_pres_ind, 0] ; for 3D monthly fields. A 4th dimension for time should be added for H5S_SELECT_HYPERSLAB to work!
        ENDIF ELSE BEGIN
          count= [nlon, nlat, 1] & offset = [0, 0, 0] ; for 2D monthly fields
        ENDELSE
        H5D_CLOSE, dataID ; Close dataset.
        ;......................

        
        dataNameU10M='U10M' ; Open and retrieve U10M .......................
        dataID_U10M=H5D_OPEN(fileID, dataNameU10M)
        data0_U10M=H5D_READ(dataID_U10M) ; data read from each file
        H5D_CLOSE, dataID_U10M ; Close U10M

        dataNameV10M='V10M' ; Open and retrieve V10M .......................
        dataID_V10M=H5D_OPEN(fileID, dataNameV10M)
        data0_V10M=H5D_READ(dataID_V10M) ; data read from each file
        dataID=dataID_V10M ; Enables the program to retrieve other attributes and close the V10M data at the end.
        
        data0=sqrt(data0_U10M^2.+data0_V10M^2.)
      ENDIF ELSE IF varName EQ 'EMP' THEN BEGIN
        ; ......................
        dataName='EVAP' ; Open just to get lon, lat and levels. Note EVAP is not read here; it will at line: dataNameE='EVAP'.
        dataID=H5D_OPEN(fileID, dataName)

        IF iyr EQ 0 AND imo EQ 0 THEN GOTO, selLonLatLev ; select lon, lat and levels
        GoBack_toMonthly_EMP: $

          IF _2d_3d EQ '3d'THEN BEGIN
          count= [nlon, nlat, dur_pres_ind, 1] & offset = [0, 0, min_pres_ind, 0] ; for 3D monthly fields. A 4th dimension for time should be added for H5S_SELECT_HYPERSLAB to work!
        ENDIF ELSE BEGIN
          count= [nlon, nlat, 1] & offset = [0, 0, 0] ; for 2D monthly fields
        ENDELSE
        H5D_CLOSE, dataID ; Close dataset.
        ;......................

                  
        dataNameE='EVAP' ; Open and retrieve EVAP .......................
        dataID_E=H5D_OPEN(fileID, dataNameE)                   
        data0_E=H5D_READ(dataID_E) ; data read from each file
        H5D_CLOSE, dataID_E ; Close EVAP

        dataNameP='PRECTOT' ; Open and retrieve PRECTOT .......................
        dataID_P=H5D_OPEN(fileID, dataNameP)
        data0_P=H5D_READ(dataID_P) ; data read from each file
        dataID=dataID_P ; Enables the program to retrieve other attributes and close the PRECTOT data at the end.

        long_name_data='evaporation minus precipitation'

        data0=data0_E-data0_P
      ENDIF ELSE BEGIN
        dataName=varName ; Open and retrieve data.......................
        dataID=H5D_OPEN(fileID, dataName)
        
        IF iyr EQ 0 AND imo EQ 0 THEN GOTO, selLonLatLev ; select lon, lat and levels
        GoBack_toMonthly: $         
        
        
        ;------- read time attributes/value
        ; NOTE: time gets uptaded for each file. Value remains 0, but 'units' and 'begin_date, change by file. 
        time_name='time'
        time_id=H5D_OPEN(fileID, time_name)
        time=H5D_READ(time_id)

        ; Get all attributes of time.
        IF (iyr EQ 0 AND imo EQ 0 AND subSet EQ 0) OR subSet EQ 1 THEN BEGIN
          long_name_id=H5A_OPEN_NAME(time_id, 'long_name')
          long_name_time=H5A_READ(long_name_id)
          H5A_CLOSE, long_name_id

          time_increment_id=H5A_OPEN_NAME(time_id, 'time_increment')
          time_increment=H5A_READ(time_increment_id)
          H5A_CLOSE, time_increment_id

          begin_time_id=H5A_OPEN_NAME(time_id, 'begin_time')
          begin_time=H5A_READ(begin_time_id)
          H5A_CLOSE, begin_time_id

          vmax_id_time=H5A_OPEN_NAME(time_id, 'vmax')
          vmax_time=H5A_READ(vmax_id_time)
          H5A_CLOSE, vmax_id_time

          vmin_id_time=H5A_OPEN_NAME(time_id, 'vmin')
          vmin_time=H5A_READ(vmin_id_time)
          H5A_CLOSE, vmin_id_time

          range_id_time=H5A_OPEN_NAME(time_id, 'valid_range')
          range_time=H5A_READ(range_id_time)
          H5A_CLOSE, range_id_time
        ENDIF

        units_id_time=H5A_OPEN_NAME(time_id, 'units')
        units_timeTmp=H5A_READ(units_id_time)
        H5A_CLOSE, units_id_time

        begin_date_id=H5A_OPEN_NAME(time_id, 'begin_date')
        begin_dateTmp=H5A_READ(begin_date_id)
        H5A_CLOSE, begin_date_id


        ; global attributes:
        ngatts=H5A_GET_NUM_ATTRS(fileID)
        FOR iga = 0L, ngatts - 1L DO BEGIN
          gatt_id=H5A_OPEN_IDX(fileID,iga)
          gattVal0=string(H5A_READ(gatt_id))
          gattName0=H5A_GET_NAME(gatt_id)
          
          IF iga EQ 0 THEN BEGIN
            gattVals=[gattVal0]
            gattNames=[gattName0]
          ENDIF ELSE BEGIN
            gattVals=[[gattVals],[gattVal0]]
            gattNames=[[gattNames],[gattName0]]              
          ENDELSE
        ENDFOR

        gattTmp=hash(gattNames, gattVals)


        H5D_CLOSE, time_id
        ; END OF ---- read time attributes/value


        
        IF _2d_3d EQ '3d'THEN BEGIN
          count= [nlon, nlat, dur_pres_ind, 1] & offset = [0, 0, min_pres_ind, 0] ; for 3D monthly fields. A 4th dimension for time should be added for H5S_SELECT_HYPERSLAB to work!
        ENDIF ELSE BEGIN
          count= [nlon, nlat, 1] & offset = [0, 0, 0] ; for 2D monthly fields
        ENDELSE

        dataspace_id = H5D_GET_SPACE(dataID) ; Open up the dataspace
        H5S_SELECT_HYPERSLAB, dataspace_id, offset, count, /RESET ; STRIDE=[2, 2] will pick every other element. STRIDE=[1, 1] is the the default.
        memory_space_id = H5S_CREATE_SIMPLE(count) ; Without specifying MEMORY_SPACE the result would be the same size as the original dataspace, with zeroes everywhere except our hyperslab selection.
        data0 = H5D_READ(dataID, FILE_SPACE=dataspace_id, MEMORY_SPACE=memory_space_id)
        H5S_CLOSE, dataspace_id
        H5D_CLOSE, dataID ; Close dataset.
      ENDELSE
      
      H5F_CLOSE, fileID ;------------------------------------ Close monthly file.
      
      IF imo EQ 0 THEN dataTmp=data0 ELSE dataTmp=data0+dataTmp
      IF imo EQ nm-1 THEN dataTmp=dataTmp/nm     
      
      IF _2d_3d EQ '3d' AND n_prs GT 1 THEN dataTmp=dataTmp[*, *, pres_ind]
    ENDIF ELSE BEGIN        
      nday=month_len[mo]
      ndaysAll=ndaysAll+nday
      FOR ida=0, nday-1 DO BEGIN
        IF ida LT 9 THEN da0= string('0', ida+1, format='(a1, i1)') ELSE da0= string(ida+1, format='(i2)') ; write the days in 2-digit format starting at 1.
        fn= fn0 + da0 + '.nc4' ; file name to read
        fileID = H5F_OPEN(fn) ; -------------------------------- Open daily File.
        print, fn
        
        IF showListVars EQ 1 THEN GOTO, GOTO_showListVars
        
        IF varName EQ 'wind10m' THEN BEGIN
          dataNameU10M='U10M' ; Open and retrieve U10M .......................
          dataID_U10M=H5D_OPEN(fileID, dataNameU10M)
          data0_U10M=H5D_READ(dataID_U10M) ; data read from each file
          nDimData0=size(data0_U10M, /n_dimensions) ; number of dimensions in data0
          IF nDimData0 EQ 3 THEN data1_U10M=mean(data0_U10M, DIMENSION=nDimData0) ELSE data1_U10M=data0_U10M ; mean daily rainfall rate using all 24 hours of the day.
          H5D_CLOSE, dataID_U10M ; Close U10M

          dataNameV10M='V10M' ; Open and retrieve V10M .......................
          dataID_V10M=H5D_OPEN(fileID, dataNameV10M)
          data0_V10M=H5D_READ(dataID_V10M) ; data read from each file
          IF nDimData0 EQ 3 THEN data1_V10M=mean(data0_V10M, DIMENSION=nDimData0) ELSE data1_V10M=data0_V10M ; mean daily rainfall rate using all 24 hours of the day.
          H5D_CLOSE, dataID_V10M ; Close V10M
          dataName=dataNameV10M ; Enables the program to retrieve other attributes at a later section.

          data1=sqrt(data1_U10M^2.+data1_V10M^2.)
        ENDIF ELSE BEGIN
          dataName=varName ; Open and retrieve data.......................
          dataID=H5D_OPEN(fileID, dataName)
        ENDELSE
        
        
        IF (iyr EQ 0 AND imo EQ 0 AND ida EQ 0 AND subSet EQ 0) OR (ida EQ 0 AND subSet EQ 1) THEN BEGIN ;>>>>> Retrive lon, lat, levels, _FillValue, long_name, units <<<<<<
            dataID=H5D_OPEN(fileID, dataName)
          
          selLonLatLev: $ ; to be called from monthly loop when monthly files are read
  
          ; Get '_FillValue' attribute.
          fillVal_id=H5A_OPEN_NAME(dataID, '_FillValue')
          fillVal=H5A_READ(fillVal_id) ; NOTE: this is in array format, so you should call it as fillVal(0)
          H5A_CLOSE, fillVal_id

          missVal_id=H5A_OPEN_NAME(dataID, 'missing_value')
          missVal=H5A_READ(missVal_id) ; NOTE: this is in array format, so you should call it as missVal(0)
          H5A_CLOSE, missVal_id
          
          fmissVal_id=H5A_OPEN_NAME(dataID, 'fmissing_value')
          fmissVal=H5A_READ(fmissVal_id) ; NOTE: this is in array format, so you should call it as fmissVal(0)
          H5A_CLOSE, fmissVal_id
    
          ; Get 'long_name' attribute.
          long_name_id_data=H5A_OPEN_NAME(dataID, 'long_name')
          long_name_data=H5A_READ(long_name_id_data)
          H5A_CLOSE, long_name_id_data
      
          ; Get 'units' attribute.
          units_id_data=H5A_OPEN_NAME(dataID, 'units')
          units_data=H5A_READ(units_id_data)
          H5A_CLOSE, units_id_data
    
          vmax_id_data=H5A_OPEN_NAME(dataID, 'vmax')
          vmax_data=H5A_READ(vmax_id_data)
          H5A_CLOSE, vmax_id_data
    
          vmin_id_data=H5A_OPEN_NAME(dataID, 'vmin')
          vmin_data=H5A_READ(vmin_id_data)
          H5A_CLOSE, vmin_id_data
    
          range_id_data=H5A_OPEN_NAME(dataID, 'valid_range')
          range_data=H5A_READ(range_id_data)
          H5A_CLOSE, range_id_data  
          
          ; Retrieve lat.
          lat_name='lat'
          lat_id=H5D_OPEN(fileID, lat_name)
          lat=H5D_READ(lat_id)
          nlat=n_elements(lat)
          
          ; Get all attributes of lat.
          long_name_id_lat=H5A_OPEN_NAME(lat_id, 'long_name')
          long_name_lat=H5A_READ(long_name_id_lat)
          H5A_CLOSE, long_name_id_lat
    
          units_id_lat=H5A_OPEN_NAME(lat_id, 'units')
          units_lat=H5A_READ(units_id_lat)
          H5A_CLOSE, units_id_lat
    
          vmax_id_lat=H5A_OPEN_NAME(lat_id, 'vmax')
          vmax_lat=H5A_READ(vmax_id_lat)
          H5A_CLOSE, vmax_id_lat
    
          vmin_id_lat=H5A_OPEN_NAME(lat_id, 'vmin')
          vmin_lat=H5A_READ(vmin_id_lat)
          H5A_CLOSE, vmin_id_lat
    
          range_id_lat=H5A_OPEN_NAME(lat_id, 'valid_range')
          range_lat=H5A_READ(range_id_lat)
          H5A_CLOSE, range_id_lat
          H5D_CLOSE, lat_id
    
          ; Retrieve lon.
          lon_name='lon'
          lon_id=H5D_OPEN(fileID, lon_name)
          lon=H5D_READ(lon_id)
          nlon=n_elements(lon)
          
          ; Get all attributes of lon.
          long_name_id_lon=H5A_OPEN_NAME(lon_id, 'long_name')
          long_name_lon=H5A_READ(long_name_id_lon)
          H5A_CLOSE, long_name_id_lon
    
          units_id_lon=H5A_OPEN_NAME(lon_id, 'units')
          units_lon=H5A_READ(units_id_lon)
          H5A_CLOSE, units_id_lon
    
          vmax_id_lon=H5A_OPEN_NAME(lon_id, 'vmax')
          vmax_lon=H5A_READ(vmax_id_lon)
          H5A_CLOSE, vmax_id_lon
    
          vmin_id_lon=H5A_OPEN_NAME(lon_id, 'vmin')
          vmin_lon=H5A_READ(vmin_id_lon)
          H5A_CLOSE, vmin_id_lon
    
          range_id_lon=H5A_OPEN_NAME(lon_id, 'valid_range')
          range_lon=H5A_READ(range_id_lon)
          H5A_CLOSE, range_id_lon              
          H5D_CLOSE, lon_id  
          
          ; Retrieve level.
          IF _2d_3d EQ '3d'THEN BEGIN
            lev_name='lev'
            lev_id=H5D_OPEN(fileID, lev_name)
            level=H5D_READ(lev_id)
            
            ; Get all attributes of lev.
            long_name_id_lev=H5A_OPEN_NAME(lev_id, 'long_name')
            long_name_lev=H5A_READ(long_name_id_lev)
            H5A_CLOSE, long_name_id_lev
  
            units_id_lev=H5A_OPEN_NAME(lev_id, 'units')
            units_lev=H5A_READ(units_id_lev)
            H5A_CLOSE, units_id_lev
  
            vmax_id_lev=H5A_OPEN_NAME(lev_id, 'vmax')
            vmax_lev=H5A_READ(vmax_id_lev)
            H5A_CLOSE, vmax_id_lev
  
            vmin_id_lev=H5A_OPEN_NAME(lev_id, 'vmin')
            vmin_lev=H5A_READ(vmin_id_lev)
            H5A_CLOSE, vmin_id_lev
  
            range_id_lev=H5A_OPEN_NAME(lev_id, 'valid_range')
            range_lev=H5A_READ(range_id_lev)
            H5A_CLOSE, range_id_lev          
            H5D_CLOSE, lev_id
            
            pres_ind = INTARR(n_prs)
            FOR i = 0, n_prs-1 DO BEGIN
              pres_ind[i] = WHERE(level EQ Xprs[i], amt )
              IF amt EQ 0 THEN BEGIN & print, 'pressure error', Xprs, level & stop & ENDIF
            ENDFOR 
          ENDIF
          
          ; pressure fix (modification to speed up reading)
          IF _2d_3d EQ '3d'THEN BEGIN
            min_pres_ind = MIN(pres_ind)
            dur_pres_ind = MAX(pres_ind) - min_pres_ind + 1
            pres_ind -= min_pres_ind
            count= [nlon, nlat, dur_pres_ind, 8] & offset = [0, 0, min_pres_ind, 0] ; in 3D fields, there are 8 data per day, so nDimData0=4.
          ENDIF ELSE IF _2d_3d EQ '2d' AND i2mVar GE 0 THEN BEGIN
            count= [nlon, nlat, 1] & offset = [0, 0, 0] ; in T2M 2D fields, there is one data per day, so nDimData0=2.
          ENDIF ELSE BEGIN
            count= [nlon, nlat, 24] & offset = [0, 0, 0] ; in 2D fields, there are 8 data per day, so nDimData0=3.
          ENDELSE         
        ENDIF ;>>>>> END OF Retrive lon, lat, levels, _FillValue, long_name, units <<<<<<    
   
        IF _day_mon EQ 'mon' OR _day_mon EQ 'ensoMon' THEN BEGIN
          IF varName EQ 'wind10m' THEN GOTO, GoBack_toMonthly_W10 $ ; go back to monthly loop for wind10m once lon, lat, levels are selected.
          ELSE IF varName EQ 'EMP' THEN GOTO, GoBack_toMonthly_EMP $; go back to monthly loop for EMP once lon, lat, leveles are selected.
          ELSE GOTO, GoBack_toMonthly ; go back to monthly loop once lon, lat, leveles are selected.
        ENDIF
                  
        dataspace_id = H5D_GET_SPACE(dataID) ; Open up the dataspace
        H5S_SELECT_HYPERSLAB, dataspace_id, offset, count, /RESET ; STRIDE=[2, 2] will pick every other element. STRIDE=[1, 1] is the the default.
        memory_space_id = H5S_CREATE_SIMPLE(count) ; Without specifying MEMORY_SPACE the result would be the same size as the original dataspace, with zeroes everywhere except our hyperslab selection.
        data0 = H5D_READ(dataID, FILE_SPACE=dataspace_id, MEMORY_SPACE=memory_space_id)
        H5S_CLOSE, dataspace_id
        H5D_CLOSE, dataID ; Close dataset.

        nDimData0=size(data0, /n_dimensions) ; number of dimensions in data0
        IF (_2d_3d EQ '3d' AND nDimData0 EQ 4) OR (_2d_3d EQ '2d' AND nDimData0 EQ 3) THEN $  ; in 3D fields, there are 8 data per day, so nDimData0=4. I'm currently averaging all non 'NaN' values, but I may change this since there may be e.g., only one out of 100 reads with a non 'NaN' value so that would dominate the mean.
          data1=mean(data0, DIMENSION=nDimData0, /NaN) ELSE data1=data0                     ; in 2D fields (except for T2M variables), there are 24 data per day, so nDimData0=3. For 2D T2M variables nDimData0=2.
        H5F_CLOSE, fileID ;------------------------------------ Close daily file.
        
        
        ;;;;;;H5F_CLOSE, fileID ;------------------------------------ Close daily file.
        IF ida EQ 0 AND imo EQ 0 AND iyr EQ 0 THEN BEGIN
          data=data1
          ;;;;;;fnDay0=fn ; This will be used later to retrieve attributes, lon, and lat. Note that "time" will not be retrieved since the daily analyis compiles more than one file for each month.
        ENDIF ELSE data=[[[data]], [[data1]]] ; All data (lon, lat, ndaysAll) for daily analysis.
        
        lDayYr++
      ENDFOR                
    ENDELSE
    
    
    ;------------------------------------------------------------------
    GOTO_showListVars: $    
    IF showListVars EQ 1 THEN BEGIN ; Get list of variables............
      nobjs = H5G_GET_NUM_OBJS(fileID)
      FOR ib = 0L, nobjs - 1L DO BEGIN
        obj=H5G_GET_OBJ_NAME_BY_IDX(fileID, ib)
        print, obj
      ENDFOR
      H5F_CLOSE, fileID
      stop
    ENDIF ; END OF Get list of variables................................
  ENDFOR
  
  CASE 1 OF
    (_day_mon EQ 'day' OR _day_mon EQ 'ensoDay') AND iyr EQ 0: BEGIN
      DayPerYrAll=[0, lDayYr]
      units_time0=units_timeTmp
      begin_date0=begin_dateTmp
    END
    
    (_day_mon EQ 'day' OR _day_mon EQ 'ensoDay') AND iyr NE 0: BEGIN
      DayPerYrAll=[DayPerYrAll, lDayYr]
      units_time0=[units_time0, units_timeTmp]
      begin_date0=[begin_date0, begin_dateTmp]
    END
    
    _day_mon EQ 'mon' AND iyr EQ 0: BEGIN
      data=dataTmp
      units_time0=units_timeTmp
      begin_date0=begin_dateTmp
      gatt0=[gattTmp]
    END
    
    _day_mon EQ 'mon' AND iyr NE 0: BEGIN
      data=[[[data]], [[dataTmp]]] ; All data (lon, lat, yr) for monthly analysis.
      units_time0=[units_time0, units_timeTmp]
      begin_date0=[begin_date0, begin_dateTmp]
      gatt0=[[gatt0],[gattTmp]]
    END
    
    _day_mon EQ 'ensoMon' AND iyr EQ 0: data=dataTmp
    _day_mon EQ 'ensoMon' AND iyr NE 0: data=[[[data]], [[dataTmp]]] ; All data (lon, lat, yr) for seaonal analysis (OND or JFM).
  ENDCASE
    
ENDFOR  
; ================================ END OF Read MERRA2 files =================================================
; ===========================================================================================================






iPrsLoop=0
IF _2d_3d EQ '3d' AND n_prs GT 1 THEN BEGIN 
  DoNextPrsLev: $
    indPrsData= indgen(ny)*n_prs+iPrsLoop
  data_used=data[*, *, indPrsData]
  
  iprLen=0 & WHILE fix(Xprs[iPrsLoop]/10^iprLen) NE 0. DO iprLen++ & pr_len=iprLen
  prLevFN=string(Xprs[iPrsLoop], format='(i'+string(pr_len, format='(i1)')+')') ; pressure level to be used in output filename
ENDIF ELSE data_used=data



; ============================================================================================================
; ================================ Monthly Percentile Calculations ===========================================
IF _day_mon EQ 'mon' THEN BEGIN
  
  yrInd=indgen(ny)
  
  ; Decided to use double(-9999.) per GESDISC
  IF FixPer EQ 0 THEN BEGIN
    perc=fltarr(nlon,nlat,ny)
    perc0=float(yrInd)/ny*100
    percTmp=fltarr(ny)
    ltmVals=MAKE_ARRAY(nlon,nlat, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; Long-term mean (climatology), when FixPer=0. It's calculated when more than validValPerThr percent of years have valid values.
    stdVals=MAKE_ARRAY(nlon,nlat, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; standard deviation, when FixPer=0. It's calculated when more than validValPerThr percent of years have valid values.
    anomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; anomaly values (X-X_bar) of variable of interest for select years used when FixPer=0. It's calculated when more than validValPerThr percent of years have valid values.
    normAnomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; normalized anomaly values (X-X_bar)/X_bar of variable of interest for select years used when FixPer=0. It's calculated when more than validValPerThr percent of years have valid values.
    stdAnomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; standardized anomaly values (X-X_bar)/std of variable of interest for select years used when FixPer=0. It's calculated when more than validValPerThr percent of years have valid values.
  ENDIF ELSE IF FixPer EQ 1 OR FixPer EQ 3 THEN BEGIN
    percVals=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; Percentile values in increasing order, corresponding to perc0, when FixPer=1 or 3. It's calculated when ALL years have valid values.
    ltmVals=MAKE_ARRAY(nlon,nlat, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; Long-term mean (climatology), when FixPer=1 or 3. It's calculated when more than validValPerThr percent of years have valid values.
    stdVals=MAKE_ARRAY(nlon,nlat, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; standard deviation, when FixPer=1 or 3. It's calculated when more than validValPerThr percent of years have valid values.
    perc0=float(yrInd)/ny*100
  ENDIF ELSE IF FixPer EQ 2 THEN BEGIN
    perc=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0))
    anomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; anomaly values (X-X_bar) of variable of interest for select years used when FixPer=2.
    normAnomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; normalized anomaly values (X-X_bar)/X_bar of variable of interest for select years used when FixPer=2.
    stdAnomal=MAKE_ARRAY(nlon,nlat,ny, /FLOAT, VALUE = double(-9999.)); missVal(0)) ; standardized anomaly values (X-X_bar)/std of variable of interest for select years used when FixPer=2.
  ENDIF
  
  
  FOR ilon=0, nlon-1 DO BEGIN
    FOR ilat=0, nlat-1 DO BEGIN
      indSort=sort(data_used[ilon, ilat, *])
      iValid=where(data_used[ilon, ilat, *] NE missVal(0), nValid) ; # number of years with valid values (for a given pressure level if 3D) 
      IF float(nValid)/ny GT validValPerThr*.01 THEN validGrd=1 ELSE validGrd=0 ; If more than validValPerThr percent of years have valid values then take this grid as a valid value and later do averaging etc on the those values, otherwise fill this grid with missing value. 

      IF FixPer EQ 0 AND validGrd EQ 1 THEN BEGIN      
        ltmVals[ilon, ilat]=mean(data_used[ilon, ilat, iValid])
        stdVals[ilon, ilat]=stddev(data_used[ilon, ilat, iValid])
        
        FOR iyr=0, nValid-1 DO BEGIN
          IF nValid EQ ny THEN percTmp[iValid[iyr]]= perc0[where(indSort EQ iValid[iyr])]
          anomal[ilon, ilat, iValid[iyr]]=data_used[ilon, ilat, iValid[iyr]]-ltmVals[ilon, ilat]
          normAnomal[ilon, ilat, iValid[iyr]]=anomal[ilon, ilat, iValid[iyr]]/ltmVals[ilon, ilat]
          stdAnomal[ilon, ilat, iValid[iyr]]=anomal[ilon, ilat, iValid[iyr]]/stdVals[ilon, ilat]
        ENDFOR
        perc[ilon, ilat, *]=percTmp ; Percentiles vary over [0, 1).
      ENDIF ELSE IF FixPer EQ 1 OR FixPer EQ 3 AND validGrd EQ 1 THEN BEGIN 
        IF nValid EQ ny THEN percVals[ilon, ilat, *] = data_used[ilon, ilat, indSort]
        ltmVals[ilon, ilat]=mean(data_used[ilon, ilat, iValid]) 
        stdVals[ilon, ilat]=stddev(data_used[ilon, ilat, iValid])
      ENDIF ELSE IF FixPer EQ 2 THEN BEGIN
        IF ilon EQ 0 AND ilat EQ 0 THEN BEGIN
          climFN0='MERRA2.'+'tavg'+C_or_S+_2d_3d+'_'+'ltm'+'_'+_HV+'.'+fyFnLTMread+mo0+'_'+lyFnLTMread+mo0+'.nc4'
          percFN0='MERRA2.'+'tavg'+C_or_S+_2d_3d+'_'+'pct'+'_'+_HV+'.'+fyFnLTMread+mo0+'_'+lyFnLTMread+mo0+'.nc4'

          climFN=dirNC4+'M2_ltm_'+fyFnLTMread+'_'+lyFnLTMread+'/'+climFN0 
          percFN=dirNC4+'M2_pct_'+fyFnLTMread+'_'+lyFnLTMread+'/'+percFN0
          print, '' & print, climFN & print, '' & print, percFN
          
          fileID = H5F_OPEN(climFN) ; -------------------------------- Open nc4 Climatology file.
          ltmID=H5D_OPEN(fileID, +varName)
          ltm_FixPer=H5D_READ(ltmID) ; long-term mean
          H5D_CLOSE, ltmID
          
          stdID=H5D_OPEN(fileID, 'std_'+varName)
          std_FixPer=H5D_READ(stdID) ; standard deviation
          H5D_CLOSE, stdID
          H5F_CLOSE, fileID ;------------------------------------ Close nc4 Climatology file.
          
          
          fileID = H5F_OPEN(percFN) ; -------------------------------- Open nc4 Percentiles file.
          dataID=H5D_OPEN(fileID, 'per_'+varName)
          percVal_FixPer=H5D_READ(dataID) ; data percentile values
          H5D_CLOSE, dataID

          percID=H5D_OPEN(fileID, 'percentiles')
          perc_FixPer=H5D_READ(percID) ; percentiles
          H5D_CLOSE, percID
          H5F_CLOSE, fileID ;------------------------------------ Close nc4 Percentiles file.
          
          npercVal_FixPer=n_elements(percVal_FixPer[0, 0, *])
          
          FOR iyr=0, ny-1 DO BEGIN
            anomal[*, *, iyr]=data_used[*, *, iyr]-ltm_FixPer
            normAnomal[*, *, iyr]=anomal[*, *, iyr]/ltm_FixPer
            stdAnomal[*, *, iyr]=anomal[*, *, iyr]/std_FixPer
          ENDFOR

        ENDIF
        
        FOR iyr=0, ny-1 DO BEGIN
          percVal_FixPerTmp=reform(percVal_FixPer[ilon, ilat, *])
          iPerc=max(where(data_used[ilon, ilat, iyr] GT percVal_FixPerTmp))
          ;;;IF iPerc LT npercVal_FixPer-1 THEN perc[ilon, ilat, iyr]=perc_FixPer[iPerc+1] ELSE perc[ilon, ilat, iyr]=100. 
          IF iPerc EQ -1 THEN perc[ilon, ilat, iyr]=0.0001 $ ; to avoid 0 but giving it a very low value.
          ELSE IF iPerc GE 0 AND iPerc LT npercVal_FixPer-1 THEN $
            perc[ilon, ilat, iyr]=perc_FixPer[iPerc+1]-(percVal_FixPerTmp[iPerc+1]-data_used[ilon, ilat, iyr])/(percVal_FixPerTmp[iPerc+1]-percVal_FixPerTmp[iPerc])*(perc_FixPer[iPerc+1]-perc_FixPer[iPerc]) $
          ELSE perc[ilon, ilat, iyr]=99.99 ; to avoid 100 but giving it a very high value.
        ENDFOR
      ENDIF

    ENDFOR
  ENDFOR

  IF FixPer EQ 3 AND _2d_3d EQ '3d' AND n_prs GT 1 THEN BEGIN
    IF iPrsLoop EQ 0 THEN BEGIN 
      ltmValsAll=[ltmVals] 
      stdValsAll=[stdVals]
      percValsAll=[percVals]
    ENDIF ELSE BEGIN
      ltmValsAll=[[ltmValsAll], [ltmVals]]
      stdValsAll=[[stdValsAll], [stdVals]]
      percValsAll=[[percValsAll], [percVals]]     
    ENDELSE
    
    IF iPrsLoop EQ n_prs-1 THEN BEGIN
      ltmValsAll=reform(ltmValsAll,nlon, nlat, n_prs)
      stdValsAll=reform(stdValsAll,nlon, nlat, n_prs)
      percValsAll=reform(percValsAll,nlon, nlat, n_prs, ny)
    ENDIF
  ENDIF ELSE IF FixPer EQ 3 AND ((_2d_3d EQ '3d' AND n_prs EQ 1) OR _2d_3d EQ '2d') THEN BEGIN
    ltmValsAll=ltmVals
    stdValsAll=stdVals
    percValsAll=percVals 
  ENDIF
ENDIF
; ================================ END OF Monthly Percentile Calculations ===================================
; ===========================================================================================================







; ============================================================================================================
; ================================ Daily Percentile Calculations =============================================
IF _day_mon EQ 'day' OR _day_mon EQ 'ensoDay' AND subSet EQ 0 THEN BEGIN
  percSel=indgen(11)*10. ; Select percentiles for analysis: 0, 10, 20, ..., 90. For each grid, the corresponding percentile 
                         ; values will be calculated using all days over the study period defined by fy, ly, fm and lm.
  n90th=lonarr(nlon, nlat, ny) ; Number of days with rainfall >= 90th percentile. 
  nLow=lonarr(nlon, nlat, ny) ; Number of days with rainfall less than or equal to threshold considered as nearly no rain, or
                              ; Number of days with T2M <= 10th percentile.
  thresh0=thresh/3600. ; to convert mm/hr to kg m-2 s-1 
  indPercSel90th=where(percSel EQ 90., perc90th_exist)
  IF perc90th_exist EQ 0 THEN BEGIN & print, '********* 90th percentile is not included in percSel values *********' & stop & ENDIF  
  indPercSel10th=where(percSel EQ 10., perc10th_exist)
  IF perc10th_exist EQ 0 THEN BEGIN & print, '********* 10th percentile is not included in percSel values *********' & stop & ENDIF

  FOR ilon=0, nlon-1 DO BEGIN
    FOR ilat=0, nlat-1 DO BEGIN
      dataSel=reform(data_used[ilon, ilat, *])
      indSort=sort(dataSel)
      percVals=dataSel[indSort[fix(.01*percSel*lDayYr)]]
      
      FOR iyr=0, ny-1 DO BEGIN
        dataYr= reform(data_used[ilon, ilat, DayPerYrAll[iyr]:DayPerYrAll[iyr+1]-1]) ; Data of all days for each year. 
        ind90th= where(dataYr GE percVals[indPercSel90th[0]], n90th0) ; Number of days with rainfall >= 90th percentile. 
        IF varName EQ 'PRECTOTCORR' THEN $
          indZero= where(dataYr LT thresh0, nLow0) $ ; Number of days with rainfall less than or equal to threshold considered as nearly no rain.        
          ELSE ind10th= where(dataYr LE percVals[indPercSel10th[0]], nLow0) ; Number of days with T2M <= 10th percentile.
        
        n90th[ilon, ilat, iyr]=n90th0
        nLow[ilon, ilat, iyr]=nLow0
      ENDFOR 

    ENDFOR
  ENDFOR
ENDIF
; ================================ END OF Daily Percentile Calculations =====================================
; ===========================================================================================================














; ============================================================================================================
; ====================== Store Monthly Outputs: One file for each year/month/variable ========================
; Outputs are stored in netcdf4 format, one file for each year/month/variable.
IF ncdfYN EQ 1 AND _day_mon EQ 'mon' AND FixPer EQ 0 OR FixPer EQ 2 AND subSet EQ 0 AND combVarYN EQ 0 THEN BEGIN
  IF nm GT 1 THEN BEGIN
    IF lm LT 9 THEN mo00= string(mo0, '0', lm+1, format='(a2, a1, a1, i1)') ELSE mo00= string(mo0, '0', lm+1, format='(a2, a1, i2)') ; add the last month in 2-digit format between 1-12, if nm > 1.
  ENDIF ELSE mo00=mo0  
  
  FOR iyr=0, ny-1 DO BEGIN
    actual_data_out=reform(data_used[*, *, iyr]) ; actual data read directly from MERRA-2 FILES.
    anomal_data_out=reform(anomal[*, *, iyr]) ; anomalies with respect to LTM calculated based on baseline period 1981-2010 (if FixPer=2) or a user-defined period (if FixPer=0).
    perc_data_out=reform(perc[*, *, iyr]) ; percentiles with respect to LTM calculated based on baseline period 1981-2010 (if FixPer=2) or a user-defined period (if FixPer=0).
    units_time=units_time0[iyr]
    begin_date=begin_date0[iyr]
    yr=fy+iyr
    yr0=string(yr, format='(i4)')
    
    IF ltmPer EQ 0 THEN ltmVerExt= '.' ELSE ltmVerExt= '.v2_0.'
    
    fnOut0='MERRA2.'+'stat'+_freq+'_'+_2d_3d+'_pct_'+_HV+ltmVerExt+yr0+mo0+'.nc4'
;    IF _2d_3d EQ '3d' AND n_prs GT 1 THEN fnOut0= varName+prLevFN+fnOut00 ELSE fnOut0= varName+fnOut00 
    fnOut=dirOut+fnOut0 ; file name to write output.
    print, fnOut    
    
    idOut = NCDF_CREATE(fnOut, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.  
    NCDF_CONTROL, idOut, /NOFILL ; Do not pre-fill the file to save time.
    
    xID= NCDF_DIMDEF(idOut, 'lon', nlon) ; Define x-dimension
    yID= NCDF_DIMDEF(idOut, 'lat', nlat) ; Define y-dimension
    tID= NCDF_DIMDEF(idOut, 'time', /UNLIMITED) ; Define time-dimension
   
    ; Define variables:
    lon_id_out = NCDF_VARDEF(idOut, lon_name, [xID], /DOUBLE)
    lat_id_out = NCDF_VARDEF(idOut, lat_name, [yID], /DOUBLE)
    time_id_out = NCDF_VARDEF(idOut, time_name, [tID], /LONG)
;    actual_id_out = NCDF_VARDEF(idOut, dataName, [xID,yID], /FLOAT)
;    anomal_id_out = NCDF_VARDEF(idOut, dataName+'_anom', [xID,yID], /FLOAT)
    perc_id_out = NCDF_VARDEF(idOut, varName, [xID,yID], /FLOAT)
    
    IF FixPer EQ 0 THEN global0_per= a1 ELSE global0_per= fyFnLTMread+'-'+lyFnLTMread              
;    globalTitle='Monthly values, anomalies and percentiles'
    globalTitle='Monthly percentiles' ; TMP ADDED TO REGENERATE PERC FILES   
;    globalDescr = 'This file includes three pieces of monthly information for ' + verb0 + ' of ' + a0 + ' ' + yr0 + '. These are actual values, anomalies and percentiles. ' + $ 
;              'The actual values are directly read from MERRA-2 collections on Discover; anomalies are calculated as actual values minus their corresponding long-term means (LTM)' + $
;              ' based on the baseline period ' + global0_per + ' using MERRA-2 ' + varName + ' data. ' + 'Percentiles are also computed based on the same period.'                   
    globalDescr = 'Percentile of monthly ' + varName + ' for ' + a0 + ' ' + yr0 + ' based on the period ' + global0_per + ' using MERRA-2 data.' ; TMP ADDED TO REGENERATE PERC FILES 


    NCDF_ATTPUT, idOut, /GLOBAL, 'Title', globalTitle, /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'Description', globalDescr, /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'Filename', fnOut0, /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'Institution', 'NASA Global Modeling and Assimilation Office', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'SpatialCoverage', 'global', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'SouthernmostLatitude', '-90.0', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'NorthernmostLatitude', '90.0', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'WesternmostLongitude', '-180', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'EasternmostLongitude', '179.375', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'LatitudeResolution', '0.5', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'LongitudeResolution', '0.625', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
    NCDF_ATTPUT, idOut, /GLOBAL, 'Contact', 'https://gmao.gsfc.nasa.gov', /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR

    NCDF_ATTPUT, idOut, lon_id_out, 'long_name', long_name_lon, /CHAR
    NCDF_ATTPUT, idOut, lon_id_out, 'units', units_lon, /CHAR
    NCDF_ATTPUT, idOut, lon_id_out, 'vmax', vmax_lon
    NCDF_ATTPUT, idOut, lon_id_out, 'vmin', vmin_lon
    NCDF_ATTPUT, idOut, lon_id_out, 'valid_range', range_lon

    NCDF_ATTPUT, idOut, lat_id_out, 'long_name', long_name_lat, /CHAR
    NCDF_ATTPUT, idOut, lat_id_out, 'units', units_lat, /CHAR
    NCDF_ATTPUT, idOut, lat_id_out, 'vmax', vmax_lat
    NCDF_ATTPUT, idOut, lat_id_out, 'vmin', vmin_lat
    NCDF_ATTPUT, idOut, lat_id_out, 'valid_range', range_lat

    NCDF_ATTPUT, idOut, time_id_out, 'long_name', long_name_time, /CHAR
    NCDF_ATTPUT, idOut, time_id_out, 'units', units_time, /CHAR
    NCDF_ATTPUT, idOut, time_id_out, 'time_increment', time_increment, /LONG
    NCDF_ATTPUT, idOut, time_id_out, 'begin_date', begin_date, /LONG
    NCDF_ATTPUT, idOut, time_id_out, 'begin_time', begin_time, /LONG
    NCDF_ATTPUT, idOut, time_id_out, 'vmax', vmax_time
    NCDF_ATTPUT, idOut, time_id_out, 'vmin', vmin_time
    NCDF_ATTPUT, idOut, time_id_out, 'valid_range', range_time

;    NCDF_ATTPUT, idOut, actual_id_out, 'long_name', long_name_data, /CHAR
;    NCDF_ATTPUT, idOut, actual_id_out, 'units', units_data, /CHAR
;    NCDF_ATTPUT, idOut, actual_id_out, 'valid_range', range_data

;    NCDF_ATTPUT, idOut, anomal_id_out, 'long_name', long_name_data+' anomaly', /CHAR
;    NCDF_ATTPUT, idOut, anomal_id_out, 'units', units_data, /CHAR
;    NCDF_ATTPUT, idOut, anomal_id_out, 'valid_range', range_data

    NCDF_ATTPUT, idOut, perc_id_out, 'long_name', 'Percentile', /CHAR
    NCDF_ATTPUT, idOut, perc_id_out, 'units', 'Percent', /CHAR
    NCDF_ATTPUT, idOut, perc_id_out, 'valid_range', [0.0, 99.9999], /FLOAT
    
    ; Put file in data mode:
    NCDF_CONTROL, idOut, /ENDEF
    
    ; Store data:
    NCDF_VARPUT, idOut, lon_id_out, lon
    NCDF_VARPUT, idOut, lat_id_out, lat
    NCDF_VARPUT, idOut, time_id_out, time
;    NCDF_VARPUT, idOut, actual_id_out, actual_data_out
;    NCDF_VARPUT, idOut, anomal_id_out, anomal_data_out
    NCDF_VARPUT, idOut, perc_id_out, perc_data_out
    NCDF_CLOSE, idOut ; Close the NetCDF file.
  ENDFOR
ENDIF
; ================================ END OF Store Monthly Outputs =============================================
; ===========================================================================================================










; ============================================================================================================
; ====================== Store Monthly Outputs: One file for each year/month/all variables ========================
; Outputs are stored in netcdf4 format, one file for each year/month/ all variables.
IF ncdfYN EQ 1 AND _day_mon EQ 'mon' AND FixPer EQ 0 OR FixPer EQ 2 AND subSet EQ 0 AND combVarYN EQ 1 THEN BEGIN
  IF nm GT 1 THEN BEGIN
    IF lm LT 9 THEN mo00= string(mo0, '0', lm+1, format='(a2, a1, a1, i1)') ELSE mo00= string(mo0, '0', lm+1, format='(a2, a1, i2)') ; add the last month in 2-digit format between 1-12, if nm > 1.
  ENDIF ELSE mo00=mo0  
  
  FOR iyr=0, ny-1 DO BEGIN
    actual_data_out=reform(data_used[*, *, iyr]) ; actual data read directly from MERRA-2 FILES.
    anomal_data_out=reform(anomal[*, *, iyr]) ; anomalies with respect to LTM calculated based on baseline period 1981-2010 (if FixPer=2) or a user-defined period (if FixPer=0).
    perc_data_out=reform(perc[*, *, iyr]) ; percentiles with respect to LTM calculated based on baseline period 1981-2010 (if FixPer=2) or a user-defined period (if FixPer=0).
    units_time=units_time0[iyr]
    begin_date=begin_date0[iyr]
    yr=fy+iyr
    yr0=string(yr, format='(i4)')
    
    IF ltmPer EQ 0 THEN ltmVerExt= '.' ELSE ltmVerExt= '.v2_0.'
    
    IF C_or_S EQ 'S_' THEN fnOut0='MERRA2.'+'stat'+C_or_S+_2d_3d+'_pct_'+_HV+ltmVerExt+yr0+mo0+'.nc4' ELSE fnOut0='MERRA2.'+'stat'+_freq+'_'+_2d_3d+'_pct_'+_HV+ltmVerExt+yr0+mo0+'.nc4'
;    fnOut0='MERRA2.'+'stat'+_freq+'_'+_2d_3d+'_pct_'+_HV+'.'+yr0+mo0+'.nc4'
;    IF _2d_3d EQ '3d' AND n_prs GT 1 THEN fnOut0= varName+prLevFN+fnOut00 ELSE fnOut0= varName+fnOut00 
    fnOut=dirOut+fnOut0 ; file name to write output.
    print, fnOut    
    
    gatt1=reform(gatt0)
    gatt=gatt1[iyr]
    
    
    IF varName EQ 'T2MMEAN' THEN long_name_data_out='Percentile for mean '    + long_name_data ELSE IF $
       varName EQ 'T2MMAX'  THEN long_name_data_out='Percentile for maximum ' + long_name_data ELSE IF $
       varName EQ 'T2MMIN'  THEN long_name_data_out='Percentile for minimum ' + long_name_data ELSE    $
                                 long_name_data_out='Percentile for ' + long_name_data

    
    IF iVar EQ 0 THEN BEGIN
      idOut = NCDF_CREATE(fnOut, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
      IF iyr EQ 0 THEN idOutAll=idout ELSE idOutAll=[idOutAll, idOut]
      
      NCDF_CONTROL, idOut, /NOFILL ; Do not pre-fill the file to save time.
      
      xID= NCDF_DIMDEF(idOut, 'lon', nlon) ; Define x-dimension
      yID= NCDF_DIMDEF(idOut, 'lat', nlat) ; Define y-dimension
      tID= NCDF_DIMDEF(idOut, 'time', /UNLIMITED) ; Define time-dimension
     
      ; Define variables:
      lon_id_out = NCDF_VARDEF(idOut, lon_name, [xID], /DOUBLE)
      lat_id_out = NCDF_VARDEF(idOut, lat_name, [yID], /DOUBLE)
      time_id_out = NCDF_VARDEF(idOut, time_name, [tID], /DOUBLE)
  ;    actual_id_out = NCDF_VARDEF(idOut, dataName, [xID,yID], /FLOAT)
  ;    anomal_id_out = NCDF_VARDEF(idOut, dataName+'_anom', [xID,yID], /FLOAT)
      
      IF FixPer EQ 0 THEN global0_per= a1 ELSE global0_per= fyFnLTMread+'-'+lyFnLTMread               
  ;    globalTitle='Monthly values, anomalies and percentiles'
  ;    globalDescr = 'This file includes three pieces of monthly information for ' + verb0 + ' of ' + a0 + ' ' + yr0 + '. These are actual values, anomalies and percentiles. ' + $ 
  ;              'The actual values are directly read from MERRA-2 collections on Discover; anomalies are calculated as actual values minus their corresponding long-term means (LTM)' + $
  ;              ' based on the baseline period ' + global0_per + ' using MERRA-2 ' + varName + ' data. ' + 'Percentiles are also computed based on the same period.'                   
      ;globalDescr = 'Percentile of monthly ' + varName + ' for ' + a0 + ' ' + yr0 + ' based on the period ' + global0_per + ' using MERRA-2 data.' ; TMP ADDED TO REGENERATE PERC FILES 
      
      
      IF C_or_S EQ 'C_' THEN mon_or_sea='Monthly' ELSE mon_or_sea='Seasonal ('+ seaName + ')'  
            
      globalDescr = 'Percentile of ' + mon_or_sea + ' MERRA-2 data based on the climatology period of ' + global0_per + '.'


      IF _2d_3d EQ '3d' THEN BEGIN
        shortNamePCT='M2SMNPPCT'
        globalTitle='MERRA-2 statM_3d_pct_Np: 3d, 3-Dimensional, ' + mon_or_sea + ' Percentiles based on ' + global0_per + '.' ;'Monthly percentiles'
        IdentifierProductDOI=''
      ENDIF ELSE BEGIN
        shortNamePCT='M2SMNXPCT'
        globalTitle='MERRA-2 statM_2d_pct_Nx: 2d, Single-Level, ' + mon_or_sea + ' Percentiles based on ' + global0_per + '.' ;'Monthly percentiles'
        IF ltmPer EQ 0 THEN IdentifierProductDOI_PCT='10.5067/JGAV2VDLRY9G' ELSE IdentifierProductDOI_PCT= '10.5067/FM4HEB84DL8C'
      ENDELSE

      IF ltmPer EQ 0 THEN verID= 'V1' ELSE verID= 'v2_0'
      
      NCDF_ATTPUT, idOut, /GLOBAL, 'ShortName', shortNamePCT, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'LongName', globalTitle, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'VersionID', verID, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Description', globalDescr, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'ProcessingLevel', 'Level 4', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'identifier_product_doi_authority', 'http://dx.doi.org/', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'identifier_product_doi', IdentifierProductDOI_PCT, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Conventions', 'CF-1.7', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Source', 'CVS tag: GEOSadas-5_12_4', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'MapProjection', 'Latitude-Longitude', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'DataSetQuality', 'A validation of the source dataset is provided in Gelaro et al. 2017 (https://doi.org/10.1175/JCLI-D-16-0758.1)', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'GranuleID', fnOut0, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'ProductionDateTime', 'File generated: ' + SYSTIME(/UTC) + ' GMT', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'RangeBeginningDate', gatt['RangeBeginningDate'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'RangeBeginningTime', gatt['RangeBeginningTime'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'RangeEndingDate', gatt['RangeEndingDate'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'RangeEndingTime', gatt['RangeEndingTime'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'SouthernmostLatitude', gatt['SouthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'NorthernmostLatitude', gatt['NorthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'WesternmostLongitude', gatt['WesternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'EasternmostLongitude', gatt['EasternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'SpatialCoverage', gatt['SpatialCoverage'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'LatitudeResolution', gatt['LatitudeResolution'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'LongitudeResolution', gatt['LongitudeResolution'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Title', globalTitle, /CHAR ;gatt['Title'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Filename', fnOut0, /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Institution', gatt['Institution'], /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
      NCDF_ATTPUT, idOut, /GLOBAL, 'Contact', gatt['Contact'], /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
      ;;;NCDF_ATTPUT, idOut, /GLOBAL, 'History', 'This granule/collection was reprocessed with corrected ocean buoy observations.', /CHAR

      actualRangeLon=[gatt['WesternmostLongitude'], gatt['EasternmostLongitude']]
      actualRangeLat=[gatt['SouthernmostLatitude'], gatt['NorthernmostLatitude']]
      
      NCDF_ATTPUT, idOut, lon_id_out, 'long_name', long_name_lon, /CHAR
      NCDF_ATTPUT, idOut, lon_id_out, 'actual_range', actualRangeLon, /FLOAT
      NCDF_ATTPUT, idOut, lon_id_out, 'standard_name', 'longitude', /CHAR
      ;;;;NCDF_ATTPUT, idOut, lon_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOut, lon_id_out, 'units', units_lon, /CHAR

      NCDF_ATTPUT, idOut, lat_id_out, 'long_name', long_name_lat, /CHAR
      NCDF_ATTPUT, idOut, lat_id_out, 'actual_range', actualRangeLat, /FLOAT
      NCDF_ATTPUT, idOut, lat_id_out, 'standard_name', 'latitude', /CHAR
      ;;;;NCDF_ATTPUT, idOut, lat_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOut, lat_id_out, 'units', units_lat, /CHAR

      NCDF_ATTPUT, idOut, time_id_out, 'long_name', long_name_time, /CHAR
      ;;;;NCDF_ATTPUT, idOut, time_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOut, time_id_out, 'calendar', 'standard', /CHAR
      NCDF_ATTPUT, idOut, time_id_out, 'units', units_time, /CHAR

  ;    NCDF_ATTPUT, idOut, actual_id_out, 'long_name', long_name_data, /CHAR
  ;    NCDF_ATTPUT, idOut, actual_id_out, 'units', units_data, /CHAR
  ;    NCDF_ATTPUT, idOut, actual_id_out, 'valid_range', range_data
  
  ;    NCDF_ATTPUT, idOut, anomal_id_out, 'long_name', long_name_data+' anomaly', /CHAR
  ;    NCDF_ATTPUT, idOut, anomal_id_out, 'units', units_data, /CHAR
  ;    NCDF_ATTPUT, idOut, anomal_id_out, 'valid_range', range_data
  
      ; Put file in data mode:
      NCDF_CONTROL, idOut, /ENDEF
    ENDIF ELSE idOut = idOutAll[iyr]

    perc_id_out = NCDF_VARDEF(idOut, varName, [xID,yID,tID], /FLOAT)
    NCDF_ATTPUT, idOut, perc_id_out, 'long_name', long_name_data_out, /CHAR
    NCDF_ATTPUT, idOut, perc_id_out, '_FillValue', FLOAT(-9999.), /FLOAT
    NCDF_ATTPUT, idOut, perc_id_out, 'units', 'Percent', /CHAR
    NCDF_ATTPUT, idOut, perc_id_out, 'valid_range', [0.0, 99.9999], /FLOAT
    
    ; Store data:
    NCDF_VARPUT, idOut, lon_id_out, lon
    NCDF_VARPUT, idOut, lat_id_out, lat
    NCDF_VARPUT, idOut, time_id_out, time
;    NCDF_VARPUT, idOut, actual_id_out, actual_data_out
;    NCDF_VARPUT, idOut, anomal_id_out, anomal_data_out
    NCDF_VARPUT, idOut, perc_id_out, perc_data_out
    IF iVar Eq nVar-1 THEN NCDF_CLOSE, idOut ; Close the NetCDF file.
  ENDFOR
ENDIF
; ================================ END OF Store Monthly Outputs =============================================
; ===========================================================================================================










; ============================================================================================================
; ================================ Store Monthly Outputs for Fixed Baseline Period (FixPer=1) ================
; Outputs are stored in netcdf4 format, one file for each year/month.
IF ncdfYN EQ 1 AND _day_mon EQ 'mon' AND FixPer EQ 1 AND subSet EQ 0 THEN BEGIN  

  FOR imo=0, nm-1 DO BEGIN
    mo=fm+imo
    mo00=amon(mo)

    units_time=units_time0[0]
    begin_date=begin_date0[0]
    yr=fy+iyr
    fixPerYrs=string(fy,'_',ly, format='(i4, a1, i4)')
    ClimPercFN0='_MERRA2.'+_time+_freq+'_'+_2d_3d+'_'+_group+'_'+_HV+'.nc4'
    IF _2d_3d EQ '3d' AND n_prs GT 1 THEN fnOutClim0= 'clim_'+fixPerYrs+'_' + mo00+ '_' + varName+prLevFN+ClimPercFN0 ELSE fnOutClim0= 'clim_'+fixPerYrs+'_' + mo00+ '_' + varName+ClimPercFN0
    IF _2d_3d EQ '3d' AND n_prs GT 1 THEN fnOutPerc0= 'perc_'+fixPerYrs+'_' + mo00+ '_' + varName+prLevFN+ClimPercFN0 ELSE fnOutPerc0= 'perc_'+fixPerYrs+'_' + mo00+ '_' + varName+ClimPercFN0

    fnOutClim=dirOut+fnOutClim0 ; climatology file name to write output.
    fnOutPerc=dirOut+fnOutPerc0 ; percentiles file name to write output.
    print, fnOutClim
    print, fnOutPerc
    ;stop
        

    ; ----------------------------- create climatology files (clim_1981_2010_xx) ------------------------------------------------
    idOutClim = NCDF_CREATE(fnOutClim, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
    NCDF_CONTROL, idOutClim, /NOFILL ; Do not pre-fill the file to save time.
  
    xID= NCDF_DIMDEF(idOutClim, 'lon', nlon) ; Define x-dimension
    yID= NCDF_DIMDEF(idOutClim, 'lat', nlat) ; Define y-dimension
;    tID= NCDF_DIMDEF(idOutClim, 'time', 1);/UNLIMITED) ; Define time-dimension

  
    ; Define variables:
    lon_id_out = NCDF_VARDEF(idOutClim, lon_name, [xID], /DOUBLE)
    lat_id_out = NCDF_VARDEF(idOutClim, lat_name, [yID], /DOUBLE)
;    time_id_out = NCDF_VARDEF(idOutClim, time_name, [tID], /LONG)
    ltm_id_out = NCDF_VARDEF(idOutClim, 'ltm', [xID,yID], /FLOAT)
    std_id_out = NCDF_VARDEF(idOutClim, 'std', [xID,yID], /FLOAT)
  
    globalClimTitle='Monthly long-term mean and standard deviation'
    globalClimDescr = 'This file includes long-term mean (climatology) and standard deviation of monthly ' + verb0 + ' of ' + a0 + ' over the baseline period ' + a1 + ' using MERRA-2 ' + varName + ' data.' + $
                  ' There is one file for each month, variable, and pressure level (if applicable). This file can be used for climatology plots and climate anomaly calculations.' 
    
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Title', globalClimTitle, /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Description', globalClimDescr, /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Filename', fnOutClim0, /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Institution', 'NASA Global Modeling and Assimilation Office', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'SpatialCoverage', 'global', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'SouthernmostLatitude', '-90.0', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'NorthernmostLatitude', '90.0', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'WesternmostLongitude', '-180', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'EasternmostLongitude', '179.375', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'LatitudeResolution', '0.5', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'LongitudeResolution', '0.625', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
    NCDF_ATTPUT, idOutClim, /GLOBAL, 'Contact', 'https://gmao.gsfc.nasa.gov', /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
  
    NCDF_ATTPUT, idOutClim, lon_id_out, 'long_name', long_name_lon, /CHAR
    NCDF_ATTPUT, idOutClim, lon_id_out, 'units', units_lon, /CHAR
    NCDF_ATTPUT, idOutClim, lon_id_out, 'vmax', vmax_lon
    NCDF_ATTPUT, idOutClim, lon_id_out, 'vmin', vmin_lon
    NCDF_ATTPUT, idOutClim, lon_id_out, 'valid_range', range_lon
  
    NCDF_ATTPUT, idOutClim, lat_id_out, 'long_name', long_name_lat, /CHAR
    NCDF_ATTPUT, idOutClim, lat_id_out, 'units', units_lat, /CHAR
    NCDF_ATTPUT, idOutClim, lat_id_out, 'vmax', vmax_lat
    NCDF_ATTPUT, idOutClim, lat_id_out, 'vmin', vmin_lat
    NCDF_ATTPUT, idOutClim, lat_id_out, 'valid_range', range_lat
  
;    NCDF_ATTPUT, idOutClim, time_id_out, 'long_name', long_name_time, /CHAR
;    NCDF_ATTPUT, idOutClim, time_id_out, 'units', units_time, /CHAR
;    NCDF_ATTPUT, idOutClim, time_id_out, 'time_increment', time_increment, /LONG
;    NCDF_ATTPUT, idOutClim, time_id_out, 'begin_date', begin_date, /LONG
;    NCDF_ATTPUT, idOutClim, time_id_out, 'begin_time', begin_time, /LONG
;    NCDF_ATTPUT, idOutClim, time_id_out, 'vmax', vmax_time
;    NCDF_ATTPUT, idOutClim, time_id_out, 'vmin', vmin_time
;    NCDF_ATTPUT, idOutClim, time_id_out, 'valid_range', range_time
    
    NCDF_ATTPUT, idOutClim, ltm_id_out, 'long_name', 'Long term mean (climatology)', /CHAR
    NCDF_ATTPUT, idOutClim, ltm_id_out, 'units', units_data, /CHAR
    NCDF_ATTPUT, idOutClim, ltm_id_out, 'valid_range', range_data

    NCDF_ATTPUT, idOutClim, std_id_out, 'long_name', 'Standard deviation', /CHAR
    NCDF_ATTPUT, idOutClim, std_id_out, 'units', units_data, /CHAR
    NCDF_ATTPUT, idOutClim, std_id_out, 'valid_range', range_data

    ; Put file in data mode:
    NCDF_CONTROL, idOutClim, /ENDEF
  
    ; Store data:
    NCDF_VARPUT, idOutClim, lon_id_out, lon
    NCDF_VARPUT, idOutClim, lat_id_out, lat
;    NCDF_VARPUT, idOutClim, time_id_out, time
    NCDF_VARPUT, idOutClim, ltm_id_out, ltmVals
    NCDF_VARPUT, idOutClim, std_id_out, stdVals
    NCDF_CLOSE, idOutClim ; Close the NetCDF file.
    ; ----------------------------- END OF create climatology files (clim_1981_2010_xx) ------------------------------------------------



    ; ----------------------------- create percentile files (perc_1981_2010_xx) ------------------------------------------------
    idOutPerc = NCDF_CREATE(fnOutPerc, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
    NCDF_CONTROL, idOutPerc, /NOFILL ; Do not pre-fill the file to save time.
  
    xID= NCDF_DIMDEF(idOutPerc, 'lon', nlon) ; Define x-dimension
    yID= NCDF_DIMDEF(idOutPerc, 'lat', nlat) ; Define y-dimension
;   tID= NCDF_DIMDEF(idOutPerc, 'time', /UNLIMITED) ; Define time-dimension
    pID= NCDF_DIMDEF(idOutPerc, 'percentiles', ny) ; Define dimension (number) of percentiles

  
    ; Define variables:
    lon_id_out = NCDF_VARDEF(idOutPerc, lon_name, [xID], /DOUBLE)
    lat_id_out = NCDF_VARDEF(idOutPerc, lat_name, [yID], /DOUBLE)
;    time_id_out = NCDF_VARDEF(idOutPerc, time_name, [tID], /LONG)
    perc_id_out = NCDF_VARDEF(idOutPerc, 'percentiles', [pID], /FLOAT)
    percVals_id_out = NCDF_VARDEF(idOutPerc, 'percVal', [xID,yID,pID], /FLOAT)
  
    globalPercTitle='Monthly percentiles'
    globalPercDescr = 'This file includes percentile values corresponding to various percentiles (e.g., 0, 3.33, 6.67, …, 96.67) of monthly ' + verb0 + ' of ' + a0 + ' over the baseline period ' + $
                   a1 + ' using MERRA-2 ' + varName + ' data.' + ' There is one file for each month, variable, and pressure level (if applicable).                    
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Title', globalPercTitle, /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Description', globalPercDescr, /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Filename', fnOutPerc0, /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Institution', 'NASA Global Modeling and Assimilation Office', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'SpatialCoverage', 'global', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'SouthernmostLatitude', '-90.0', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'NorthernmostLatitude', '90.0', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'WesternmostLongitude', '-180', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'EasternmostLongitude', '179.375', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'LatitudeResolution', '0.5', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'LongitudeResolution', '0.625', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
    NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Contact', 'https://gmao.gsfc.nasa.gov', /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
  
    NCDF_ATTPUT, idOutPerc, lon_id_out, 'long_name', long_name_lon, /CHAR
    NCDF_ATTPUT, idOutPerc, lon_id_out, 'units', units_lon, /CHAR
    NCDF_ATTPUT, idOutPerc, lon_id_out, 'vmax', vmax_lon
    NCDF_ATTPUT, idOutPerc, lon_id_out, 'vmin', vmin_lon
    NCDF_ATTPUT, idOutPerc, lon_id_out, 'valid_range', range_lon
  
    NCDF_ATTPUT, idOutPerc, lat_id_out, 'long_name', long_name_lat, /CHAR
    NCDF_ATTPUT, idOutPerc, lat_id_out, 'units', units_lat, /CHAR
    NCDF_ATTPUT, idOutPerc, lat_id_out, 'vmax', vmax_lat
    NCDF_ATTPUT, idOutPerc, lat_id_out, 'vmin', vmin_lat
    NCDF_ATTPUT, idOutPerc, lat_id_out, 'valid_range', range_lat
  
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'long_name', long_name_time, /CHAR
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'units', units_time, /CHAR
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'time_increment', time_increment, /LONG
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'begin_date', begin_date, /LONG
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'begin_time', begin_time, /LONG
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'vmax', vmax_time
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'vmin', vmin_time
;    NCDF_ATTPUT, idOutPerc, time_id_out, 'valid_range', range_time
    
    NCDF_ATTPUT, idOutPerc, perc_id_out, 'long_name', 'Percentile', /CHAR
    NCDF_ATTPUT, idOutPerc, perc_id_out, 'units', 'Percent', /CHAR
    NCDF_ATTPUT, idOutPerc, perc_id_out, 'valid_range', [0.0, 99.9999], /FLOAT

    NCDF_ATTPUT, idOutPerc, percVals_id_out, 'long_name', 'Percentile values', /CHAR
    NCDF_ATTPUT, idOutPerc, percVals_id_out, 'units', units_data, /CHAR
    NCDF_ATTPUT, idOutPerc, percVals_id_out, 'valid_range', range_data
  
    ; Put file in data mode:
    NCDF_CONTROL, idOutPerc, /ENDEF
  
    ; Store data:
    NCDF_VARPUT, idOutPerc, lon_id_out, lon
    NCDF_VARPUT, idOutPerc, lat_id_out, lat
;    NCDF_VARPUT, idOutPerc, time_id_out, time
    NCDF_VARPUT, idOutPerc, perc_id_out, perc0
    NCDF_VARPUT, idOutPerc, percVals_id_out, percVals
    NCDF_CLOSE, idOutPerc ; Close the NetCDF file.
    ; ----------------------------- END OF create percentile files (perc_1981_2010_xx) ------------------------------------------------
    
  ENDFOR
ENDIF
; ================================ END OF Store Monthly Outputs for Fixed Baseline Period (FixPer=1) ========
; ===========================================================================================================









; ============================================================================================================
; ===== Store Monthly Outputs for Fixed Baseline Period, multiple levels/variables (FixPer=3) ================
; Outputs are stored in netcdf4 format, one file for each year/month.

; NOTE: data type of the _FillValue must match the data type of the variable it will be an attribute of. 
; That is to say, if your variable (identified by variableID) is type FLOAT, then the _FillValue attribute must also be of type FLOAT. 

IF ncdfYN EQ 1 AND _day_mon EQ 'mon' AND FixPer EQ 3 AND subSet EQ 0 AND iPrsLoop EQ n_prs-1 THEN BEGIN  
  
  gatt=reform(gatt0)
  gattFyr=gatt[0] ; global attributes of first year
  gattLyr=gatt[ny-1] ; global attributes of last year

  ;;;actualRangeLon=gattFyr['WesternmostLongitude']+', '+gattFyr['EasternmostLongitude']
  ;;;actualRangeLat=gattFyr['SouthernmostLatitude']+', '+gattFyr['NorthernmostLatitude']
  
  actualRangeLon=[gattFyr['WesternmostLongitude'], gattFyr['EasternmostLongitude']]
  actualRangeLat=[gattFyr['SouthernmostLatitude'], gattFyr['NorthernmostLatitude']]

  ;;;actualRangeLev=string(strtrim(min(Xprs), 1), ', ', strtrim(max(Xprs), 1))
  actualRangeLev=[min(Xprs), max(Xprs)]
  

  ;;;;FOR imo=0, nm-1 DO BEGIN ; nm will be set to 1 in each month loop so it's trivial!?    
    ;;;mo=fm;;+imo
    ;;;mo00=amon(mo)
;    IF MonAutoLoop EQ 1 AND fm EQ lm THEN BEGIN ; write the months in 2-digit format between 1-12.
;      IF fm LT 9 THEN mo0= string('0', fm+1, format='(a1, i1)') ELSE mo0= string(fm+1, format='(i2)')
;      C_or_S='C_'
;    ENDIF ELSE IF MonAutoLoop EQ 0 THEN BEGIN ; for seasonal files
;      IF lm LT 9 THEN mo0= string('0', lm+1, format='(a1, i1)') ELSE mo0= string(lm+1, format='(i2)')    
;      _S='S_'       
;    ENDIF
    


    
    ; ----------------------------- create climatology files (clim_1981_2010_xx) ------------------------------------------------
    IF iVar EQ 0 THEN BEGIN ; storing common variables like lon, lat, lev (for climatology files). 
      units_time=units_time0[0]
      begin_date=begin_date0[0]
      
      ;;;yr=fy+iyr ! WRONG! because iyr comes here when it is nyr. check and remove!
      ;;;IF MonAutoLoop EQ 1 THEN fixPerYrs=string(fy,mo0,'_',ly,mo0, format='(i4, a2, a1, i4, a2)') ELSE fixPerYrs=seaName+string('_', fy,'_',ly, format='(a1, i4, a1, i4)')
      ;;;IF MonAutoLoop EQ 1 THEN fixPerYrs=string(fy,mo0,'_',ly,mo0, format='(i4, a2, a1, i4, a2)') ELSE fixPerYrs=seaName+string('_', fy,'_',ly, format='(a1, i4, a1, i4)')
      fixPerYrs=string(fy,mo0,'_',ly,mo0, format='(i4, a2, a1, i4, a2)')
;      IF _2d_3d EQ '2d' AND force2D EQ 0 AND nVar GT 1 THEN ClimPercFN0='_MERRA2.'+_time+_freq+'_'+_2d_3d+'_'+_HV+'.nc4' ELSE IF force2D EQ 1 THEN ClimPercFN0='_MERRA2.'+'tavg'+_freq+'_'+'2d'+'_'+'Nx'+'.nc4' $ 
;        ELSE ClimPercFN0='_MERRA2.'+_time+_freq+'_'+_2d_3d+'_'+_group+'_'+_HV+'.nc4'
;      fnOutClim0= 'clim_'+fixPerYrs+'_' + mo00+ ClimPercFN0

      IF a1 EQ '1981-2010' THEN verID= 'V1' ELSE IF a1 EQ '1991-2020' THEN verID= 'v2_0' ELSE verID= 'Vx'

      IF force2D EQ 1 THEN BEGIN
        IF a1 EQ '1981-2010' THEN fnOutClim0= 'MERRA2.tavg'+C_or_S+'2d'+'_ltm_'+'Nx'+'.'+fixPerYrs+'.nc4' ELSE fnOutClim0= 'MERRA2.tavg'+C_or_S+'2d'+'_ltm_'+'Nx'+'.'+verID + '.'+fixPerYrs+'.nc4'
      ENDIF ELSE BEGIN
        IF a1 EQ '1981-2010' THEN fnOutClim0= 'MERRA2.tavg'+C_or_S+_2d_3d+'_ltm_'+_HV+'.'+fixPerYrs+'.nc4' ELSE fnOutClim0= 'MERRA2.tavg'+C_or_S+_2d_3d+'_ltm_'+_HV+'.'+verID + '.'+fixPerYrs+'.nc4'
      ENDELSE 


      fnOutClim=dirOut+fnOutClim0 ; climatology file name to write output.     
      print, fnOutClim      
      
      idOutClim = NCDF_CREATE(fnOutClim, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
      NCDF_CONTROL, idOutClim, /NOFILL ; Do not pre-fill the file to save time.
    
      xID= NCDF_DIMDEF(idOutClim, 'lon', nlon) ; Define x-dimension
      yID= NCDF_DIMDEF(idOutClim, 'lat', nlat) ; Define y-dimension
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN zID= NCDF_DIMDEF(idOutClim, 'lev', n_prs) ; Define z-dimension  
      tID= NCDF_DIMDEF(idOutClim, 'time', /UNLIMITED) ; Define time-dimension
        
      ; Define variables:
      lon_id_out = NCDF_VARDEF(idOutClim, lon_name, [xID], /DOUBLE)
      lat_id_out = NCDF_VARDEF(idOutClim, lat_name, [yID], /DOUBLE)
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN lev_id_out = NCDF_VARDEF(idOutClim, lev_name, [zID], /DOUBLE)
      time_id_out = NCDF_VARDEF(idOutClim, time_name, [tID], /DOUBLE)
  

      IF C_or_S EQ 'C_' THEN mon_or_sea='Monthly' ELSE mon_or_sea='Seasonal ('+ seaName + ')'      

      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN
        globalClimDescr = 'This file includes long-term mean (climatology) and standard deviation of ' + mon_or_sea + ' values for ' + a01 + ' over the baseline period ' + a1 + ' using MERRA-2 data.' + $
        ' There is one file for each month that includes multiple variables at different pressure levels (if applicable). This file can be used for climatology plots and climate anomaly calculations.'
        shortNameLTM='M2TCNPLTM'
        globalClimTitle='MERRA-2 tavgC_3d_ltm_Np: 3d, Long Term Mean 3-Dimensional Meteorological Fields based on ' + a1 + '.' ;'Monthly long-term mean and standard deviation'
        IF a1 EQ '1981-2010' THEN IdentifierProductDOI_LTM='10.5067/HQR1D9MPSEJN' ELSE IdentifierProductDOI_LTM= '10.5067/QTDN06JJU27T'
      ENDIF ELSE BEGIN
        globalClimDescr = 'This file includes long-term mean (climatology) and standard deviation of ' + mon_or_sea + ' values for ' + a01 + ' over the baseline period ' + a1 + ' using MERRA-2 data.' + $
        ' There is one file for each month that includes multiple 2D variables. This file can be used for climatology plots and climate anomaly calculations.'
        shortNameLTM='M2TCNXLTM'
        globalClimTitle='MERRA-2 tavgC_2d_ltm_Nx: 2d, Single-Level, Long Term Mean Diagnostics based on ' + a1 + '.'
        IF a1 EQ '1981-2010' THEN IdentifierProductDOI_LTM='10.5067/HWSZE7YK7L81' ELSE IdentifierProductDOI_LTM='10.5067/5P9JKV0EB46M' 
      ENDELSE
      

      NCDF_ATTPUT, idOutClim, /GLOBAL, 'ShortName', shortNameLTM, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'LongName', globalClimTitle, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'VersionID', verID, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Description', globalClimDescr, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'ProcessingLevel', 'Level 4', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'identifier_product_doi_authority', 'http://dx.doi.org/', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'identifier_product_doi', IdentifierProductDOI_LTM, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Conventions', 'CF-1.7', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Source', 'CVS tag: GEOSadas-5_12_4', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'MapProjection', 'Latitude-Longitude', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'DataSetQuality', 'A validation of the source dataset is provided in Gelaro et al. 2017 (https://doi.org/10.1175/JCLI-D-16-0758.1)', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'GranuleID', fnOutClim0, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'ProductionDateTime', 'File generated: ' + SYSTIME(/UTC) + ' GMT', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'RangeBeginningDate', gattFyr['RangeBeginningDate'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'RangeBeginningTime', gattFyr['RangeBeginningTime'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'RangeEndingDate', gattLyr['RangeEndingDate'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'RangeEndingTime', gattLyr['RangeEndingTime'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'SouthernmostLatitude', gattFyr['SouthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'NorthernmostLatitude', gattFyr['NorthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'WesternmostLongitude', gattFyr['WesternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'EasternmostLongitude', gattFyr['EasternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'SpatialCoverage', gattFyr['SpatialCoverage'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'LatitudeResolution', gattFyr['LatitudeResolution'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'LongitudeResolution', gattFyr['LongitudeResolution'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Title', globalClimTitle, /CHAR ;gattFyr['Title'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Filename', fnOutClim0, /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Institution', gattFyr['Institution'], /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
      NCDF_ATTPUT, idOutClim, /GLOBAL, 'Contact', gattFyr['Contact'], /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
      ;;;NCDF_ATTPUT, idOutClim, /GLOBAL, 'History', 'This granule/collection was reprocessed with corrected ocean buoy observations.', /CHAR
        
      NCDF_ATTPUT, idOutClim, lon_id_out, 'long_name', long_name_lon, /CHAR
      NCDF_ATTPUT, idOutClim, lon_id_out, 'actual_range', actualRangeLon, /FLOAT
      NCDF_ATTPUT, idOutClim, lon_id_out, 'standard_name', 'longitude', /CHAR
      ;;;;NCDF_ATTPUT, idOutClim, lon_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutClim, lon_id_out, 'units', units_lon, /CHAR
      
      NCDF_ATTPUT, idOutClim, lat_id_out, 'long_name', long_name_lat, /CHAR
      NCDF_ATTPUT, idOutClim, lat_id_out, 'actual_range', actualRangeLat, /FLOAT
      NCDF_ATTPUT, idOutClim, lat_id_out, 'standard_name', 'latitude', /CHAR
      ;;;;NCDF_ATTPUT, idOutClim, lat_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutClim, lat_id_out, 'units', units_lat, /CHAR
  
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN        
        NCDF_ATTPUT, idOutClim, lev_id_out, 'long_name', long_name_lev, /CHAR
        NCDF_ATTPUT, idOutClim, lev_id_out, 'actual_range', actualRangeLev, /FLOAT ;/CHAR
        ;;;;NCDF_ATTPUT, idOutClim, lev_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
        NCDF_ATTPUT, idOutClim, lev_id_out, 'units', units_lev, /CHAR
      ENDIF
    
      NCDF_ATTPUT, idOutClim, time_id_out, 'long_name', long_name_time, /CHAR
      ;;;;NCDF_ATTPUT, idOutClim, time_id_out, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutClim, time_id_out, 'calendar', 'standard', /CHAR
      NCDF_ATTPUT, idOutClim, time_id_out, 'units', units_time, /CHAR      
      ;NCDF_ATTPUT, idOutClim, time_id_out, 'time_increment', time_increment, /LONG
      
      ; Put file in data mode:
      NCDF_CONTROL, idOutClim, /ENDEF
    
      ; Store common variables:
      NCDF_VARPUT, idOutClim, lon_id_out, lon
      NCDF_VARPUT, idOutClim, lat_id_out, lat
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN NCDF_VARPUT, idOutClim, lev_id_out, Xprs
      NCDF_VARPUT, idOutClim, time_id_out, time
    ENDIF ; end of storing common variables like lon, lat, lev (for climatology files).

    ; store data for each variable    
    IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN
;      ltm_id_out = NCDF_VARDEF(idOutClim, 'ltm_'+varNameOut, [xID,yID,zID, tID], /FLOAT)
      ltm_id_out = NCDF_VARDEF(idOutClim, varNameOut, [xID,yID,zID, tID], /FLOAT)
      std_id_out = NCDF_VARDEF(idOutClim, 'std_'+varNameOut, [xID,yID,zID, tID], /FLOAT)
    ENDIF ELSE BEGIN
;      ltm_id_out = NCDF_VARDEF(idOutClim, 'ltm_'+varNameOut, [xID,yID, tID], /FLOAT)
      ltm_id_out = NCDF_VARDEF(idOutClim, varNameOut, [xID,yID, tID], /FLOAT)
      std_id_out = NCDF_VARDEF(idOutClim, 'std_'+varNameOut, [xID,yID, tID], /FLOAT)
    ENDELSE
    
    
    NCDF_ATTPUT, idOutClim, ltm_id_out, 'long_name', 'Long_term_mean_(climatology)_of_' + long_name_data + '_(' + varNameOut + ')', /CHAR
    NCDF_ATTPUT, idOutClim, ltm_id_out, 'units', units_data, /CHAR
    NCDF_ATTPUT, idOutClim, ltm_id_out, '_FillValue', FLOAT(-9999.), /FLOAT

    NCDF_ATTPUT, idOutClim, std_id_out, 'long_name', 'Standard_deviation_of_'+ long_name_data + '_(' + varNameOut + ')', /CHAR
    NCDF_ATTPUT, idOutClim, std_id_out, 'units', units_data, /CHAR
    NCDF_ATTPUT, idOutClim, std_id_out, '_FillValue', FLOAT(-9999.), /FLOAT    
   
    NCDF_VARPUT, idOutClim, ltm_id_out, ltmValsAll
    NCDF_VARPUT, idOutClim, std_id_out, stdValsAll

    IF iVar EQ nVar-1 THEN NCDF_CLOSE, idOutClim ; Close the NetCDF file.
    ; ----------------------------- END OF create climatology files (clim_1981_2010_xx) ------------------------------------------------
    



    ; ----------------------------- create percentile files (perc_1981_2010_xx) ------------------------------------------------
    IF iVar EQ 0 THEN BEGIN ; storing common variables like lon, lat, lev (for percentile files).
      ;fnOutPerc0= 'perc_'+fixPerYrs+'_' + mo00+ ClimPercFN0      
      IF force2D EQ 1 THEN BEGIN
        IF a1 EQ '1981-2010' THEN fnOutPerc0= 'MERRA2.tavg'+C_or_S+'2d'+'_pct_'+'Nx'+'.'+fixPerYrs+'.nc4' ELSE fnOutPerc0= 'MERRA2.tavg'+C_or_S+'2d'+'_pct_'+'Nx'+'.'+verID + '.'+fixPerYrs+'.nc4'
      ENDIF ELSE BEGIN
        IF a1 EQ '1981-2010' THEN fnOutPerc0= 'MERRA2.tavg'+C_or_S+_2d_3d+'_pct_'+_HV+'.'+fixPerYrs+'.nc4' ELSE fnOutPerc0= 'MERRA2.tavg'+C_or_S+_2d_3d+'_pct_'+_HV+'.'+verID + '.'+fixPerYrs+'.nc4'
      ENDELSE

      
      fnOutPerc=dirOut+fnOutPerc0 ; percentile file name to write output.
      print, fnOutPerc

      idOutPerc = NCDF_CREATE(fnOutPerc, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
      NCDF_CONTROL, idOutPerc, /NOFILL ; Do not pre-fill the file to save time.
      
      xID1= NCDF_DIMDEF(idOutPerc, 'lon', nlon) ; Define x-dimension
      yID1= NCDF_DIMDEF(idOutPerc, 'lat', nlat) ; Define y-dimension
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN zID1= NCDF_DIMDEF(idOutPerc, 'lev', n_prs) ; Define z-dimension
      pID1= NCDF_DIMDEF(idOutPerc, 'percentiles', ny) ; Define percentiles dimension
      tID1= NCDF_DIMDEF(idOutPerc, 'time', /UNLIMITED) ; Define time-dimension
      
      
      ; Define variables:
      lon_id_out1 = NCDF_VARDEF(idOutPerc, lon_name, [xID1], /DOUBLE)
      lat_id_out1 = NCDF_VARDEF(idOutPerc, lat_name, [yID1], /DOUBLE)
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN lev_id_out1 = NCDF_VARDEF(idOutPerc, lev_name, [zID1], /DOUBLE)
      perc_id_out1 = NCDF_VARDEF(idOutPerc, 'percentiles', [pID1], /DOUBLE)
      time_id_out1 = NCDF_VARDEF(idOutPerc, time_name, [tID1], /DOUBLE)
      
      
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN
        globalPercDescr = 'This file includes percentiles of ' + mon_or_sea + ' values for ' + a01 + ' over the baseline period ' + a1 + ' using MERRA-2 data.' + $
          ' There is one file for each month that includes multiple variables at different pressure levels (if applicable). This file can be used for percentile calculations and plots.'
        shortNamePCT='M2SMNPPCT'
        globalPercTitle='MERRA-2 statM_3d_pct_Np: 3d, 3-Dimensional, ' + mon_or_sea + ' Percentiles' ;'Monthly percentiles'
        IdentifierProductDOI_PCT=''
      ENDIF ELSE BEGIN
        globalPercDescr = 'This file includes percentiles of '+ mon_or_sea + ' values for ' + a01 + ' over the baseline period ' + a1 + ' using MERRA-2 data.' + $
          ' There is one file for each month that includes multiple 2D variables. This file can be used for percentile calculations and plots.'
        shortNamePCT='M2SMNXPCT'
        globalPercTitle='MERRA-2 statM_2d_pct_Nx: 2d, Single-Level, ' + mon_or_sea + ' Percentiles' ;'Monthly percentiles'
        IdentifierProductDOI_PCT='10.5067/JGAV2VDLRY9G'
      ENDELSE

      IF a1 EQ '1981-2010' THEN verID= 'V1' ELSE IF a1 EQ '1991-2020' THEN verID= 'v2_0' ELSE verID= 'Vx'
      
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'ShortName', shortNamePCT, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'LongName', globalPercTitle, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'VersionID', verID, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Description', globalPercDescr, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'ProcessingLevel', 'Level 4', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'identifier_product_doi_authority', 'http://dx.doi.org/', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'identifier_product_doi', IdentifierProductDOI_PCT, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Conventions', 'CF-1.7', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Source', 'CVS tag: GEOSadas-5_12_4', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'MapProjection', 'Latitude-Longitude', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'DataSetQuality', 'A validation of the source dataset is provided in Gelaro et al. 2017 (https://doi.org/10.1175/JCLI-D-16-0758.1)', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'GranuleID', fnOutPerc0, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'ProductionDateTime', 'File generated: ' + SYSTIME(/UTC) + ' GMT', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'RangeBeginningDate', gattFyr['RangeBeginningDate'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'RangeBeginningTime', gattFyr['RangeBeginningTime'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'RangeEndingDate', gattLyr['RangeEndingDate'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'RangeEndingTime', gattLyr['RangeEndingTime'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'SouthernmostLatitude', gattFyr['SouthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'NorthernmostLatitude', gattFyr['NorthernmostLatitude'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'WesternmostLongitude', gattFyr['WesternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'EasternmostLongitude', gattFyr['EasternmostLongitude'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'SpatialCoverage', gattFyr['SpatialCoverage'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'LatitudeResolution', gattFyr['LatitudeResolution'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'LongitudeResolution', gattFyr['LongitudeResolution'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Title', globalPercTitle, /CHAR ;gattFyr['Title'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Filename', fnOutPerc0, /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Institution', gattFyr['Institution'], /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
      NCDF_ATTPUT, idOutPerc, /GLOBAL, 'Contact', gattFyr['Contact'], /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
      ;;;NCDF_ATTPUT, idOutPerc, /GLOBAL, 'History', 'This granule/collection was reprocessed with corrected ocean buoy observations.', /CHAR

      NCDF_ATTPUT, idOutPerc, lon_id_out1, 'long_name', long_name_lon, /CHAR
      NCDF_ATTPUT, idOutPerc, lon_id_out, 'actual_range', actualRangeLon, /FLOAT
      NCDF_ATTPUT, idOutPerc, lon_id_out, 'standard_name', 'longitude', /CHAR
      ;;;;NCDF_ATTPUT, idOutPerc, lon_id_out1, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutPerc, lon_id_out1, 'units', units_lon, /CHAR

      NCDF_ATTPUT, idOutPerc, lat_id_out1, 'long_name', long_name_lat, /CHAR
      NCDF_ATTPUT, idOutPerc, lat_id_out, 'actual_range', actualRangeLat, /FLOAT
      NCDF_ATTPUT, idOutPerc, lat_id_out, 'standard_name', 'latitude', /CHAR
      ;;;;NCDF_ATTPUT, idOutPerc, lat_id_out1, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutPerc, lat_id_out1, 'units', units_lat, /CHAR
      
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN
        NCDF_ATTPUT, idOutPerc, lev_id_out1, 'long_name', long_name_lev, /CHAR
        NCDF_ATTPUT, idOutPerc, lev_id_out, 'actual_range', actualRangeLev, /FLOAT
        ;;;;NCDF_ATTPUT, idOutPerc, lev_id_out1, '_FillValue', DOUBLE(-9999.), /DOUBLE        
        NCDF_ATTPUT, idOutPerc, lev_id_out1, 'units', units_lev, /CHAR
      ENDIF

      NCDF_ATTPUT, idOutPerc, perc_id_out1, 'long_name', 'Percentile', /CHAR
      NCDF_ATTPUT, idOutPerc, perc_id_out1, '_FillValue', DOUBLE(-9999.), /DOUBLE      
      NCDF_ATTPUT, idOutPerc, perc_id_out1, 'units', 'Percent', /CHAR
      NCDF_ATTPUT, idOutPerc, perc_id_out1, 'vmax', 99.9999, /FLOAT
      NCDF_ATTPUT, idOutPerc, perc_id_out1, 'vmin', 0.0, /FLOAT

      NCDF_ATTPUT, idOutPerc, time_id_out1, 'long_name', long_name_time, /CHAR
      ;;;;NCDF_ATTPUT, idOutPerc, time_id_out1, '_FillValue', DOUBLE(-9999.), /DOUBLE
      NCDF_ATTPUT, idOutPerc, time_id_out1, 'calendar', 'standard', /CHAR
      NCDF_ATTPUT, idOutPerc, time_id_out1, 'units', units_time, /CHAR      
      ;NCDF_ATTPUT, idOutPerc, time_id_out1, 'time_increment', time_increment, /LONG

      ; Put file in data mode:
      NCDF_CONTROL, idOutPerc, /ENDEF

      ; Store common variables:
      NCDF_VARPUT, idOutPerc, lon_id_out1, lon
      NCDF_VARPUT, idOutPerc, lat_id_out1, lat
      NCDF_VARPUT, idOutPerc, perc_id_out1, perc0
      IF _2d_3d EQ '3d' AND force2D EQ 0 THEN NCDF_VARPUT, idOutPerc, lev_id_out1, Xprs
      NCDF_VARPUT, idOutPerc, time_id_out1, time
    ENDIF ; end of storing common variables like lon, lat, lev (for percentile files).

    ; store data for each variable
    IF _2d_3d EQ '3d' AND force2D EQ 0 THEN BEGIN
      perVal_id_out = NCDF_VARDEF(idOutPerc, 'per_'+varNameOut, [xID1,yID1,zID1, pID1, tID1], /FLOAT)
    ENDIF ELSE BEGIN
      perVal_id_out = NCDF_VARDEF(idOutPerc, 'per_'+varNameOut, [xID1,yID1,pID1, tID1], /FLOAT)
    ENDELSE

    NCDF_ATTPUT, idOutPerc, perVal_id_out, 'long_name', 'Percentile_of_'+ long_name_data + '_(' + varNameOut + ')', /CHAR
    NCDF_ATTPUT, idOutPerc, perVal_id_out, '_FillValue', FLOAT(-9999.), /FLOAT
    NCDF_ATTPUT, idOutPerc, perVal_id_out, 'units', units_data, /CHAR

    NCDF_VARPUT, idOutPerc, perVal_id_out, percValsAll

    IF iVar EQ nVar-1 THEN NCDF_CLOSE, idOutPerc ; Close the NetCDF file.
    ; ----------------------------- END OF create percentile files (perc_1981_2010_xx) ------------------------------------------------


  ;;;;ENDFOR
ENDIF
; ===== END OF Store Monthly Outputs for Fixed Baseline Period, multiple levels/variables (FixPer=3) ========
; ===========================================================================================================












; ============================================================================================================
; ================================= Store a Subset of Daily Variables ========================================
; Outputs are stored in netcdf4 format, one file for each year/month.
IF ncdfYN EQ 1 AND _day_mon EQ 'day' AND FixPer EQ 3 AND subSet EQ 1 AND iPrsLoop EQ n_prs-1 AND MonAutoLoop EQ 1 AND force2D EQ 1 THEN BEGIN  
  ; NOTE:
  ; -- for now it works only with MonAutoLoop=1 & force2D=1 
  
  IF iVar EQ 0 THEN BEGIN
    dataAllVars=[data] 
    units_dataAll=[[units_data]]
    varNameOutAll=[[varNameOut]]
    long_name_dataAll=[long_name_data]
  ENDIF ELSE BEGIN
    dataAllVars=[[dataAllVars], [data]]
    units_dataAll=[[units_dataAll], [units_data]]
    varNameOutAll=[[varNameOutAll], [varNameOut]]
    long_name_dataAll=[[long_name_dataAll], [long_name_data]]
  ENDELSE
  
  
  
  IF iVar EQ nVar-1 THEN BEGIN ; ----------------------------- create output files (subSet_xx) ------------------------------------------------
    dataAllVars=reform(dataAllVars,nlon, nlat, nVar, nDaysAll)
    
    FOR iyr=0, ny-1 DO BEGIN ; years loop
      yr00=string(fy+iyr, format='(i4)')

      ; storing common variables like lon, lat, lev.
      fnOutSubset0= 'subSet_MERRA2_Daily_' + yr00+ mo0+ '.nc4' 
      fnOutSubset=dirOut+fnOutSubset0 ; climatology file name to write output.     
      print, fnOutSubset      
      
      idOutSub = NCDF_CREATE(fnOutSubset, /NOCLOBBER, /NETCDF4_FORMAT) ; Create a nc4 file.
      NCDF_CONTROL, idOutSub, /NOFILL ; Do not pre-fill the file to save time.
      
      ntSub=DayPerYrAll[iyr+1]-DayPerYrAll[iyr]
      xID= NCDF_DIMDEF(idOutSub, 'lon', nlon) ; Define x-dimension
      yID= NCDF_DIMDEF(idOutSub, 'lat', nlat) ; Define y-dimension
      tID= NCDF_DIMDEF(idOutSub, 'time', ntSub);/UNLIMITED) ; Define time-dimension
    
      ; Define variables:
      lon_id_out = NCDF_VARDEF(idOutSub, lon_name, [xID], /DOUBLE)
      lat_id_out = NCDF_VARDEF(idOutSub, lat_name, [yID], /DOUBLE)
      time_id_out = NCDF_VARDEF(idOutSub, time_name, [tID], /DOUBLE)
  
      globalSubTitle='Daily subset of MERRA-2 variables'
      globalSubDescr = 'This file includes MERRA-2 daily data for ' + a01 + '' + yr00  + '.'

      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Title', globalSubTitle, /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Description', globalSubDescr, /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Filename', fnOutSubset0, /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Institution', 'NASA Global Modeling and Assimilation Office', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Format', 'NetCDF-4', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'SpatialCoverage', 'global', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'SouthernmostLatitude', '-90.0', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'NorthernmostLatitude', '90.0', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'WesternmostLongitude', '-180', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'EasternmostLongitude', '179.375', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'LatitudeResolution', '0.5', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'LongitudeResolution', '0.625', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'DataResolution', '0.5 x 0.625', /CHAR
      NCDF_ATTPUT, idOutSub, /GLOBAL, 'Contact', 'https://gmao.gsfc.nasa.gov', /CHAR ;'Amin Dezfuli: amin.dezfuli@nasa.gov', /CHAR
    
      NCDF_ATTPUT, idOutSub, lon_id_out, 'long_name', long_name_lon, /CHAR
      NCDF_ATTPUT, idOutSub, lon_id_out, 'units', units_lon, /CHAR
      NCDF_ATTPUT, idOutSub, lon_id_out, 'vmax', vmax_lon
      NCDF_ATTPUT, idOutSub, lon_id_out, 'vmin', vmin_lon
      NCDF_ATTPUT, idOutSub, lon_id_out, 'valid_range', range_lon
    
      NCDF_ATTPUT, idOutSub, lat_id_out, 'long_name', long_name_lat, /CHAR
      NCDF_ATTPUT, idOutSub, lat_id_out, 'units', units_lat, /CHAR
      NCDF_ATTPUT, idOutSub, lat_id_out, 'vmax', vmax_lat
      NCDF_ATTPUT, idOutSub, lat_id_out, 'vmin', vmin_lat
      NCDF_ATTPUT, idOutSub, lat_id_out, 'valid_range', range_lat

      NCDF_ATTPUT, idOutSub, time_id_out, 'long_name', 'days since ' + begin_date0[iyr], /CHAR
      NCDF_ATTPUT, idOutSub, time_id_out, 'units', 'day', /CHAR
      NCDF_ATTPUT, idOutSub, time_id_out, 'begin_date', begin_date0[iyr], /LONG
      NCDF_ATTPUT, idOutSub, time_id_out, 'vmax', vmax_time
      NCDF_ATTPUT, idOutSub, time_id_out, 'vmin', vmin_time
      NCDF_ATTPUT, idOutSub, time_id_out, 'valid_range', range_time

      
      ; Put file in data mode:
      NCDF_CONTROL, idOutSub, /ENDEF
    
      ; Store common variables:
      NCDF_VARPUT, idOutSub, lon_id_out, lon
      NCDF_VARPUT, idOutSub, lat_id_out, lat
      NCDF_VARPUT, idOutSub, time_id_out, time
      ; end of storing common variables like lon, lat, lev (for climatology files).

      ; store data for each variable -------------------   
      FOR iVar=0, nVar-1 DO BEGIN ; variables loop
        var_id_out = NCDF_VARDEF(idOutSub, varNameOutAll[iVar], [xID,yID, tID], /FLOAT)
      
        NCDF_ATTPUT, idOutSub, var_id_out, 'long_name', long_name_dataAll[iVar], /CHAR
        NCDF_ATTPUT, idOutSub, var_id_out, 'units', units_dataAll[iVar], /CHAR
        NCDF_ATTPUT, idOutSub, var_id_out, 'valid_range', range_data
        NCDF_ATTPUT, idOutSub, var_id_out, '_FillValue', fillVal
        NCDF_ATTPUT, idOutSub, var_id_out, 'missing_value', missVal
        NCDF_ATTPUT, idOutSub, var_id_out, 'fmissing_value', fmissVal     
        NCDF_VARPUT, idOutSub, var_id_out, reform(dataAllVars[*, *, iVar, DayPerYrAll[iyr]:DayPerYrAll[iyr+1]-1])  
      ENDFOR ; END OF variables loop ------------------- 
            
      NCDF_CLOSE, idOutSub ; Close the NetCDF file.      
    ENDFOR ; END OF years loop    
  ENDIF ; ----------------------------- END OF create output files (subSet_xx) ------------------------------------------------
  
ENDIF
; ================================= END OF Store a Subset of Daily Variables ================================
; ===========================================================================================================











; ============================================================================================================
; ================================ Loop over multiple pressure levels ========================================
IF _2d_3d EQ '3d' AND n_prs GT 1 AND iPrsLoop LT n_prs-1 THEN BEGIN
  iPrsLoop++
  GOTO, DoNextPrsLev
ENDIF
; ================================ END OF Loop over multiple pressure levels =================================
; ============================================================================================================






; ============================================================================================================
; ================================ Loop over multiple variables ==============================================
IF iVar LT nVar-1 THEN BEGIN
  iVar++
  GOTO, DO_LOOP_var
ENDIF
; ================================ END OF Loop over multiple variables =======================================
; ============================================================================================================





; ============================================================================================================
; ================================ Loop over multiple months =================================================
IF MonAutoLoop EQ 1 AND iMonLoop LT nm_NCDF-1 THEN BEGIN
  iMonLoop++
  GOTO, DO_LOOP_mon
ENDIF
; ================================ END OF Loop over multiple months ==========================================
; ============================================================================================================


print, ""
print, "****************************************************************************************************************************"
IF MonAutoLoop EQ 0 THEN $
  print, "************************* Seasonal percentile file has been successfully generated for " + seaName + " *********************************" $
ELSE IF MonAutoLoop EQ 1 THEN $
  print, "************************* Monthly percentile file has been successfully generated for " + a01 + " *********************************"
print, "****************************************************************************************************************************"
print, ""
  
stop
END

















;**********************************************************************************************************************************************************************
;***************************************************************** FUNCTION: TIME SERIES DATES ************************************************************************
;**********************************************************************************************************************************************************************
FUNCTION TIME_SER, FY=fyr_ts, LY=lyr_ts, FM=fmon_ts, LM=lmon_ts, ND=nday_mean, FD=fday_ts, CT=cont_YN, AS=AnnCyc, GCM=gcm

; This function is used when we want to produce a time series. It reads first/last year and month, and an interval length to generate
;a continous set of dates used in composite function.
;;;IF AnnCyc  EQ 'yes' THEN cont_YN='no' ; just a check
month_len= [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] ; number of days in each month
IF fmon_ts LE lmon_ts THEN ny_ltm= lyr_ts-fyr_ts+1 ELSE ny_ltm= lyr_ts-fyr_ts
yrs= indgen(ny_ltm)+fyr_ts
  
IF nday_mean EQ 'mon' THEN BEGIN ; for time series of monthly means
  IF cont_YN EQ 'no' THEN BEGIN 
    IF fmon_ts LE lmon_ts THEN n_mo= lmon_ts -fmon_ts +1 ELSE n_mo= 12-fmon_ts + lmon_ts +1 & n_seg=n_mo*ny_ltm
    seg=-1 & date=intarr(5, n_seg) & yr_add=0
    FOR i_yr=0, ny_ltm-1 DO BEGIN
      IF ((yrs[i_yr] MOD 4 EQ 0 AND fmon_ts LE lmon_ts AND gcm EQ 'no') OR $
            ((yrs[i_yr]+1) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts GT 1 AND gcm EQ 'no') OR $
            ((yrs[i_yr]) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts EQ 1 AND gcm EQ 'no')) $
            THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year
      FOR i_mon=0, n_mo-1 DO BEGIN
        seg++
        IF (fmon_ts LE lmon_ts OR i_mon LE (11-fmon_ts)) THEN m=(fmon_ts+ i_mon) MOD 12 ELSE m=i_mon - (12-fmon_ts)
        IF fmon_ts GT lmon_ts THEN date[*, seg]=[yrs[0]+yr_add, m, m, 0, month_len[m]-1] ELSE date[*, seg]=[yrs[i_yr], m, m, 0, month_len[m]-1]
        IF (m EQ 11 AND fmon_ts GT lmon_ts) THEN yr_add=yr_add+1
      ENDFOR
    ENDFOR
    
  ENDIF ELSE BEGIN  ;for time series of monthly means when cont_YN = 'yes'
    ny_ltm= lyr_ts-fyr_ts+1 & n_mo= (ny_ltm-2)*12 + (12-fmon_ts)+ (lmon_ts+1) & n_seg=n_mo
    yrs= indgen(ny_ltm)+fyr_ts & seg=-1 & date=intarr(5, n_seg) & yr_add=0
    FOR i_mon=0, n_mo-1 DO BEGIN
      seg++
      IF (yrs[yr_add] MOD 4 EQ 0 AND gcm EQ 'no') THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
      IF i_mon LT (12-fmon_ts) OR (i_mon MOD 12) LT (12-fmon_ts) THEN m=(i_mon MOD 12)+fmon_ts ELSE m=(i_mon MOD 12) - (12-fmon_ts)
      date[*, seg]=[yrs[0]+yr_add, m, m, 0, month_len[m]-1]
      IF m EQ 11 THEN yr_add=yr_add+1
    ENDFOR
  ENDELSE
ENDIF ELSE IF nday_mean EQ 'sea' THEN BEGIN ; for time series of seasonal totals: one value per season.
  n_seg=ny_ltm
  seg=-1 & date=intarr(5, n_seg) & yr_add=0
  FOR i_yr=0, ny_ltm-1 DO BEGIN
    IF ((yrs[i_yr] MOD 4 EQ 0 AND fmon_ts LE lmon_ts AND gcm EQ 'no') OR $
        ((yrs[i_yr]+1) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts GT 1 AND gcm EQ 'no') OR $
        ((yrs[i_yr]) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts EQ 1 AND gcm EQ 'no')) $
        THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year
    seg++
    date[*, seg]=[yrs[i_yr], fmon_ts, lmon_ts, 0, month_len[lmon_ts]-1]
  ENDFOR
ENDIF ELSE BEGIN ; for when nday_mean is a number not 'mon' or 'sea'.

  tot_day=0 & tot2=0 & day2=-1
  IF cont_YN EQ 'no' THEN BEGIN ; =============================================================================================
    IF fmon_ts LE lmon_ts THEN n_mo= lmon_ts -fmon_ts +1 ELSE n_mo= 12-fmon_ts + lmon_ts +1
    FOR i_yr1=0, ny_ltm-1 DO BEGIN
      ;;;;;;IF ((yrs[i_yr1] MOD 4 EQ 0 AND fmon_ts LE lmon_ts AND gcm EQ 'no') OR ((yrs[i_yr1]+1) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND gcm EQ 'no')) $
      IF ((yrs[i_yr1] MOD 4 EQ 0 AND fmon_ts LE lmon_ts AND gcm EQ 'no') OR $
          ((yrs[i_yr1]+1) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts GT 1 AND gcm EQ 'no') OR $
          ((yrs[i_yr1]) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts EQ 1 AND gcm EQ 'no')) $
          THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
      IF AnnCyc  EQ 'yes' THEN month_len[1]= 28                                                                                                                                     ; except for AnnCyc='yes' in which case Feb 29 is removed from leap years.
      IF fmon_ts LE lmon_ts THEN tot1=TOTAL(month_len[fmon_ts:lmon_ts])-fday_ts ELSE tot1=TOTAL(month_len[fmon_ts:11])+TOTAL(month_len[0:lmon_ts])-fday_ts
      IF nday_mean GT 1 THEN off=tot1-(fix(tot1/nday_mean)*nday_mean) ELSE off=0
      IF off GT .5*nday_mean THEN BEGIN & add_d= nday_mean-off & add_m=1 & ENDIF ELSE BEGIN & add_d=0 & add_m=0 & ENDELSE
      if add_m eq 1 then tot_day = tot_day+ tot1+add_d ELSE tot_day = tot_day+ tot1 - off
      ;print, tot_day
    ENDFOR
    
    day=-1 & seg=-1 & n_seg = tot_day/nday_mean & date=intarr(5, n_seg) & m1=0 & m2=0 & yr_add=0
    FOR i_yr=0, ny_ltm-1 DO BEGIN ; !!! repeat for all years !!!
      IF ((yrs[i_yr] MOD 4 EQ 0 AND fmon_ts LE lmon_ts AND gcm EQ 'no') OR $
          ((yrs[i_yr]+1) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts GT 1 AND gcm EQ 'no') OR $
          ((yrs[i_yr]) MOD 4 EQ 0 AND fmon_ts GT lmon_ts AND fmon_ts EQ 1 AND gcm EQ 'no')) $ 
          THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
      IF AnnCyc  EQ 'yes' THEN month_len[1]= 28                                                                                                                                     ; except for AnnCyc='yes' in which case Feb 29 is removed from leap years.
      IF fmon_ts LE lmon_ts THEN tot1=TOTAL(month_len[fmon_ts:lmon_ts])-fday_ts ELSE tot1=TOTAL(month_len[fmon_ts:11])+TOTAL(month_len[0:lmon_ts])-fday_ts
      IF nday_mean GT 1 THEN off=tot1-(fix(tot1/nday_mean)*nday_mean) ELSE off=0
      IF off GT .5*nday_mean THEN BEGIN & add_d= nday_mean-off & add_m=1 & ENDIF ELSE BEGIN & add_d=0 & add_m=0 & ENDELSE
      
      FOR i_mon=0, n_mo+add_m-1 DO BEGIN ; !!! repeat for all months !!!
        ;;;;IF (fmon_ts LE lmon_ts OR i_mon LE (11-fmon_ts)) THEN m=(fmon_ts+ i_mon) MOD 12 ELSE m=(i_mon MOD 11) - (12-fmon_ts)
        IF (fmon_ts LE lmon_ts OR i_mon LE (11-fmon_ts)) THEN m=(fmon_ts+ i_mon) MOD 12 ELSE m=i_mon - (12-fmon_ts)
        if (i_mon eq n_mo+add_m-1 and add_m ne 0) then n_day=add_d
        if (i_mon eq n_mo+add_m-1 and add_m eq 0) then n_day=month_len[m]-off
        if i_mon lt n_mo+add_m-1 then n_day=month_len[m]
        if (i_mon eq 0 and fday_ts ne 0) then begin & n_day=month_len[m]-fday_ts & fd_off=fday_ts & endif else begin & fd_off=0 & endelse
        
        FOR i_day=0, n_day-1 DO BEGIN   ; !!! repeat for all days !!!
          day+=1
          IF day MOD nday_mean EQ 0 THEN BEGIN & m1=m & day1=i_day+fd_off & seg++ & ENDIF
          IF day MOD nday_mean EQ nday_mean-1 THEN BEGIN & m2=m & day2=i_day+fd_off & IF fmon_ts LE lmon_ts THEN yrr=i_yr ELSE yrr=0 & date[*, seg]=[yrs[yrr]+yr_add, m1, m2, day1, day2] & ENDIF
          ;;;; XXXXXX IF day MOD nday_mean EQ nday_mean-1 THEN BEGIN & m2=m & day2=i_day+fd_off & IF fmon_ts LE lmon_ts THEN yrr=i_yr ELSE yrr=0 & date[*, seg]=[yrs[yrr], m1, m2, day1, day2] & ENDIF
          IF m EQ 0 AND m1 EQ 11 AND m2 EQ 0 THEN yr_add=yr_add+1
          IF day MOD nday_mean EQ 0 AND m2 EQ 11 AND day2 EQ 30 AND fmon_ts GT lmon_ts THEN yr_add=yr_add+1
        ENDFOR ;  !!! end of the loop: repeat for all days !!!
        ;;;stop
      ENDFOR    ;  !!! end of the loop: repeat for all months  !!!
    ENDFOR    ;  !!! end of the loop: repeat for all years  !!!
    ;;;stop
  ENDIF ELSE BEGIN ; that is for when cont_YN='yes' ===========================================================================
    ny_ltm= lyr_ts-fyr_ts+1 & n_mo= (ny_ltm-2)*12 + (12-fmon_ts)+ (lmon_ts+1)
    yrs= indgen(ny_ltm)+fyr_ts
    FOR i_yr1=0, ny_ltm-1 DO BEGIN
      IF (yrs[i_yr1] MOD 4 EQ 0 AND gcm EQ 'no') THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
      IF i_yr1 EQ 0 AND ny_ltm GT 1 THEN tot1=TOTAL(month_len[fmon_ts:11])-fday_ts
      IF i_yr1 EQ 0 AND ny_ltm EQ 1 THEN tot1=TOTAL(month_len[fmon_ts:lmon_ts])-fday_ts
      IF i_yr1 GT 0 AND i_yr1 LT ny_ltm-1 THEN tot2=TOTAL(month_len)+tot2
      IF i_yr1 EQ ny_ltm-1 THEN BEGIN
        IF ny_ltm GT 1 THEN tot3=TOTAL(month_len[0:lmon_ts]) + tot1 + tot2 ELSE tot3= tot1 + tot2
        IF nday_mean GT 1 THEN off=tot3-(fix(tot3/nday_mean)*nday_mean) ELSE off=0
        IF off GT .5*nday_mean THEN BEGIN & add_d= nday_mean-off & add_m=1 & ENDIF ELSE BEGIN & add_d=0 & add_m=0 & ENDELSE
        if add_m eq 1 then tot_day = tot_day+ tot3+add_d ELSE tot_day = tot_day+ tot3 - off      & ENDIF
        ;print, tot_day
    ENDFOR
      
    day=-1 & seg=-1 & n_seg = tot_day/nday_mean & date=intarr(5, n_seg) & m1=0 & m2=0 & yr_add=0
    FOR i_mon=0, n_mo+add_m-1 DO BEGIN ; !!! repeat for all months !!!
      IF (yrs[yr_add] MOD 4 EQ 0 AND gcm EQ 'no') THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
      IF i_mon LT (12-fmon_ts) OR (i_mon MOD 12) LT (12-fmon_ts) THEN m=(i_mon MOD 12)+fmon_ts ELSE m=(i_mon MOD 12) - (12-fmon_ts)
      if (i_mon eq n_mo+add_m-1 and add_m ne 0) then n_day=add_d
      if (i_mon eq n_mo+add_m-1 and add_m eq 0) then n_day=month_len[m]-off
      if i_mon lt n_mo+add_m-1 then n_day=month_len[m]
      if (i_mon eq 0 and fday_ts ne 0) then begin & n_day=month_len[m]-fday_ts & fd_off=fday_ts & endif else begin & fd_off=0 & endelse
      
      FOR i_day=0, n_day-1 DO BEGIN   ; !!! repeat for all days !!!
        day+=1
        IF day MOD nday_mean EQ 0 AND day LT tot_day THEN BEGIN & m1=m & day1=i_day+fd_off & seg++ & ENDIF
        IF day MOD nday_mean EQ nday_mean-1 AND day LT tot_day THEN BEGIN & m2=m & day2=i_day+fd_off & date[*, seg]=[yrs[0]+yr_add, m1, m2, day1, day2] & ENDIF
        IF m EQ 0 AND m1 EQ 11 AND m2 EQ 0 THEN yr_add=yr_add+1
        IF day MOD nday_mean EQ 0 AND m2 EQ 11 AND day2 EQ 30 THEN yr_add=yr_add+1
      ENDFOR ;  !!! end of the loop: repeat for all days !!!
    ENDFOR    ;  !!! end of the loop: repeat for all months  !!!
  ENDELSE
ENDELSE
  ;==============================================================================================================================
  
  RETURN, date
END
;**********************************************************************************************************************************************************************
;**********************************************************************************************************************************************************************








;**********************************************************************************************************************************************************************
;***************************************************************** FUNCTION: TIME SERIES DATES ************************************************************************
;**********************************************************************************************************************************************************************
FUNCTION DATES_MON, FY=fyr, LY=lyr, FM=fmo, LM=lmo, CT=cont_YN

; This function is used when we want to produce a time series. It reads first/last year and month to generate a continous set of dates.
month_len= [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] ; number of days in each month
IF fmo LE lmo THEN ny_ltm= lyr-fyr+1 ELSE ny_ltm= lyr-fyr
yrs= indgen(ny_ltm)+fyr
  
IF cont_YN EQ 'no' THEN BEGIN & IF fmo LE lmo THEN n_mo= lmo -fmo +1 ELSE n_mo= 12-fmo + lmo +1 & n_seg=n_mo*ny_ltm      
  seg=-1 & date=intarr(2, n_seg) & yr_add=0
  FOR i_yr=0, ny_ltm-1 DO BEGIN 
    IF ((yrs[i_yr] MOD 4 EQ 0 AND fmo LE lmo) OR ((yrs[i_yr]+1) MOD 4 EQ 0 AND fmo GT lmo)) THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year 
    FOR i_mon=0, n_mo-1 DO BEGIN
      seg++
      IF (fmo LE lmo OR i_mon LE (11-fmo)) THEN m=(fmo+ i_mon) MOD 12 ELSE m=(i_mon MOD 11) - (12-fmo)
      IF fmo GT lmo THEN date[*, seg]=[yrs[0]+yr_add, m] ELSE date[*, seg]=[yrs[i_yr], m]
      IF (m EQ 11 AND fmo GT lmo) THEN yr_add=yr_add+1
    ENDFOR    
  ENDFOR    

ENDIF ELSE BEGIN & ny_ltm= lyr-fyr+1 & n_mo= (ny_ltm-2)*12 + (12-fmo)+ (lmo+1) & n_seg=n_mo ;for time series of monthly means when cont_YN = 'yes'
  yrs= indgen(ny_ltm)+fyr & seg=-1 & date=intarr(2, n_seg) & yr_add=0
  FOR i_mon=0, n_mo-1 DO BEGIN  
    seg++                
    IF (yrs[yr_add] MOD 4 EQ 0) THEN month_len[1]= 29 ELSE month_len[1]= 28 ; number of days in Feb for a leap year!
    IF i_mon LT (12-fmo) OR (i_mon MOD 12) LT (12-fmo) THEN m=(i_mon MOD 12)+fmo ELSE m=(i_mon MOD 12) - (12-fmo)
    date[*, seg]=[yrs[0]+yr_add, m]
    IF m EQ 11 THEN yr_add=yr_add+1
  ENDFOR                   
ENDELSE

RETURN, date
END
;**********************************************************************************************************************************************************************
;**********************************************************************************************************************************************************************




