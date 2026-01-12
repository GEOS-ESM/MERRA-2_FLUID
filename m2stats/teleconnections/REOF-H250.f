CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C  A. STATISTICAL ANALYSIS                                             C
C     8  EMPIRICAL ORTHOGONAL FUNCTIONS (EOF's) AND                    C
C        ROTATED EMPIRICAL ORTHOGONAL FUNCTIONS (REOF's)               C
C        (1) reof                                                      C
C        (2) transf                                                    C
C        (3) crossproduct                                              C
C        (4) jcb                                                       C
C        (5) arrang                                                    C
C        (6) tcoeff                                                    C
C        (7) rotator                                                   C
C        (8) arrange2                                                  C     
C        (9) meanvar                                                   C
C        (10)initial                                                   C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c
c     By Dr. Jianping Li and Dong Xiao, Jul. 17, 2006.
c
!*****Time-Space transfermation is used for saving calculational time.
c     The missing values (terrain), annual cycle and the grids whose variance 
c     equal to zero are removed (added) before (after) calling the subroutine.    
c
c     Reference: ¡¶Methods for Diagnosing and Forecasting Climate Variability¡·
c     By Hongbao Wu and Lei Wu, published in 2005. China Metorology Press.
c
c     Questions, suggestions or GS file for drawing pictures? Emial us, please! 
c     E-mail: ljp@lasg.iap.ac.cn, xiaodong@mail.iap.ac.cn.
c
c     Citation: Li, J., and D. Xiao, 2006: REOF subroutine, http://web.lasg.ac.cn/staff/ljp/subroutine/REOF.f.
c
c-----*----------------------------------------------------6---------7--
c
c     Warning: the stacks of this subroutine may overflow in personal computer (PC).
c       If you want to compute it on PC, please delete the expressions '*4'
c       in 68, 174, 181, 186 and 193, and go on.
c
c     The parameters you need to change:    
c	  n---length of time series, viz. sample size;
c       mx---grids in row;
c       my---grids in column; 
c       mnl---min(m,n)
c       np---num. of eigenvectors to rotate; 
c       undef---missing value; 
c       mg1 and mg2---the efficient grids (output on screen) and cancel the 
c           "stop" in line 111, try again.
c       ks=-1,0,1: see the caption of the REOF subroutine. 
c       km=1: monthly or daily data. km=0: data without annual cycle.
c       nd: the number of the months or days in a year.
c    
c-----*----------------------------------------------------6---------7--
      program main
      parameter(n=117,mx=576,my=181,mx1=576,my1=361,m=mx*my,mnl=n,np=30)
      parameter(slat=0.0,yint=0.5,undef=-9.99e+8,mg1=104256,mg2=104256)
      parameter(ks=0,km=1,nd=1,std=0.0001)
!-----input array
      dimension f0(n,m),f5(mx1*my1)
!-----work arrays
      dimension f1(n,mg1),f2(n,mg1),g(mg1),h1(mg1,n),h2(mg1,n)
      dimension f(mg2,n),gvt(mg2,mnl),rgvt(mg2,np),cof(mnl,n),rcof(np,n)
!-----output arrays
      dimension er(mnl,4),egvt(m,mnl),ecof(mnl,n)
      dimension rer(np,2),regvt(m,np),recof(np,n)

c-----Read data.
      open(20,file=
     &'./H2-DJFano19802018.d',
     &status='old',form='unformatted',access='direct',recl=mx1*my1)

        do j=1,n
          read(20,rec=j+0)f5
          do i=1,m
          f0(j,i)=f5(mx1*(my1-my)+i)
          enddo
        enddo
	close(20)
	write(*,*)'read data ok'
c-----Remove the terrain or missing value.
      l1=0
	do j=1,m
	  if(f0(1,j).ne.undef)then
          l1=l1+1
	    do k=1,n
            f1(k,l1)=f0(k,j)*  ! area weighting by Lim 
     &      sqrt(cos((slat+int((j-1)/mx)*yint)*3.1415/180.)) ! area weighting by Lim
c            f1(k,l1)=f0(k,j)  ! no weighting
	    enddo
	  endif
	enddo
      write(*,*)'grids without terrain'
	write(*,*)'mg1=',l1
c-----Remove annual cycle.
      if(km.eq.1)then
	  ny=n/nd	  
	  do i=1,l1
	    call initial(nd,ny,n,f1(1,i),f2(1,i))
	  end do 	
	  do i=1,l1
	    do k=1,n
	      f1(k,i)=f2(k,i)
	    end do
	  end do
	end if
c-----Remove the grids whose variance equal to zero.
	l2=0
	do i=1,l1
	  call meanvar(n,f1(1,i),ax,g(i),vx)	
	  if(g(i).gt.std)then
          l2=l2+1
	    do k=1,n
            f(l2,k)=f1(k,i)
	    enddo
	  endif
	end do
	write(*,*)'grids without terrain and constant value'
	write(*,*)'mg2=',l2
c        stop
c-----Call the subroutine.
      call reof(l2,n,mnl,np,f,ks,er,gvt,ecof,rer,rgvt,recof)
      write(*,*)'reof ok and transform to the original form in the next'
c-----Add the grids whose variance equal to zero.      
	l3=0
	do i=1,mg2
	  if(g(i).gt.std)then
	    l3=l3+1
	    do k=1,mnl
	      h1(i,k)=gvt(l3,k) 
	    end do
	    do k=1,np
	      h2(i,k)=rgvt(l3,k)
	    end do		
	  else
	    do k=1,mnl
	      h1(i,k)=undef
	    end do
	    do k=1,np
	      h2(i,k)=undef
	    end do
	  endif
	enddo
c-----Add the terrain or missing value.
	l4=0
	do i=1,m
	  if(f0(1,i).ne.undef)then
	    l4=l4+1
	    do k=1,mnl
	      egvt(i,k)=h1(l4,k)
	    end do
		do k=1,np
	      regvt(i,k)=h2(l4,k)
	    end do
	  else
	    do k=1,mnl
	      egvt(i,k)=undef
	    end do
	    do k=1,np
	      regvt(i,k)=undef
	    end do
	  endif
	enddo
c-----output the result.        
c-----output the error.
      write(*,*)'output the results'
c	open(10,file='er-H2-DJF19802018.d',status='unknown')
c      write(10,*)'EOF lamda (eigenvalues) from big to small'
c	write(10,*)(er(i,1),i=1,mnl)
c	write(10,*)'EOF accumulated eigenvalues from big to small'
c	write(10,*)(er(i,2),i=1,mnl)
c	write(10,*)'EOF explained variances'
c	write(10,*)(er(i,3),i=1,mnl)
c	write(10,*)'EOF accumulated explained variances'
c	write(10,*)(er(i,4),i=1,mnl)
c	write(10,*)'REOF explained variances'
c	write(10,*)(rer(i,1),i=1,np)
c	write(10,*)'REOF accumulated explained variances'
c	write(10,*)(rer(i,2),i=1,np)
c	close(10)
        open(9,file='rinf-H2-DJF19802018.d',status='unknown')   ! added by Lim (from here)
        totvar=0.0
        do jt=1,np
        avg=0.0
        var=0.0
        do it=1,n
         avg=avg+recof(jt,it)/float(n)
         var=var+recof(jt,it)*recof(jt,it)/float(n)
        enddo
        var=var-avg*avg
        totvar=totvar+var
        enddo 
        write (9, 500) totvar
        write (9, 501)
     &  (rer(i,1)/rer(np,2), rer(i,2)/rer(np,2), i=1,np)
500   format (5x, 'TOTAL VARIANCE = ',e15.7,///)
501   format (5x, 'VARIANCE AND CUMULATIVE VARIANCE = ',2e16.7,/)  ! (end)
c-----output eigenvactors matrix of EOF.
c      open(11,file='egvt-H2-DJF19802018.d',status='unknown'
cc     &,form='unformatted',access='direct',recl=mx*my*4)	
c     &,form='unformatted',access='direct',recl=mx*my)	
c	do j=1,mnl
c	  write(11,rec=j)(egvt(i,j),i=1,m)
c	end do
c	close(11)
c-----output time coefficients matrix of EOF.
c      open(12,file='ecof-H2-DJF19802018.d',status='unknown'
cc     &,form='unformatted',access='direct',recl=mnl*4)
c     &,form='unformatted',access='direct',recl=mnl)
c      do i=1,n
c	  write(12,rec=i)(ecof(j,i),j=1,mnl)
c	end do
c	close(12)
c-----output loading vectors of REOF.
      open(13,file='ev-H2-DJF19802018.d',status='unknown'
c     &,form='unformatted',access='direct',recl=mx*my*4)
     &,form='unformatted',access='direct',recl=mx*my)
      do j=1,np
       write(13,rec=j)(regvt(i,j)*sqrt(totvar*rer(j,1)/rer(np,2)),i=1,m) ! Lim
