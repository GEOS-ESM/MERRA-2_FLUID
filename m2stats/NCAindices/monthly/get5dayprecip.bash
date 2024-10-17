#!/bin/bash
yr=$1
mnth=$2

y1=${yr}
y2=${yr}
if [ ${mnth} -eq 1 ]; then
	m1=dec
	m=jan
	m2=feb
	let "y1=${y1}-1"
elif [ ${mnth} -eq 2 ]; then
	m1=jan
	m=feb
	m2=mar	
elif [ ${mnth} -eq 3 ]; then
	m1=feb
	m=mar
	m2=apr	
elif [ ${mnth} -eq 4 ]; then
	m1=mar
	m=apr
	m2=may	
elif [ ${mnth} -eq 5 ]; then
	m1=apr
	m=may
	m2=jun	
elif [ ${mnth} -eq 6 ]; then
	m1=may
	m=jun
	m2=jul	
elif [ ${mnth} -eq 7 ]; then
	m1=jun
	m=jul
	m2=aug	
elif [ ${mnth} -eq 8 ]; then
	m1=jul
	m=aug
	m2=sep	
elif [ ${mnth} -eq 9 ]; then
	m1=aug
	m=sep
	m2=oct	
elif [ ${mnth} -eq 10 ]; then
	m1=sep
	m=oct
	m2=nov	
elif [ ${mnth} -eq 11 ]; then
	m1=oct
	m=nov
	m2=dec	
elif [ ${mnth} -eq 12 ]; then
	m1=nov
	m=dec
	m2=jan
	let "y2=${y2}+1"
fi

/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/lats4d.sh -i /discover/nobackup/projects/gmao/merra2/data/pub/products/opendap/tavg1_2d_flx_Nx -o tmp/MERRA2.prectot.daily.${yr}${mnth} -time 00:30Z27${m1}${y1} 00:30Z05${m2}${y2} 24 -func "mean(@,t-12,t+11)*86400" -vars prectot -mxtimes 1800
wait
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/lats4d.sh -i tmp/MERRA2.prectot.daily.${yr}${mnth}.nc -o tmp/MERRA2.prectot.5daytotal.${yr}${m} -time 0:30Z01${m}${yr} 0:30Z01${m2}${y2} 1 -func "sum(@,t-2,t+2)" -vars prectot -mxtimes 366
