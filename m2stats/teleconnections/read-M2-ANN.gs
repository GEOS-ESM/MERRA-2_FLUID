year1=1980
year2=2017
yyyy=year1
yyyy1=year2-1
month='jan feb mar apr may jun jul aug sep oct nov dec'
'set gxout fwrite'
'set fwrite H250-ANNanomonth8017.d'
'open /discover/nobackup/ylim/Data/MERRA-2/d5124_m2.tavg1_2d_slv_Nx.monthly.ddf'
'set x 1 576'
'set y 1 361'
'set z 1'
'set t 1'
mmm=1
while (mmm <= 12)
mon=subwrd(month,mmm)
if (mmm <= endingmon)
'define aa'mmm'=ave(h250,time=01'mon''year1',time=01'mon''year2',12)'
endif
if (mmm > endingmon)
'define aa'mmm'=ave(h250,time=01'mon''year1',time=01'mon''yyyy1',12)'
endif
mmm=mmm+1
endwhile
while (yyyy <= year2)
height=1
'open /discover/nobackup/ylim/Data/MERRA-2/d5124_m2.tavg1_2d_slv_Nx.monthly.ddf'
'set dfile 2'
'set x 1 576'
'set y 1 361'
'set z 'height''
'set t 1'
if (yyyy < year2)
'define aa=h250(time=01jan'yyyy')'
'define bb=h250(time=01feb'yyyy')'
'define cc=h250(time=01mar'yyyy')'
'define dd=h250(time=01apr'yyyy')'
'define ee=h250(time=01may'yyyy')'
'define ff=h250(time=01jun'yyyy')'
'define gg=h250(time=01jul'yyyy')'
'define hh=h250(time=01aug'yyyy')'
'define ii=h250(time=01sep'yyyy')'
'define jj=h250(time=01oct'yyyy')'
'define kk=h250(time=01nov'yyyy')'
'define ll=h250(time=01dec'yyyy')'
'd aa-aa1'
'd bb-aa2'
'd cc-aa3'
'd dd-aa4'
'd ee-aa5'
'd ff-aa6'
'd gg-aa7'
'd hh-aa8'
'd ii-aa9'
'd jj-aa10'
'd kk-aa11'
'd ll-aa12'
endif
if (yyyy = year2)
mmm=1
while (mmm <= endingmon)
mon=subwrd(month,mmm)
'define aa=h250(time=01'mon''yyyy')'
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
