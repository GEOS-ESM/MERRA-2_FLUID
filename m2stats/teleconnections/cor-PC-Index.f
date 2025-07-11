      parameter (nx=576,ny=201,mode=12,ntel=9,nt=516,iskip=0)
      dimension pc(mode),tind(ntel),ev(nx,ny)

      open (11,file='pc-H2-DJF19802018.d',form='unformatted',
     & access='direct',recl=mode,status='old')
      open (12,file='Tel-ENSO-ALL-8022.d',form='unformatted',
     & access='direct',recl=ntel,status='old')
      open (13,file='ev-H2-DJF19802018.d',form='unformatted',
     & access='direct',recl=nx*ny,status='old')

      open (14,file='pc-TELE-DJF19802018.d',form='unformatted',
     & access='direct',recl=1,status='unknown')
      open (15,file='ev-TELE-DJF19802018.d',form='unformatted',
     & access='direct',recl=nx*ny,status='unknown')

      itel=3
      cormax=0.0

      do 5 im=1,mode
      var1=0.0
      var2=0.0
      covar=0.0
      do 10 it=1,nt
       read (11,rec=it) pc
       read (12,rec=iskip+it) tind
       var1=var1+pc(im)*pc(im)/float(nt)
       var2=var2+tind(itel)*tind(itel)/float(nt)
       covar=covar+pc(im)*tind(itel)/float(nt)
10    continue
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
       read (11,rec=it) pc
       write (14,rec=it) pc(number)*factor
      enddo

      stop
      end