c	  write(13,rec=j)(regvt(i,j),i=1,m)
	end do
	close(13)
c-----output time coefficients matrix of REOF.
      open(14,file='pc-H2-DJF19802018.d',status='unknown'
     &,form='unformatted',access='direct',recl=np)
c      open(15,file='recof-asc-H250-10S90N.dat',status='unknown')
      do j=1,n
      write(14,rec=j)(recof(i,j)/sqrt(totvar*rer(i,1)/rer(np,2)),i=1,np) ! Lim
c        write(14,rec=j)(recof(i,j),i=1,np)
	end do
c      do j=1,np   ! PC writing in asc (Lim)
c        write(15,'(6e13.5)') (recof(j,kk),kk=1,n)
c      end do      ! (end)
	close(14)
c-----
	end
c-----*----------------------------------------------------6---------7--
C     Rotated Emperical orthogonal function (REOF)
c     This subroutine applies the REOF approach to analysis
c       time series of meteorological field f(m,n).
c
c     input: m,n,mnl,np,f(m,n),ks
c       m: number of grid-points
c       n: length of time series, viz. sample size
c       mnl=min(m,n)
c       np: the number of the eigenvactors to rotate 
c         (the corresponding EOF accumulated variance is about 60-80% or the 
c         corresponding eigenvalues of EOF exceed 1.0 )
c       f(m,n): the raw spatial-temporal seires
c       ks: contral parameter
c           ks=-1: self; ks=0: depature; ks=1: standerlized depature
c       self: generally not be adapted, the first modes like the climate normal.
c           the others are same as the modes of departure field.
c       departure: the eigenvectors stand for the averaged anomalies of the variable.
c           the larger the anomalies, the more the contribution. 
c           It would emphasize the regions with larger anomalies.
c           suggestion: mainly used in larger scale field.
c 	  standard: the eigenvectors stand for the correlation coefficients
c           between the timeseries of the grids and the corresponding time coefficients.
c           standard=departure/(standard deviation). it compute every grid in same level.
c           There is no regional difference in this kind field.
c           suggestion: mainly used in the correlations of different regions.
c
c     output: egvt,ecof,er,rer,regvt,recof
c       egvt(m,mnl): array of eigenvactors
c       ecof(mnl,n): array of time coefficients for the respective eigenvectors
c       er(mnl,1): lamda (eigenvalues), its equence is from big to small.
c       er(mnl,2): accumulated eigenvalues from big to small
c       er(mnl,3): explained variances (lamda/total explain) from big to small
c       er(mnl,4): accumulated explained variances from big to small
c       rer(mnl,1): explained variances (lamda/total explain) 
c       rer(mnl,2): accumulated explained variances 
c       regvt(m,np): rodated array of loading vectors of REOF 
c       recof(mnl,np): rodated array of time coefficients for the respective eigenvectors
c
c     By Dong Xiao and Dr. Jianping Li, Jul. 17, 2006
c     Recmoplied on May 9, 2007
c
c     Reference: ¡¶Methods for Diagnosing and Forecasting Climate Variability¡·
c     By Hongbao Wu and Lei Wu, published in 2005. China Metorology Press.
c-----
      subroutine reof(m,n,mnl,np,f,ks,er,egvt,ecof,rer,regvt,recof)
