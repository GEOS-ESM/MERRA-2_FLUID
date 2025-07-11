      parameter (nx=576,ny=201,mode=12,ntel=9,nt=516)
      dimension evref(nx,ny),evref1(ntel,nx,ny),ev(nx,ny),pc(mode)

      open (11,file='ev-H2-ANN19802021ref.d',form='unformatted',
     & access='direct',recl=nx*ny,status='old')
      open (12,file='pc-H2-DJF19802018.d',form='unformatted',
     & access='direct',recl=mode,status='old')
      open (13,file='ev-H2-DJF19802018.d',form='unformatted',
     & access='direct',recl=nx*ny,status='old')

      open (14,file='pc-TELE-DJF19802018_ENDM.d',form='unformatted',
     & access='direct',recl=1,status='unknown')
      open (15,file='ev-TELE-DJF19802018_ENDM.d',form='unformatted',
     & access='direct',recl=nx*ny,status='unknown')

      itel=3
      cormax=0.0

      do 1 im=1,mode
       read (11,rec=im) evref
       do 2 jj=1,ny
       do 2 ii=1,nx
        if (im .eq. 1) then
         evref1(3,ii,jj)=-evref(ii,jj)
        else if (im .eq. 2) then 
         evref1(1,ii,jj)=evref(ii,jj)
        else if (im .eq. 3) then 
         evref1(2,ii,jj)=-evref(ii,jj)
        else if (im .eq. 5) then 
         evref1(4,ii,jj)=-evref(ii,jj)
        else if (im .eq. 6) then 
         evref1(6,ii,jj)=-evref(ii,jj)
        else if (im .eq. 7) then 
         evref1(5,ii,jj)=evref(ii,jj)
        else if (im .eq. 9) then 
         evref1(9,ii,jj)=-evref(ii,jj)
        else if (im .eq. 10) then 
         evref1(7,ii,jj)=-evref(ii,jj)
        else if (im .eq. 11) then 
         evref1(8,ii,jj)=evref(ii,jj)
        endif
2      continue
1     continue

      do 5 im=1,mode
      var1=0.0
      var2=0.0
      covar=0.0
       read (13,rec=im) ev
       do jj=1,ny
       do ii=1,nx
       var1=var1+evref1(itel,ii,jj)*evref1(itel,ii,jj)/float(nx*ny)
       var2=var2+ev(ii,jj)*ev(ii,jj)/float(nx*ny)
       covar=covar+evref1(itel,ii,jj)*ev(ii,jj)/float(nx*ny)
       enddo
       enddo
      cor=covar/(sqrt(var1)*sqrt(var2))
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
       ev(ii,jj)=ev(ii,jj)*factor
      enddo
      enddo
      write (15,rec=1) ev
      do it=1,nt
       read (12,rec=it) pc
       write (14,rec=it) pc(number)*factor
      enddo

      stop
      end
