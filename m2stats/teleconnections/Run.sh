#!/bin/csh -f
echo
echo "Enter the type of climate mode:"
echo "1 -- Atmospheric teleconnections (NAO, AO, ENSO, PNA,......),"
echo "2 -- SST modes (PDO, AMO, IOD)"
echo " "
set TY = $<

#if ($TY != '1' & \
#    $TY != '2') goto TY 

if ( $TY == '1' | \
     $TY == '2' ) then
     set Type = $TY
endif

if ($Type == '1') then
echo "1 -- North Atlantic Oscillation (NAO)"
echo "2 -- Arctic Oscillation (AO)"
echo "3 -- ENSO-teleconnection"
echo "4 -- Pacific North American (PNA)"
echo "5 -- East Atlantic / West Russia (EA/WR)"
echo "6 -- Scandinavian (SCA)"
echo "7 -- West Pacific (WP)"
echo "8 -- East Pacific / North Pacific (EP/NP)"
echo "9 -- East Atlantic (EA)"
echo " "
set TY2 = $<
if ($TY2 == '1' | \
    $TY2 == '2' | \
    $TY2 == '3' | \
    $TY2 == '4' | \
    $TY2 == '5' | \
    $TY2 == '6' | \
    $TY2 == '7' | \
    $TY2 == '8' | \
    $TY2 == '9' ) then
    set Type2 = $TY2
endif

if ($TY2 == '1' ) then
    set TEL = 'NAO'
endif
if ($TY2 == '2' ) then
    set TEL = 'AO'
endif
if ($TY2 == '3' ) then
    set TEL = 'ENSO'
endif
if ($TY2 == '4' ) then
    set TEL = 'PNA'
endif
if ($TY2 == '5' ) then
    set TEL = 'EAWR'
endif
if ($TY2 == '6' ) then
    set TEL = 'SCA'
endif
if ($TY2 == '7' ) then
    set TEL = 'WP'
endif
if ($TY2 == '8' ) then
    set TEL = 'EPNP'
endif
if ($TY2 == '9' ) then
    set TEL = 'EA'
endif
endif

if ($Type == '2') then
echo "1 -- Pacific Decadal Oscillation (PDO)"
echo "2 -- Atlantic Multi-decadal Oscillation (AMO)"
echo "3 -- Indian Ocean Dipole (IOD)"
echo " "
set TY2 = $<
if ($TY2 == '1' | \
    $TY2 == '2' | \
    $TY2 == '3' ) then
    set Type2 = $TY2
endif
endif

echo "Enter the season:"
echo "1 -- MAM,  2 -- JJA,  3 -- SON,  4 -- DJF,  5 -- All months"
echo " "
set SC = $<

if ($Type == '1') then
echo "Enter the starting year (1980- ):"
endif
if ($Type == '2') then
echo "Enter the starting year (1901- ):"
endif
set SY = $<

if ($Type == '1') then
echo "Enter the ending year (All months: -2024, Seasonal: -2023):"
endif
if ($Type == '2') then
echo "Enter the ending year ( -2021):"
endif
set EY = $<

echo "Enter the final month (1-3 for specific season, 1-12 for annual) in the ending year"
set EM = $<

set TS = `echo $SY`
set TE = `echo $EY`
    @ TT = ($TE - $TS) + 0
    @ TT1 = $TT * 3 + $EM
    @ TT2 = $TT * 12 + $EM
    @ MON1 = ($EM - 1) * 10000 / 3
    @ MON2 = ($EM - 1) * 10000 / 12
    @ TSKIP1 = ($TS - 1980) * 3  
    @ TSKIP2 = ($TS - 1980) * 12 

if ( $SC == '1' | \
     $SC == '2' | \
     $SC == '3' | \
     $SC == '4' | \
     $SC == '5' ) then
     set Season = $SC
endif

if ($SC == '1') then
   set Season2 = 'MAM'
endif
if ($SC == '2') then
   set Season2 = 'JJA'
endif
if ($SC == '3') then
   set Season2 = 'SON'
endif
if ($SC == '4') then
   set Season2 = 'DJF'
endif
if ($SC == '5') then
   set Season2 = 'ANN'
endif
 
if ($Type == '1') then

