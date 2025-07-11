year1=1980
year2=2021
yyyy=year1
yyyy2=year2+1
*
start1=yyyy
end1=year2
start2=yyyy+1
end2=year2+1
start3=yyyy+1
end3=year2+1
*
'set gxout fwrite'
'set fwrite Had-ano-remglo.d'
*'open /discover/nobackup/ylim/Data/SST/OI-19822022-remglo.ctl'
'open /discover/nobackup/ylim/Data/SST/Had-18702021-remglo.ctl'
'set x 1 360'
'set y 1 180'
'set z 1'
'set t 1'
'define dd=ave(sst,time=01dec'start1',time=01dec'end1',12)'
'define ee=ave(sst,time=01jan'start2',time=01jan'end2',12)'
'define ff=ave(sst,time=01feb'start3',time=01feb'end3',12)'
while (yyyy < yyyy2)
height=1
*mon=1
*mon1=4
*while (mon < mon1)
*month=subwrd(mm,mon)
yyyy1=yyyy+1
*'open /discover/nobackup/ylim/Data/SST/OI-19822022-remglo.ctl'
'open /discover/nobackup/ylim/Data/SST/Had-18702021-remglo.ctl'
'set dfile 2'
'set x 1 360'
'set y 1 180'
'set z 'height''
'set t 1'
'define aa=sst(time=01dec'yyyy')'
'd aa-dd'
'define bb=sst(time=01jan'yyyy1')'
'd bb-ee'
'define cc=sst(time=01feb'yyyy1')'
'd cc-ff'
'close 2'
say yyyy
*say yyyy month day1
*mon=mon+1
*endwhile
yyyy=yyyy+1
endwhile
'close 1'
quit