!-----input array
      dimension f(m,n)
!-----work arrays
      dimension cov(mnl,mnl),s(mnl,mnl),d(mnl)
!-----output arrays
      dimension er(mnl,4),egvt(m,mnl),ecof(mnl,n)
      dimension rer(np,2),regvt(m,np),recof(np,n)


c---- Preprocessing data
      call transf(m,n,f,ks)	
c---- Crossed product matrix of the data f
      call crossproduct(m,n,mnl,f,cov,sum)	
c---- Eigenvalues and eigenvectors by the Jacobi method 
      eps=1e-7
      call jcb(mnl,cov,s,d,eps)
c---- Specified eigenvalues 
      call arrang(m,n,mnl,d,s,er,tr)
	write(*,*)'error=',sum,tr,sum-tr	
c	write(*,*)'error=',sum-tr	
c---- Normalized eignvectors and their time coefficients 
      call tcoeff(m,n,mnl,f,s,er,egvt,ecof) 
	write(*,*)'EOF accomplished'
c-----linear transposed (rotate)
      call rotaor(m,n,mnl,np,egvt,ecof,tr,rer,regvt,recof)
	write(*,*)'REOF accomplished'
c---- Specified eignvectors and time coefficients with explained variances of REOF (if you need)     
      call arrange2(m,n,np,regvt,recof,rer)
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Preprocessing data to provide a field by ks.
c
c     input: m,n,f,ks
c       m: number of grid-points
c       n: length of time series, viz. sample size
c       f(m,n): the raw spatial-temporal seires
c       ks: contral parameter
c           ks=-1: self; ks=0: depature; ks=1: standerdlized depature
c
c     output: f
c       f(m,n): output field based on the control parameter ks.
c
c     By Dr. Jianping Li.
c-----
      subroutine transf(m,n,f,ks)
