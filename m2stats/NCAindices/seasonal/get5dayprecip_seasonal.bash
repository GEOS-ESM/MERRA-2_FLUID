#!/bin/bash


yr2=$1
ssnnum=$2

if [ ${ssnnum} -eq 1 ]; then
	m1=oct
	m2=feb
	yr1=`expr ${yr2} - 1`
elif [ ${ssnnum} -eq 2 ]; then
	m1=nov
	m2=mar
	yr1=`expr ${yr2} - 1`
elif [ ${ssnnum} -eq 3 ]; then
	m1=dec
	m2=apr
	yr1=`expr ${yr2} - 1`
elif [ ${ssnnum} -eq 4 ]; then
	m1=jan
	m2=may
	yr1=$yr2
elif [ ${ssnnum} -eq 5 ]; then
	m1=feb
	m2=jun
	yr1=$yr2
elif [ ${ssnnum} -eq 6 ]; then
	m1=mar
	m2=jul
	yr1=$yr2
elif [ ${ssnnum} -eq 7 ]; then
	m1=apr
	m2=aug
	yr1=$yr2
elif [ ${ssnnum} -eq 8 ]; then
	m1=may
	m2=sep
	yr1=$yr2
elif [ ${ssnnum} -eq 9 ]; then
	m1=jun
	m2=oct
	yr1=$yr2
elif [ ${ssnnum} -eq 10 ]; then
	m1=jul
	m2=nov
	yr1=$yr2
elif [ ${ssnnum} -eq 11 ]; then
	m1=aug
	m2=dec
	yr1=$yr2
elif [ ${ssnnum} -eq 12 ]; then
	m1=sep
	m2=jan
	yr1=${yr2}
	yr2=`expr ${yr2} + 1`
else 
	echo "Incorrect Season Selection"
fi

/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/lats4d.sh -i /discover/nobackup/acollow/MERRA2/opendap/tavg1_2d_flx_Nx -o MERRA2.prectot.daily.uptodate -time 00:30Z01${m1}${yr1} 00:30Z03${m2}${yr2} 24 -func "mean(@,t-12,t+11)*86400" -vars prectot -mxtimes 400000
wait
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/lats4d.sh -i MERRA2.prectot.daily.uptodate.nc -o MERRA2.prectot.5daytotal.uptodate -time 0:30Z01${m1}${yr1} 0:30Z01${m2}${yr2} 1 -func "sum(@,t-2,t+2)" -vars prectot -mxtimes 366
