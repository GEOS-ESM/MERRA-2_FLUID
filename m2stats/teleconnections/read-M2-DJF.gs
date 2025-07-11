year1=1980
year2=2017
yyyy=year1
*
start1=yyyy
end1=year2
start2=yyyy+1
end2=year2+1
*
month='dec jan feb'
'set gxout fwrite'
'set fwrite H250-DJFanomonth8017.d'
'open /discover/nobackup/ylim/Data/MERRA-2/d5124_m2.tavg1_2d_slv_Nx.monthly.ddf'
'set x 1 576'
'set y 1 361'
'set z 1'
'set t 1'
mmm=1
while (mmm <= 3)
mon=subwrd(month,mmm)
if (mmm <= endingmon)
if (mmm = 1)
'define aa'mmm'=ave(h250,time=01'mon''start1',time=01'mon''end1',12)'
endif
if (mmm = 2 | mmm = 3)
'define aa'mmm'=ave(h250,time=01'mon''start2',time=01'mon''end2',12)'
endif
endif
if (mmm > endingmon)
'define aa'mmm'=ave(h250,time=01'mon''start2',time=01'mon''end1',12)'
endif
mmm=mmm+1
endwhile
while (yyyy <= year2)
height=1
yyyy1=yyyy+1
'open /discover/nobackup/ylim/Data/MERRA-2/d5124_m2.tavg1_2d_slv_Nx.monthly.ddf'
'set dfile 2'
'set x 1 576'
'set y 1 361'
'set z 'height''
'set t 1'
if (yyyy < year2)
'define aa=h250(time=01dec'yyyy')'
'd aa-aa1'
'define bb=h250(time=01jan'yyyy1')'
'd bb-aa2'
'define cc=h250(time=01feb'yyyy1')'
'd cc-aa3'
endif
if (yyyy = year2)
mmm=1
while (mmm <= endingmon)
mon=subwrd(month,mmm)
if (mmm = 1)
'define aa=h250(time=01'mon''yyyy')'
endif
if (mmm = 2 | mon = 3)
'define aa=h250(time=01'mon''yyyy1')'
endif
'd aa-aa'mmm''
mmm=mmm+1
endwhile
endif
'close 2'
say yyyy
yyyy=yyyy+1
endwhile
'close 1'
quit