!-----input array
      dimension f(m,n)
!-----work arrays
      dimension fw(n),wn(m)

	i0=0
	do i=1,m
	  do j=1,n
          fw(j)=f(i,j)
        enddo
	  call meanvar(n,fw,af,sf,vf)
	  if(sf.eq.0.)then
	    i0=i0+1
	    wn(i0)=i
	  endif
	enddo
	if(i0.ne.0)then
	  write(*,*)'****  FAULT  ****'
        write(*,*)' The program cannot go on because the original field'
        write(*,*)'     has invalid data whose variance equal zero.'
	  write(*,*)
	  write(*,*)' There are totally',i0,'       gridpionts 
     *with invalid data.'
	  write(*,*)
        write(*,*)' The array WN stores the positions of those invalid '
        write(*,*)'     grid-points. You must pick off those invalid '  
        write(*,*)'     data from the orignal field and then reinput '  
        write(*,*)'     a new field to calculate its EOFs.'   
	  write(*,*)'****  FAULT  ****'
	  stop
	endif	 	  
      if(ks.eq.-1)return
c-----anomaly of f
      if(ks.eq.0)then                
        do i=1,m
          do j=1,n
            fw(j)=f(i,j)
          enddo
          call meanvar(n,fw,af,sf,vf)
          do j=1,n
            f(i,j)=f(i,j)-af
          enddo
        enddo
        return
      endif
