      parameter (nx=360, ny=180, mx=90, my=70, nm=4, lx=4315)
      dimension sst(nx,ny), ev(lx), rev(mx,my) 

      open (11,file='./ev-AMO.d',
     &form='unformatted',access='direct',recl=lx,status='old')
      open (12,file='/discover/nobackup/ylim/Data/SST
     &/Had-mon18702021-remglo.d',
     &form='unformatted',access='direct',recl=nx*ny,status='old')
      open (13,file='./ev-AMO-recover.d',
     &form='unformatted',access='direct',recl=mx*my,status='unknown')

      read (12,rec=373) sst

      do it=1,nm
       read (11,rec=it) ev
       ig=0
       do jj=1,my
       do ii=1,mx
        if (sst(ii+90,jj+90).gt.-100.) then
         ig=ig+1
         rev(ii,jj)=ev(ig)
        else
         rev(ii,jj)=-9999.
        endif
       enddo
       enddo
       print*,it,ig
       write (13,rec=it) rev
      enddo

      stop
      end