if ( $Season == '1' | $Season == '2' | $Season == '3') then
sed s/year1=1980/year1=${SY}/g read-M2.gs > tmp.gs
sed s/year2=2017/year2=${EY}/g tmp.gs > tmp1.gs
sed s/H250-DJFanomonth8017/H2-${Season2}ano${SY}${EY}/g tmp1.gs > tmp2.gs
sed s/endingmon/${EM}/g tmp2.gs > tmp3.gs
if ( $Season == '1') then
sed s/mar/mar/g tmp3.gs > tmp4.gs
sed s/apr/apr/g tmp4.gs > tmp5.gs
sed s/may/may/g tmp5.gs > tmp6.gs
endif
if ( $Season == '2') then
sed s/mar/jun/g tmp3.gs > tmp4.gs
sed s/apr/jul/g tmp4.gs > tmp5.gs
sed s/may/aug/g tmp5.gs > tmp6.gs
endif
if ( $Season == '3') then
sed s/mar/sep/g tmp3.gs > tmp4.gs
sed s/apr/oct/g tmp4.gs > tmp5.gs
sed s/may/nov/g tmp5.gs > tmp6.gs
endif
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp6"
endif
if ( $Season == '4') then
sed s/year1=1980/year1=${SY}/g read-M2-DJF.gs > tmp.gs
sed s/year2=2017/year2=${EY}/g tmp.gs > tmp1.gs
sed s/H250-DJFanomonth8017/H2-DJFano${SY}${EY}/g tmp1.gs > tmp2.gs
sed s/endingmon/${EM}/g tmp2.gs > tmp3.gs
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp3"
endif
if ( $Season == '5') then
sed s/year1=1980/year1=${SY}/g read-M2-ANN.gs > tmp.gs
sed s/year2=2017/year2=${EY}/g tmp.gs > tmp1.gs
sed s/H250-ANNanomonth8017/H2-ANNano${SY}${EY}/g tmp1.gs > tmp2.gs
sed s/endingmon/${EM}/g tmp2.gs > tmp3.gs
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp3"
endif
rm -f tmp?.gs

sed s/mx=576/mx=576/g REOF-H250.f > tmp.f
sed s/my=181/my=201/g tmp.f > tmp1.f
sed s/mx1=576/mx1=576/g tmp1.f > tmp2.f
sed s/my1=361/my1=361/g tmp2.f > tmp3.f
sed s/np=30/np=12/g tmp3.f > tmp4.f
sed s/slat=0.0/slat=-10./g tmp4.f > tmp5.f
sed s/yint=0.5/yint=0.5/g tmp5.f > tmp6.f
sed s/mg1=104256/mg1=115776/g tmp6.f > tmp7.f
sed s/mg2=104256/mg2=115776/g tmp7.f > tmp8.f
sed s/H2-DJFano19802018/H2-${Season2}ano${SY}${EY}/g tmp8.f > tmp9.f
if ( $Season < '5') then
sed s/n=117/n=$TT1/g tmp9.f > tmp10.f
endif
if ( $Season == '5') then
sed s/n=117/n=$TT2/g tmp9.f > tmp10.f
endif
sed s/H2-DJF19802018/H2-${Season2}${SY}${EY}/g tmp10.f > tmp11.f
ifort tmp11.f
./a.out
rm -f tmp*.f

sed s/H2-DJF19802018/${TEL}-${Season2}${SY}${EY}_${EM}/g ev-H2.ctl > ev.ctl
sed s/H2-DJF19802018/${TEL}-${Season2}${SY}${EY}_${EM}/g pc-H2.ctl > pc.ctl
if ( $Season == '1') then
sed s/dec1980/mar${SY}/g ev.ctl > ev1.ctl
sed s/dec1980/mar${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '2') then
sed s/dec1980/jun${SY}/g ev.ctl > ev1.ctl
sed s/dec1980/jun${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '3') then
sed s/dec1980/sep${SY}/g ev.ctl > ev1.ctl
sed s/dec1980/sep${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '4') then
sed s/dec1980/dec${SY}/g ev.ctl > ev1.ctl
sed s/dec1980/dec${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '5') then
sed s/dec1980/jan${SY}/g ev.ctl > ev1.ctl
sed s/dec1980/jan${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season < '5') then
sed s/117/$TT1/g pc1.ctl > pc2.ctl
sed s/nt=516/nt=${TT1}/g scorr-ev.f > cor1.f
endif
if ( $Season == '5') then
sed s/117/$TT2/g pc1.ctl > pc2.ctl
sed s/nt=516/nt=${TT2}/g scorr-ev.f > cor1.f
endif
sed s/DJF19802018/${Season2}${SY}${EY}/g cor1.f > cor2.f
sed s/TELE/$TEL/g cor2.f > cor3.f
sed s/ENDM/${EM}/g cor3.f > cor4.f
sed s/itel=3/itel=${Type2}/g cor4.f > cor5.f
ifort cor5.f
./a.out
rm -f cor1.f cor2.f cor3.f cor4.f cor5.f

