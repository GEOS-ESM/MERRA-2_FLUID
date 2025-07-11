'reinit'
'open pc2.ctl'
'open Tel-ENSO-ALL-8022.ctl'
*
cormax=0.0
mode=1
while (mode < 13)
'set x 1'
'set y 1'
'set z 1'
'set t 1'
'define cor=tcorr(pc.1(x='mode'),tele.2(x=atm),time=01janyyyy1,time=01decyyyy2)'
if (abs(cormax) < abs(cor)) then
'cormax=cor'
'number='mode''
say cormax ' ' number
endif
mode=mode+1
endwhile
if (cormax > 0.0) then
'factor=1'
else
'factor=-1'
endif
'close 2'
'close 1'
*
'set sdfwrite ev-H2-DJF19802018.nc'
'open ev1.ctl'
'set x 1 576'
'set y 1 201'
'set z 1'
'set t 'number''
*'set t 1 12'
'define ev=h*factor'
*'define ev=h'
'sdfwrite ev'
'close 1'
*
'set sdfwrite pc-H2-DJF19802018.nc'
'open pc2.ctl'
'set x 'number''
*'set x 1 12'
'set y 1'
*'set y 1 117'
'set z 1'
'set t 1 117'
*'set t 1'
'define pc1=pc*factor'
*'define pc1=pc'
'sdfwrite pc1'
'close 1'
quit
