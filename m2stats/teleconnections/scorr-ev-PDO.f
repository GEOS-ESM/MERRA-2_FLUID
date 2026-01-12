      parameter (nx=360,ny=180,mode=4,ntel=4,nt=1419)
      dimension evref(nx,ny),evref1(ntel,nx,ny),ev(nx,ny),pc(mode)

      open (11,file='evPDO-ANN19612021ref.d',form='unformatted',
     & access='direct',recl=nx*ny,status='old')
      open (12,file='pc-PDO-DJF18702021.d',form='unformatted',
     & access='direct',recl=mode,status='old')
      open (13,file='ev-PDO-DJF18702021.d',form='unformatted',
     & access='direct',recl=nx*ny,status='old')

      open (14,file='pc-PDO-DJF18702021rv.d',form='unformatted',
     & access='direct',recl=1,status='unknown')
      open (15,file='ev-PDO-DJF18702021rv.d',form='unformatted',
     & access='direct',recl=nx*ny,status='unknown')

      itel=1
      cormax=0.0
      dmiss=-9999.

      do 1 im=1,mode
       read (11,rec=im) evref
       do 2 jj=1,ny
       do 2 ii=1,nx
        if (im .eq. 1) then
         evref1(1,ii,jj)=-evref(ii,jj)
        else if (im .eq. 2) then 
         evref1(2,ii,jj)=evref(ii,jj)
        else if (im .eq. 3) then 
         evref1(3,ii,jj)=evref(ii,jj)
        else if (im .eq. 4) then 
         evref1(4,ii,jj)=evref(ii,jj)
        endif
2      continue
1     continue

      do 5 im=1,mode
      var1=0.0
      var2=0.0
      covar=0.0
       read (13,rec=im) ev
       icount=0
       do jj=1,ny
       do ii=1,nx
       if (evref1(itel,ii,jj).ne.dmiss.and.ev(ii,jj).ne.dmiss) then 
       var1=var1+evref1(itel,ii,jj)*evref1(itel,ii,jj)
       var2=var2+ev(ii,jj)*ev(ii,jj)
       covar=covar+evref1(itel,ii,jj)*ev(ii,jj)
       icount=icount+1
       endif
       enddo
       enddo
      cor=(covar/float(icount))/
     &(sqrt(var1/float(icount))*sqrt(var2/float(icount)))
      if (abs(cormax) .lt. abs(cor)) then
       cormax=cor
       number=im
       print*,cormax,number
      endif
5     continue
      if (cormax .lt. 0.0) then
       factor=-1.0
      else
       factor=1.0
      endif

      read (13,rec=number) ev 
      do jj=1,ny
      do ii=1,nx
       if (ev(ii,jj).ne.dmiss) then
        ev(ii,jj)=ev(ii,jj)*factor
       endif
      enddo
      enddo
      write (15,rec=1) ev
      do it=1,nt
       read (12,rec=it) pc
       write (14,rec=it) pc(number)*factor
      enddo

      stop
      end