sed s/H2-DJF19802018/${TEL}-${Season2}${SY}${EY}_${EM}/g conv_b2nc-atm.gs > tmp.gs
if ( $Season < '5') then
sed s/117/$TT1/g tmp.gs > tmp1.gs
endif
if ( $Season == '5') then
sed s/117/$TT2/g tmp.gs > tmp1.gs
endif

if ($Type2 != '5' & $Type2 != '8') then
if ( $Season < '5') then
sed s/,' 'DJF/,' '${Season2}/g REOF-Tele.gs > r1.gs
endif
if ( $Season == '5') then
sed s/,' 'DJF/,' 'All' 'months/g REOF-Tele.gs > r1.gs
endif
sed s/DJF/${Season2}/g r1.gs > r2.gs
endif
if ($Type2 == '5') then
if ( $Season < '5') then
sed s/,' 'DJF/,' '${Season2}/g REOF-EAWR.gs > r1.gs
endif
if ( $Season == '5') then
sed s/,' 'DJF/,' 'All' 'months/g REOF-EAWR.gs > r1.gs
endif
sed s/DJF/${Season2}/g r1.gs > r2.gs
endif
if ($Type2 == '8') then
if ( $Season < '5') then
sed s/,' 'DJF/,' '${Season2}/g REOF-EPNP.gs > r1.gs
endif
if ( $Season == '5') then
sed s/,' 'DJF/,' 'All' 'months/g REOF-EPNP.gs > r1.gs
endif
sed s/DJF/${Season2}/g r1.gs > r2.gs
endif
sed s/ev-H2/ev-${TEL}/g r2.gs > r3.gs
sed s/pc-H2/pc-${TEL}/g r3.gs > r4.gs
sed s/1980/${SY}/g r4.gs > r5.gs
sed s/2018/${EY}/g r5.gs > r6.gs
if ( $Season < '5') then
sed s/117/$TT1/g r6.gs > r7.gs
sed s/6667/$MON1/g r7.gs > r8.gs
endif
if ( $Season == '5') then
sed s/117/$TT2/g r6.gs > r7.gs
sed s/6667/$MON2/g r7.gs > r8.gs
endif
sed s/REF-H2/REF-${TEL}/g r8.gs > r9.gs
if ($Type2 == '1') then
sed s/TELECONNECTION/North' 'Atlantic' 'Oscillation/g r9.gs > r10.gs
sed s/acronym/NAO/g r10.gs > r11.gs
endif
if ($Type2 == '2') then
sed s/TELECONNECTION/Arctic' 'Oscillation/g r9.gs > r10.gs
sed s/acronym/AO/g r10.gs > r11.gs
endif
if ($Type2 == '3') then
sed s/TELECONNECTION/ENSO' 'Teleconnection/g r9.gs > r10.gs
sed s/acronym/ENSO/g r10.gs > r11.gs
endif
if ($Type2 == '4') then
sed s/TELECONNECTION/Pacific' 'North' 'American/g r9.gs > r10.gs
sed s/acronym/PNA/g r10.gs > r11.gs
endif
if ($Type2 == '6') then
sed s/TELECONNECTION/Scandinavian' 'Teleconnection/g r9.gs > r10.gs
sed s/acronym/SCA/g r10.gs > r11.gs
endif
if ($Type2 == '7') then
sed s/TELECONNECTION/West' 'Pacific/g r9.gs > r10.gs
sed s/acronym/WP/g r10.gs > r11.gs
endif
if ($Type2 == '9') then
sed s/TELECONNECTION/East' 'Atlantic/g r9.gs > r10.gs
sed s/acronym/EA/g r10.gs > r11.gs
endif
if ($Type2 == '5' | $Type2 == '8') then
cp r9.gs r11.gs
endif
if ($Type2 == '1' | $Type2 == '2' | $Type2 == '5' | $Type2 == '6' | $Type2 == '9') then
sed s/lon' '0' '360/lon' '-180' '180/g  r11.gs > r12.gs
else
cp r11.gs r12.gs
endif
sed s/ENDM/${EM}/g r12.gs > r13.gs
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -pbc "tmp1"
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "r13"

