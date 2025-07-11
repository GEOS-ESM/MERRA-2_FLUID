      parameter (mx=4, lx=1419)
      dimension pc(lx), pc1(lx,mx)

      open (11,file='./pc-PDO.d',
     &form='unformatted',access='direct',recl=lx,status='old')
      open (12,file='./pc-PDO-DJF18702021.d',
     &form='unformatted',access='direct',recl=mx,status='unknown')

      do it=1,mx
       read (11,rec=it) pc
       do jt=1,lx
        pc1(jt,it)=pc(jt)
       enddo
      enddo

      do kt=1,lx
       write (12,rec=kt) (pc1(kt,lt),lt=1,mx) 
      enddo
      stop
      end
