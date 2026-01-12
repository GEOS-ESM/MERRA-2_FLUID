      parameter (nx=360, ny=180, mx=360, my=180, nm=4, lx=41119)
c      parameter (nx=360, ny=180, mx=260, my=180, nm=4, lx=29566)
c      parameter (nx=360, ny=180, mx=160, my=45, nm=4, lx=4185)
      dimension sst(nx,ny), ev(lx), rev(mx,my) 

      open (11,file='./ev-PDO.d',
     &form='unformatted',access='direct',recl=lx,status='old')
      open (12,file='/discover/nobackup/ylim/Data/SST
     &/Had-mon18702021-remglo.d',
     &form='unformatted',access='direct',recl=nx*ny,status='old')
      open (13,file='./ev-PDO-recover.d',
     &form='unformatted',access='direct',recl=mx*my,status='unknown')

      read (12,rec=373) sst

      do it=1,nm
       read (11,rec=it) ev
       ig=0
       do jj=1,my
       do ii=1,mx
        if (ii.le.180) then
c        if (ii.le.80) then
c        if (ii.le.80) then
        if (sst(ii,jj+0).gt.-100.) then
c        if (sst(ii,jj+0).gt.-100.) then
c        if (sst(ii,jj+110).gt.-100.) then
         ig=ig+1
         rev(ii+180,jj)=ev(ig)
c         rev(ii+180,jj)=ev(ig)
c         rev(ii+80,jj)=ev(ig)
        else
         rev(ii+180,jj)=-9999.
c         rev(ii+180,jj)=-9999.
c         rev(ii+80,jj)=-9999.
        endif
        endif
        if (ii.gt.180) then
c        if (ii.gt.80) then
c        if (ii.gt.80) then
        if (sst(ii+0,jj+0).gt.-100.) then
c        if (sst(ii+180-80,jj+0).gt.-100.) then
c        if (sst(ii+280-80,jj+110).gt.-100.) then
         ig=ig+1
         rev(ii-180,jj)=ev(ig)
c         rev(ii-80,jj)=ev(ig)
c         rev(ii-80,jj)=ev(ig)
        else
         rev(ii-180,jj)=-9999.
c         rev(ii-80,jj)=-9999.
c         rev(ii-80,jj)=-9999.
        endif
        endif
       enddo
       enddo
       print*,it,ig
       write (13,rec=it) rev
      enddo

      stop
      end