c-----normalizing f
      if(ks.eq.1)then                 
        do i=1,m
          do j=1,n
            fw(j)=f(i,j)
          enddo
          call meanvar(n,fw,af,sf,vf)
          do j=1,n
            f(i,j)=(f(i,j)-af)/sf
          enddo
        enddo
      endif
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Crossed product martix of the data. It is n times of 
c       covariance matrix of the data if ks=0 (i.e. for anomaly). 
c
c     input: m,n,mnl,f
c       m: number of grid-points
c       n: length of time series, viz. sample size
c       mnl=min(m,n)
c       f(m,n): the raw spatial-temporal seires
c
c     output: cov(mnl,mnl),sum  
c       cov(m,n)=(f*f') or (f'f) dependes on m and n.
c         It is a mnl*mnl real symmetric matrix.
c       sum: the tra of the matrix (f*f')/n 
c
c     By Dr. Jianping Li.
c     Recompiled by Dong Xiao, jul. 17, 2006
c-----
      subroutine crossproduct(m,n,mnl,f,cov,sum)
!-----input array
      dimension f(m,n)
!-----work array
	dimension cov(mnl,mnl)

      if(n-m) 10,50,50
  10  do 20 i=1,mnl
      do 20 j=i,mnl
        cov(i,j)=0.0
        do is=1,m
          cov(i,j)=cov(i,j)+f(is,i)*f(is,j)
        enddo
        cov(j,i)=cov(i,j)
  20  continue
      sum=0.
	do i=1,mnl
	sum=sum+cov(i,i)
	end do
	sum=sum/(mnl*1.)
      return
  50  do 60 i=1,mnl
      do 60 j=i,mnl
        cov(i,j)=0.0
        do js=1,n
          cov(i,j)=cov(i,j)+f(i,js)*f(j,js)
        enddo
        cov(j,i)=cov(i,j)
  60  continue
      sum=0.
	do i=1,mnl
	sum=sum+cov(i,i)
	end do
	sum=sum/(mnl*1.)
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Computing eigenvalues and eigenvectors of a real symmetric matrix
c       a(m,m) by the Jacobi method
c
c     input: m,a,s,d,eps 
c       m: order of matrix
c       a(m,m): the covariance matrix
c       eps: given precision
c
c     output: s,d 
c       s(m,m): eigenvectors
c       d(m): eigenvalues
c
c     By Dr. Jianping Li.
c-----
      subroutine jcb(m,a,s,d,eps)
!-----input array
      dimension a(m,m)
!-----output arrays
	dimension s(m,m),d(m)

      do 30 i=1,m
      do 30 j=1,i
        if(i-j) 20,10,20
  10    s(i,j)=1.
        go to 30
  20    s(i,j)=0.
        s(j,i)=0.
  30  continue
      g=0.
      do 40 i=2,m
        i1=i-1
        do 40 j=1,i1
  40      g=g+2.*a(i,j)*a(i,j)
      s1=sqrt(g)
      s2=eps/float(m)*s1
      s3=s1
      l=0
  50  s3=s3/float(m)
  60  do 130 iq=2,m
        iq1=iq-1
        do 130 ip=1,iq1
        if(abs(a(ip,iq)).lt.s3) goto 130
        l=1
        v1=a(ip,ip)
        v2=a(ip,iq)
        v3=a(iq,iq)
        u=0.5*(v1-v3)
        if(u.eq.0.0) g=1.
        if(abs(u).ge.1e-10) g=-sign(1.,u)*v2/sqrt(v2*v2+u*u)
        st=g/sqrt(2.*(1.+sqrt(1.-g*g)))
        ct=sqrt(1.-st*st)
        do 110 i=1,m
          g=a(i,ip)*ct-a(i,iq)*st
          a(i,iq)=a(i,ip)*st+a(i,iq)*ct
          a(i,ip)=g
          g=s(i,ip)*ct-s(i,iq)*st
          s(i,iq)=s(i,ip)*st+s(i,iq)*ct
  110     s(i,ip)=g
        do 120 i=1,m
          a(ip,i)=a(i,ip)
  120     a(iq,i)=a(i,iq)
        g=2.*v2*st*ct
        a(ip,ip)=v1*ct*ct+v3*st*st-g
        a(iq,iq)=v1*st*st+v3*ct*ct+g
        a(ip,iq)=(v1-v3)*st*ct+v2*(ct*ct-st*st)
        a(iq,ip)=a(ip,iq)
  130 continue
      if(l-1) 150,140,150
  140 l=0
      go to 60
  150 if(s3.gt.s2) goto 50
      do 160 i=1,m
        d(i)=a(i,i)
  160 continue
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Provides a series of eigenvalues from maximuim to minimuim.
c
c     input: m,n,mnl,d,s
c       m: number of grid-points
c       n: length of time series, viz. sample size
c       d(mnl): eigenvalues 
c       s(mnl,mnl): eigenvectors
c
c     output: er,tr
c       er(mnl,1): lamda (eigenvalues), its equence is from big to small.
c       er(mnl,2): accumulated eigenvalues from big to small
c       er(mnl,3): explained variances (lamda/total explain) from big to small
c       er(mnl,4): accumulated explaned variances from big to small
c       tr: the tra of the eigenvectors matrix.
c
c     By Dr. Jianping Li.
c----- 
      subroutine arrang(m,n,mnl,d,s,er,tr)
!-----input arrays
      dimension d(mnl),s(mnl,mnl)
!-----output array
	dimension er(mnl,4)

	tr=0.0
      do 10 i=1,mnl
        tr=tr+d(i)/(mnl*1.)
        er(i,1)=d(i)/(mnl*1.)
  10  continue
      mnl1=mnl-1
      do 20 k1=mnl1,1,-1
      do 20 k2=k1,mnl1
        if(er(k2,1).lt.er(k2+1,1)) then
          c=er(k2+1,1)
          er(k2+1,1)=er(k2,1)
          er(k2,1)=c
          do 15 i=1,mnl
            c=s(i,k2+1)
            s(i,k2+1)=s(i,k2)
            s(i,k2)=c
  15      continue
        endif
  20  continue
      er(1,2)=er(1,1)
      do 30 i=2,mnl
        er(i,2)=er(i-1,2)+er(i,1)
  30  continue
      do 40 i=1,mnl
        er(i,3)=er(i,1)*100./tr
        er(i,4)=er(i,2)*100./tr
  40  continue
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Provides eigenvectors and their time coefficients
c
c     input: m,n,mnl,f,s,er
c       m: number of grid-points
c       n: length of time series, viz. sample size
c       mnl=min(m,n)
c       f(m,n): the raw spatial-temporal seires
c       s(mnl,mnl): eigenvectors
c       er(mnl,1): lamda (eigenvalues), its equence is from big to small.
c       er(mnl,2): accumulated eigenvalues from big to small.
c       er(mnl,3): explained variances (lamda/total explain) from big to small.
c       er(mnl,4): accumulated explaned variances from big to small.
c
c     output: egvt,ecof
c       egvt(m,mnl): new eigenvectors
c         departure: the eigenvectors stand for the swing of the variable.
c 	    standard: the eigenvectors stand for the correlation coefficients
c           between the timeseries and the corresponding time coefficients.
c       ecof(mnl,n): time coefficients of egvt 
c
c     By Dr. Jianping.Li
c     Recompiled by Dong Xiao, jul. 17, 2006
c-----
      subroutine tcoeff(m,n,mnl,f,s,er,egvt,ecof)
!-----input arrays
      dimension f(m,n),s(mnl,mnl),er(mnl,4)
!-----work arrays
      dimension v(m),v1(n)
!-----output arrays
	dimension egvt(m,mnl),ecof(mnl,n)

      do j=1,mnl
        do i=1,m
          egvt(i,j)=0.
        enddo
        do i=1,n
          ecof(j,i)=0.
        enddo
      enddo
c-----Normalizing the input eignvectors (c=sqrt(lamda))
      do 10 j=1,mnl
        c=0.
        do i=1,mnl
          c=c+s(i,j)*s(i,j)
        enddo
        c=sqrt(c)
        do i=1,mnl
          s(i,j)=s(i,j)/c
        enddo
  10  continue
c-----(m<n)
      if(m.le.n) then       
	  do js=1,mnl
          do i=1,m
            egvt(i,js)=s(i,js)
          enddo
        enddo
        do 30 j=1,n
          do i=1,m
            v(i)=f(i,j)
          enddo
          do is=1,mnl
            do i=1,m
              ecof(is,j)=ecof(is,j)+v(i)*egvt(i,is)
            enddo
          enddo
  30    continue
      else
c-----(m>n)
        do 40 i=1,m
          do j=1,n
            v1(j)=f(i,j)
          enddo
          do js=1,mnl
          do j=1,n
            egvt(i,js)=egvt(i,js)+v1(j)*s(j,js)
          enddo
          enddo
  40    continue
        do 60 j=1,n
          do i=1,m
            v(i)=f(i,j)
          enddo
!-----Z=V'(n*m)X(m*n)-------not be adopted, need to be nomoralized again. 
c          do is=1,mnl
c            do i=1,n
c              ecof(is,j)=ecof(is,j)+v(i)*egvt(i,is)
c            enddo
c          enddo
  60    continue
c-----Z=V'sqrt(lamda)---(Z=V'X=>ZV=V'XV=V'(lamda*V)=(lamda*V')V=>Z=lamda*V' or V=0)
c     the lamda here is 1/n times of that in the reference.
        do 50 js=1,mnl
          do j=1,n
            ecof(js,j)=s(j,js)*sqrt(abs(er(js,1))/(mnl*1.0))
          enddo
          do i=1,m
            egvt(i,js)=egvt(i,js)/sqrt(abs(er(js,1))/(mnl*1.0))  ! normalization
          enddo
  50    continue
c-----transfer normalized eigenvectors and time coefficients to new ones
c     for new means:
c       departure: the eigenvectors stand for the swing of the variable.
c 	  standard: the eigenvectors stand for the correlation coefficients
c         between the timeseries and the corresponding time coefficients.
      do js=1,mnl
	  do i=1,m
          egvt(i,js)=egvt(i,js)*(sqrt(abs(er(js,1))))  ! 
	  end do
	  do i=1,n
          ecof(js,i)=(ecof(js,i))/(sqrt(abs(er(js,1))))  ! 
	  end do
	end do
	end if
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Computing eigenvalues and eigenvectors of a real symmetric matrix
c       a(m,n) by the rotated method
c
c     input: m,n,mnl,np,egvt,ecof,tr 
c       m: grids
c       n: length of time series, viz. sample size
c       mnl=min(m,n) 
c       np: num. of eigenvectors to rotate
c       egvt(m,n): the eigenvactors matrix
c       tr: the rank of the eigenvectors matrix
c
c     output: regvt,recof,rer
c       regvt(m,np): the rotated array of eigenvactors (Loading Vector)
c       recof(np,n): array of time coefficients for the respective eigenvectors
c       rer(mnl,1): explained variances (lamda/total explain) 
c       rer(mnl,2): accumulated explained variances 
c
c     reference: ¡¶Methods for Diagnosing and Forecasting Climate Variability¡·
c       By Hongbao Wu and Lei Wu, published in 2005. China Metorology Press.
c
c     By prof. Hongbao Wu
c     Becompiled by Dong Xiao, July 17, 2006
c-----
	subroutine rotaor(m,n,mnl,np,egvt,ecof,tr,rer,regvt,recof)
!-----input arrays
	dimension egvt(m,mnl),ecof(mnl,n)	 
!-----work arrays	
	dimension h(m),st(np),vrlv(500),er(mnl,4),s(m,np)
!-----output arrays	 
      dimension regvt(m,np),recof(np,n),rer(np,2)
      integer t,k

      write(*,*)'rotate beginning'
c-----Take out forward NP eigenvectors to rotate
      do j=1,np
        do i=1,m
	    regvt(i,j)=egvt(i,j)
	  end do
	end do
c-----Take out forward NP time coefficients to rotate
      do i=1,np
        do j=1,n
		recof(i,j)=ecof(i,j)
        end do
	end do
c-----compute the common degree
      do i=1,m
	  h(i)=0.0
        do j=1,np
 		h(i)=h(i)+regvt(i,j)**2
        end do
	end do
      do i=1,m
	  h(i)=sqrt(h(i))
      end do
c-----compute the variance of the variance contribution by per common degree 
c-----(equal to the ratated one)
      vrlv0=0.0
      do k=1,np
	  g1=0.0
        g2=0.0
        do i=1,m
		g1=g1+(regvt(i,k)**2/h(i)**2)**2/real(m)
		g2=g2+(regvt(i,k)**2/h(i)**2)/real(m)
        end do
	  g2=g2**2
	  vrlv0=vrlv0+g1-g2
      end do
c-----rotated
      lll=0
	write(*,*)'rotate times'
 800  continue
      do 505 t=1,np
      do 505 k=1,np
        if(t.ge.k) goto 505
		call rot(regvt,recof,h,t,k,m,n,np)
 505  continue
      lll=lll+1
	write(*,*)'LLL=',LLL
      vrlv(lll)=0.0
      do k=1,np
	  g1=0.0
	  g2=0.0
        do i=1,m
	    g1=g1+(regvt(i,k)**2/h(i)**2)**2/real(m)
 	    g2=g2+(regvt(i,k)**2/h(i)**2)/real(m)
        end do
	  g2=g2**2
	  vrlv(lll)=vrlv(lll)+g1-g2
      end do
      if(lll.lt.2) goto 800
	ci=(vrlv(lll)-vrlv(lll-1))/vrlv0
	if(ci.lt.0.001) goto 600
	if(lll.ge.100) goto 600
      goto 800
 600  continue
c-----compute the explained variances
	do j=1,np
	  st(j)=0.0
        do i=1,m
 		st(j)=st(j)+regvt(i,j)**2
        end do
      end do
      do j=1,np
	  rer(j,1)=st(j)*100/tr
	end do
c-----compute the accumulated explained variances
      ddd=0.0
      do k=1,np
        ddd=ddd+st(k)/tr
        rer(k,2)=ddd*100.
      enddo
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Computing eigenvalues and eigenvectors of two columns of
c       a(m,t) and a(m,k) by the rotated method
c
c     input: a,b,h,t,k,mm,nn,np 
c       a(m,np): the covariance matrix
c       b(np,n): the time coefficient matrix
c       h(m): common degree.
c       t: column 1 (grid 1)
c       k: column 2 (grid 2)
c       m: grids
c       n: length of time series, viz. sample size
c       np: num. of eigenvectors to rotate
c
c     output: a,b 
c       a(m,np): the rotated covariance matrix
c       b(np,n): time coefficient matrix
c
c     By prof. Hongbao Wu
c     Becompiled by Dong Xiao, Jul 17, 2006
c-----
      subroutine rot(a,b,h,t,k,m,n,np)
!-----input arrays
      dimension a(m,np),b(np,n),h(m)
!-----work arrays
      dimension u(m),vr(m),wt(m),wk(m),wbt(n),wbk(n)
!-----output arrays
c      dimension a(m,np),b(np,n)
      integer t,k

c-----compute fi
      do 25 i=1,m
      u(i)=(a(i,t)/h(i))**2-(a(i,k)/h(i))**2
 25   vr(i)=2.0*(a(i,t)/h(i))*(a(i,k)/h(i))
      c=0.0
      d=0.0
      s=0.0
      g=0.0
      do 30 i=1,m
      c=c+(u(i)**2-vr(i)**2)
      d=d+2.0*u(i)*vr(i)
      s=s+u(i)
 30   g=g+vr(i)
      tg1=d-2.0*s*g/(m*1.)
      tg2=c-(s**2-g**2)/(m*1.)
      fi=atan2(tg1,tg2)/4.0
c-----compute new a and b with fi 
      do 75 i=1,m
      wt(i)=a(i,t)
 75   wk(i)=a(i,k)
      do 84 kk=1,n
      wbt(kk)=b(t,kk)
 84   wbk(kk)=b(k,kk)
      do 78 i=1,m
      a(i,t)=wt(i)*cos(fi)+wk(i)*sin(fi)
 78   a(i,k)=wt(i)*(-sin(fi))+wk(i)*cos(fi)
      do 89 it=1,n
      b(t,it)=wbt(it)*cos(fi)+wbk(it)*sin(fi)
 89   b(k,it)=wbt(it)*(-sin(fi))+wbk(it)*cos(fi)
c-----
      return
      end
c-----*----------------------------------------------------6--------7--
c     Specified eignvectors and time coefficients with explained variances
c       of REOF (if you need). if not, the loading vectors of REOF  
c       corresponds to the EOF modes.
c
c     input: m,n,np,regvt,recof,tr 
c       m: grids
c       n: length of time series, viz. sample size
c       np: num. of eigenvectors to rotate
c       regvt(m,np): the rotated array of eigenvactors (Loading Vector)
c       recof(np,n): array of time coefficients for the respective eigenvectors
c       rer(mnl,1): explained variances (lamda/total explain) 
c       rer(mnl,2): accumulated explained variances
c
c     output: regvt,recof,rer
c       regvt(m,np): the rotated array of eigenvactors (Loading Vector)
c       recof(np,n): array of time coefficients for the respective eigenvectors
c       rer(mnl,1): explained variances (lamda/total explain) 
c       rer(mnl,2): accumulated explained variances
c
c     By Dong Xiao, Aug 21, 2006
c-----
      subroutine arrange2(m,n,np,regvt,recof,rer)
!-----input and output arrays	 
      dimension regvt(m,np),recof(np,n),rer(np,2)

      mnl1=np-1
      do 20 k1=mnl1,1,-1
      do 20 k2=k1,mnl1
        if(rer(k2,1).lt.rer(k2+1,1)) then
          c=rer(k2+1,1)
          rer(k2+1,1)=rer(k2,1)
          rer(k2,1)=c
          do i=1,m
            d=regvt(i,k2+1)
            regvt(i,k2+1)=regvt(i,k2)
            regvt(i,k2)=d
          end do
          do i=1,n
            e=recof(k2+1,i)
            recof(k2+1,i)=recof(k2,i)
            recof(k2,i)=e
          end do
        endif
  20  continue
      do i=1,np
	  rer(i,2)=0.0
	end do
      rer(1,2)=rer(1,1)
      do 30 i=2,np
        rer(i,2)=rer(i-1,2)+rer(i,1)
  30  continue
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     Computing the mean ax, standard deviation sx
c       and variance vx of a series x(i) (i=1,...,n).
c
c     input: n and x(n)
c       n: length of raw series
c       x(n): raw series
c
c     output: ax, sx and vx
c       ax: the mean value of x(n)
c       sx: the standard deviation of x(n)
c       vx: the variance of x(n)
c
c     By Dr. Jianping Li, May 6, 1999.
c-----
      subroutine meanvar(n,x,ax,sx,vx)
!-----input array
      dimension x(n)

      ax=0.
      vx=0.
      sx=0.
      do 10 i=1,n
        ax=ax+x(i)
  10  continue
      ax=ax/float(n)
      do 20 i=1,n
        vx=vx+(x(i)-ax)**2
  20  continue
      vx=vx/float(n)
      sx=sqrt(vx)
c-----
      return
      end
c-----*----------------------------------------------------6---------7--
c     This subroutine is for removing annual cycle (Monthly of daily data)
c     
c     input:
c       nd: number of days or monthes in a year. 
c       ny: number of year
c       ndy=nd*ny
c       f(ndy): the daily of monthly data.
c
c     output:
c       af(ndy): the daily of monthly data without annual cycle
c
c     by Dr Jianping Li,  
c     recomplied by Dong Xiao on May 7, 2007
c-----
      subroutine initial(nd,ny,ndy,f,af)
!-----input array
	real f(ndy)
!-----work arrays
	real fave(nd),fstd(nd)
!-----output array
	real af(ndy)
c-----
	do i=1,nd
	  fave(i)=0.
	  do j=1,ny
	    fave(i)=fave(i)+f(i+(j-1)*nd)
	  enddo
	  fave(i)=fave(i)/ny
	  fstd(i)=0.0
	  do j=1,ny
	    fstd(i)=fstd(i)+(f(i+(j-1)*nd)-fave(i))**2
	  enddo
	  fstd(i)=sqrt(fstd(i)/float(ny))
	  do j=1,ny
	    ij=i+(j-1)*nd
c-----standard departure
c	    af(ij)=(f(ij)-fave(i))/fstd(i)
c-----departure
	af(ij)=(f(ij)-fave(i))
	  enddo
	enddo
c-----
	return
	end
c-----*----------------------------------------------------6---------7--