rm -f tmp*.gs r?.gs r??.gs
mv ev1.ctl ./Output/ev-${TEL}-${Season2}${SY}${EY}_${EM}.ctl
mv pc2.ctl ./Output/pc-${TEL}-${Season2}${SY}${EY}_${EM}.ctl
mv REF-${TEL}-${Season2}${SY}${EY}_${EM}.png ./Output/
mv REF-${TEL}-${Season2}${SY}${EY}_${EM}.eps ./Output/
mv ev-${TEL}-${Season2}${SY}${EY}_${EM}.d ./Output/
mv ev-${TEL}-${Season2}${SY}${EY}_${EM}.nc ./Output/
mv pc-${TEL}-${Season2}${SY}${EY}_${EM}.d ./Output/
mv pc-${TEL}-${Season2}${SY}${EY}_${EM}.nc ./Output/
rm -f H2-${Season2}ano${SY}${EY}.d
rm -f rinf-H2-${Season2}${SY}${EY}.d
rm -f ev-H2-${Season2}${SY}${EY}.d
rm -f pc-H2-${Season2}${SY}${EY}.d
#rm -f ev1.ctl pc2.ctl 

endif

if ($Type == '2') then

sed s/year1=1980/year1=${SY}/g SST-SeaAno.gs > tmp.gs
sed s/year2=2021/year2=${EY}/g tmp.gs > tmp1.gs
if ( $Season == '1' | $Season == '2' | $Season == '3') then
sed s/yyyy1=yyyy+1/yyyy1=yyyy+0/g tmp1.gs > tmp2.gs
sed s/start2=yyyy+1/start2=yyyy/g tmp2.gs > tmp3.gs
sed s/end2=year2+1/end2=year2/g tmp3.gs > tmp4.gs
sed s/start3=yyyy+1/start3=yyyy/g tmp4.gs > tmp5.gs
sed s/end3=year2+1/end3=year2/g tmp5.gs > tmp6.gs
endif
if ( $Season == '1') then
sed s/01dec/01mar/g tmp6.gs > tmp7.gs
sed s/01jan/01apr/g tmp7.gs > tmp8.gs
sed s/01feb/01may/g tmp8.gs > tmp9.gs
endif
if ( $Season == '2') then
sed s/01dec/01jun/g tmp6.gs > tmp7.gs
sed s/01jan/01jul/g tmp7.gs > tmp8.gs
sed s/01feb/01aug/g tmp8.gs > tmp9.gs
endif
if ( $Season == '3') then
sed s/01dec/01sep/g tmp6.gs > tmp7.gs
sed s/01jan/01oct/g tmp7.gs > tmp8.gs
sed s/01feb/01nov/g tmp8.gs > tmp9.gs
endif
if ( $Season == '4') then
sed s/yyyy1=yyyy+1/yyyy1=yyyy+1/g tmp1.gs > tmp2.gs
sed s/start2=yyyy+1/start2=yyyy+1/g tmp2.gs > tmp3.gs
sed s/end2=year2+1/end2=year2+1/g tmp3.gs > tmp4.gs
sed s/start3=yyyy+1/start3=yyyy+1/g tmp4.gs > tmp5.gs
sed s/end3=year2+1/end3=year2+1/g tmp5.gs > tmp6.gs
sed s/01dec/01dec/g tmp6.gs > tmp7.gs
sed s/01jan/01jan/g tmp7.gs > tmp8.gs
sed s/01feb/01feb/g tmp8.gs > tmp9.gs
endif
if ( $Season < '5') then
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp9"
endif
if ( $Season == '5') then
sed s/year1=1980/year1=${SY}/g SST-AnnAno.gs > tmp.gs
sed s/year2=2021/year2=${EY}/g tmp.gs > tmp1.gs
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp1"
endif
rm -f tmp*.gs

