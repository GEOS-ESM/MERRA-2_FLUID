function wspdyrmn(args)
'reinit'

inpath='/discover/nobackup/projects/gmao/merra2/merra2/scratch/opendap/'
* inpath='/gpfsm/dnb05/projects/p53/merra2/data/pub/products/opendap/'

'open 'inpath'tavg1_2d_slv_Nx'
'open 'inpath'inst3_3d_asm_Np'

mn.1=JAN; mn.2=FEB ; mn.3=MAR ; mn.4=APR ; mn.5=MAY ; mn.6=JUN ; mn.7=JUL ; mn.8=AUG ; mn.9=SEP ; mn.10=OCT ; mn.11=NOV ; mn.12=DEC
de.1=31; de.2=28; de.3=31; de.4=30; de.5=31; de.6=30; de.7=31; de.8=31; de.9=30;de.10=31; de.11=30; de.12=31

opath='/discover/nobackup/projects/gmao/nca/indices/windspeed/'


'set x 1 576'
'set y 1 361'
'set t 1'

yr=subwrd(args,1)
emn=subwrd(args,2)
if(emn='' | yr=''); say "YEAR,MN not specified "yr" "emn;'return'
else
say "YR, MN "yr", "emn
endif

if(emn < 10 )
mm="0"emn
else
mm=emn
endif

ly=math_mod(yr,4)
ly=math_abs(ly)

dayend=de.emn
if(emn=2 & ly=0)
dayend=29
endif

'set dfile 1'
t1='00:30Z01'mn.emn''yr
t2='23:30Z'dayend''mn.emn''yr

say t1' 't2

'set time 't1
ofile='MERRA2_mon_wspd_'yr''mm'.nc'

'set sdfwrite -3dt -flt -rt 'opath'temp.nc'

'define wspd10m=mean(mag(u10m,v10m),time='t1',time='t2')'
'sdfwrite wspd10m'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'define wspd50m=mean(mag(u50m,v50m),time='t1',time='t2')'
'sdfwrite wspd50m'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'define wspd850=mean(mag(u850,v850),time='t1',time='t2')'
'sdfwrite wspd850'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'define wspd500=mean(mag(u500,v500),time='t1',time='t2')'
'sdfwrite wspd500'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'set dfile 2'
t1='00:00Z01'mn.emn''yr
t2='21:00Z'dayend''mn.emn''yr

say t1' 't2

'set time 't1

'set lev 700'
'define wspd700=mean(mag(u.2,v.2),time='t1',time='t2')'
'sdfwrite wspd700'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'set lev 300'
'define wspd300=mean(mag(u.2,v.2),time='t1',time='t2')'
'sdfwrite wspd300'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f temp.nc'

'set lev 200'
'define wspd200=mean(mag(u.2,v.2),time='t1',time='t2')'
'sdfwrite wspd200'
say result
'!/usr/local/other/nco/5.1.4/bin/ncks -h -A 'opath'temp.nc 'opath''ofile
say result
'!rm -f /discover/nobackup/projects/gmao/nca/indices/windspeed/temp.nc'

'clear sdfwrite'


'quit'









