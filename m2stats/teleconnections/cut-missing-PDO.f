      parameter (nx=360, ny=180, mx=360, my=180, nt=1419, lx=41119)  ! globe
c      parameter (nx=360, ny=180, mx=260, my=180, nt=1419, lx=29566)  ! Pac&Ind
c      parameter (nx=360, ny=180, mx=160, my=45, nt=1419, lx=4185)  ! Pacific
      dimension sst(nx,ny), sst1(lx)

      open (11,file='./Had-ano-remglo.d',
     &form='unformatted',access='direct',recl=nx*ny,status='old')
c      open (12,file='../../../Data/mask-GEOS5/Landmask1deg.bdat',
c     &form='unformatted',access='direct',recl=nx*ny,status='old')
      open (13,file='./HadAnoPac-remglomis.d',
     &form='unformatted',access='direct',recl=lx,status='unknown')

      do it=1,nt
       read (11,rec=it) sst
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
         sst1(ig)=sst(ii,jj+0)
c         sst1(ig)=sst(ii,jj+0)
c         sst1(ig)=sst(ii,jj+110)
        endif
        endif
        if (ii.gt.180) then
c        if (ii.gt.80) then
c        if (ii.gt.80) then
        if (sst(ii+0,jj+0).gt.-100.) then
c        if (sst(ii+180-80,jj+0).gt.-100.) then
c        if (sst(ii+280-80,jj+110).gt.-100.) then
         ig=ig+1
         sst1(ig)=sst(ii+0,jj+0)
c         sst1(ig)=sst(ii+180-80,jj+0)
c         sst1(ig)=sst(ii+280-80,jj+110)
        endif
        endif
       enddo
       enddo
       print*,it,ig
       write (13,rec=it) sst1
      enddo

      stop
      end