if ( $Type2 == '1' & $Season < '5') then
sed s/nt=1419/nt=$TT1/g cut-missing-PDO.f > tmp.f
sed s/lx=41119/lx=41119/g tmp.f > tmp1.f
sed s/1419/$TT1/g eigen-PDO.c > tmp.c
sed s/4185/41119/g tmp.c > tmp1.c
endif
if ( $Type2 == '1' & $Season == '5') then
sed s/nt=1419/nt=$TT2/g cut-missing-PDO.f > tmp.f
sed s/lx=41119/lx=41119/g tmp.f > tmp1.f
sed s/1419/$TT2/g eigen-PDO.c > tmp.c
sed s/4185/41119/g tmp.c > tmp1.c
endif
if ( $Type2 == '2' & $Season < '5') then
sed s/nt=1419/nt=$TT1/g cut-missing-AMO.f > tmp.f
sed s/lx=4315/lx=4315/g tmp.f > tmp1.f
sed s/1419/$TT1/g eigen-AMO.c > tmp.c
sed s/4315/4315/g tmp.c > tmp1.c
endif
if ( $Type2 == '2' & $Season == '5') then
sed s/nt=1419/nt=$TT2/g cut-missing-AMO.f > tmp.f
sed s/lx=4315/lx=4315/g tmp.f > tmp1.f
sed s/1419/$TT2/g eigen-AMO.c > tmp.c
sed s/4315/4315/g tmp.c > tmp1.c
endif
if ( $Type2 == '3' & $Season < '5') then
sed s/nt=1419/nt=$TT1/g cut-missing-IOD.f > tmp.f
sed s/lx=4531/lx=4531/g tmp.f > tmp1.f
sed s/1419/$TT1/g eigen-IOD.c > tmp.c
sed s/4531/4531/g tmp.c > tmp1.c
endif
if ( $Type2 == '3' & $Season == '5') then
sed s/nt=1419/nt=$TT2/g cut-missing-IOD.f > tmp.f
sed s/lx=4531/lx=4531/g tmp.f > tmp1.f
sed s/1419/$TT2/g eigen-IOD.c > tmp.c
sed s/4531/4531/g tmp.c > tmp1.c
endif
sed s/11,rec=it/11,rec=it/g tmp1.f > tmp2.f
sed s/DJF/${Season2}/g tmp1.c > tmp2.c
sed s/1870/${SY}/g tmp2.c > tmp3.c
sed s/2021/${EY}/g tmp3.c > tmp4.c
ifort tmp2.f
./a.out
csh ./tmp4.c
rm -f tmp*.f tmp*.c

# Recover the missing values over land, and switch the writing order of the PC (mode,time)
if ( $Type2 == '1' ) then
sed s/lx=41119/lx=41119/g EV-recovermissing-PDO.f > tmp.f
sed s/recover/${Season2}${SY}${EY}/g tmp.f > tmp1.f
if ( $Season < '5' ) then
sed s/lx=1419/lx=$TT1/g PC-switch.f > pc.f
endif
if ( $Season == '5' ) then
sed s/lx=1419/lx=$TT2/g PC-switch.f > pc.f
endif
sed s/PDO/PDO/g pc.f > pc1.f
sed s/DJF18702021/${Season2}${SY}${EY}/g pc1.f > pc2.f
endif

if ( $Type2 == '2' ) then
sed s/lx=4315/lx=4315/g EV-recovermissing-AMO.f > tmp.f
sed s/recover/${Season2}${SY}${EY}/g tmp.f > tmp1.f
if ( $Season < '5' ) then
sed s/lx=1419/lx=$TT1/g PC-switch.f > pc.f
endif
if ( $Season == '5' ) then
sed s/lx=1419/lx=$TT2/g PC-switch.f > pc.f
endif
sed s/PDO/AMO/g pc.f > pc1.f
sed s/DJF18702021/${Season2}${SY}${EY}/g pc1.f > pc2.f
endif

if ( $Type2 == '3' ) then
sed s/lx=4531/lx=4531/g EV-recovermissing-IOD.f > tmp.f
sed s/recover/${Season2}${SY}${EY}/g tmp.f > tmp1.f
if ( $Season < '5' ) then
sed s/lx=1419/lx=$TT1/g PC-switch.f > pc.f
endif
if ( $Season == '5' ) then
sed s/lx=1419/lx=$TT2/g PC-switch.f > pc.f
endif
sed s/PDO/IOD/g pc.f > pc1.f
sed s/DJF18702021/${Season2}${SY}${EY}/g pc1.f > pc2.f
endif

ifort tmp1.f
./a.out
ifort pc2.f
./a.out
rm -f tmp*.f pc*.f ev-PDO.d ev-AMO.d ev-IOD.d pc-PDO.d pc-AMO.d pc-IOD.d

