      parameter (nx=360, ny=180, mx=120, my=60, nt=1419, lx=4531)  
      dimension sst(nx,ny), sst1(lx)

      open (11,file='./Had-ano-remglo.d',
     &form='unformatted',access='direct',recl=nx*ny,status='old')
c      open (12,file='../../../Data/mask-GEOS5/Landmask1deg.bdat',
c     &form='unformatted',access='direct',recl=nx*ny,status='old')
      open (13,file='./HadAnoInd-remglomis.d',
     &form='unformatted',access='direct',recl=lx,status='unknown')

      do it=1,nt
       read (11,rec=it) sst
       ig=0
       do jj=1,my
       do ii=1,mx
        if (sst(ii+210,jj+60).gt.-100.) then
         ig=ig+1
         sst1(ig)=sst(ii+210,jj+60)
        endif
       enddo
       enddo
       print*,it,ig
       write (13,rec=it) sst1
      enddo

      stop
      end