if ( $Type2 == '1') then
sed s/DJF18702021/${Season2}${SY}${EY}/g ev-PDO.ctl > ev.ctl
sed s/DJF18702021/${Season2}${SY}${EY}/g pc-PDO.ctl > pc.ctl
endif
if ( $Type2 == '2') then
sed s/DJF18702021/${Season2}${SY}${EY}/g ev-AMO.ctl > ev.ctl
sed s/DJF18702021/${Season2}${SY}${EY}/g pc-AMO.ctl > pc.ctl
endif
if ( $Type2 == '3') then
sed s/DJF18702021/${Season2}${SY}${EY}/g ev-IOD.ctl > ev.ctl
sed s/DJF18702021/${Season2}${SY}${EY}/g pc-IOD.ctl > pc.ctl
endif
if ( $Season == '1') then
sed s/dec1901/mar${SY}/g ev.ctl > ev1.ctl
sed s/dec1901/mar${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '2') then
sed s/dec1901/jun${SY}/g ev.ctl > ev1.ctl
sed s/dec1901/jun${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '3') then
sed s/dec1901/sep${SY}/g ev.ctl > ev1.ctl
sed s/dec1901/sep${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '4') then
sed s/dec1901/dec${SY}/g ev.ctl > ev1.ctl
sed s/dec1901/dec${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season == '5') then
sed s/dec1901/jan${SY}/g ev.ctl > ev1.ctl
sed s/dec1901/jan${SY}/g pc.ctl > pc1.ctl
endif
if ( $Season < '5') then
sed s/1419/$TT1/g pc1.ctl > pc2.ctl
if ( $Type2 == '1') then
sed s/nt=1419/nt=${TT1}/g scorr-ev-PDO.f > cor1.f
endif
if ( $Type2 == '2') then
sed s/nt=1419/nt=${TT1}/g scorr-ev-AMO.f > cor1.f
endif
if ( $Type2 == '3') then
sed s/nt=1419/nt=${TT1}/g scorr-ev-IOD.f > cor1.f
endif
endif
if ( $Season == '5') then
sed s/1419/$TT2/g pc1.ctl > pc2.ctl
if ( $Type2 == '1') then
sed s/nt=1419/nt=${TT2}/g scorr-ev-PDO.f > cor1.f
endif
if ( $Type2 == '2') then
sed s/nt=1419/nt=${TT2}/g scorr-ev-AMO.f > cor1.f
endif
if ( $Type2 == '3') then
sed s/nt=1419/nt=${TT2}/g scorr-ev-IOD.f > cor1.f
endif
endif
sed s/DJF18702021/${Season2}${SY}${EY}/g cor1.f > cor2.f
if ( $Type2 == '1' | $Type2 == '2') then
sed s/itel=1/itel=1/g cor2.f > cor3.f
endif
if ( $Type2 == '3') then
sed s/itel=2/itel=2/g cor2.f > cor3.f
endif
ifort cor3.f
./a.out
rm -f cor1.f cor2.f cor3.f 

if ( $Type2 == '1') then
sed s/DJF18702021/${Season2}${SY}${EY}/g conv_b2nc-PDO.gs > tmp.gs
sed s/DJF/${Season2}/g PDO-plot.gs > r1.gs
endif
if ( $Type2 == '2') then
sed s/DJF18702021/${Season2}${SY}${EY}/g conv_b2nc-AMO.gs > tmp.gs
sed s/DJF/${Season2}/g AMO-plot.gs > r1.gs
endif
if ( $Type2 == '3') then
sed s/DJF18702021/${Season2}${SY}${EY}/g conv_b2nc-IOD.gs > tmp.gs
sed s/DJF/${Season2}/g IOD-plot.gs > r1.gs
endif
if ( $Season < '5') then
sed s/1419/$TT1/g tmp.gs > tmp1.gs
endif
if ( $Season == '5') then
sed s/1419/$TT2/g tmp.gs > tmp1.gs
endif
sed s/1980/${SY}/g r1.gs > r2.gs
sed s/2018/${EY}/g r2.gs > r3.gs
if ( $Season < '5') then
sed s/117/$TT1/g r3.gs > r4.gs
endif
if ( $Season == '5') then
sed s/117/$TT2/g r3.gs > r4.gs
sed s/6667/9167/g r4.gs > r5.gs
endif

/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "tmp1"
if ( $Season < '5') then
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "r4"
endif
if ( $Season == '5') then
/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/grads -lbc "r5"
endif
#rm -f tmp*.gs r?.gs
rm -f ev.ctl pc.ctl pc1.ctl
if ( $Type2 == '1') then
mv pc2.ctl pc-PDO-${Season2}${SY}${EY}.ctl
endif
if ( $Type2 == '2') then
mv pc2.ctl pc-AMO-${Season2}${SY}${EY}.ctl
endif
if ( $Type2 == '3') then
mv pc2.ctl pc-IOD-${Season2}${SY}${EY}.ctl
endif

rm -f ev.ctl ev1.ctl pc.ctl pc1.ctl pc2.ctl

endif

