      ALLOCATABLE DMTRX(:,:), ARR(:), AVG(:,:)
      ALLOCATABLE COV(:,:), EIGV(:), EIGF(:,:), PCTS(:)
      ALLOCATABLE TSER(:,:), EOF(:)
      ALLOCATABLE TSER1(:,:)  ! Lim
      ALLOCATABLE INDX(:)
      CHARACTER*50 FILNM1, FILNM2, FILNM3, FORMT1, FORMT2, FORMT3
      CHARACTER*3 ANS, SEQ(10)

      DATA SEQ / '0TH', '1ST', '2ND', '3RD', '4TH',
     &           '5TH', '6TH', '7TH', '8TH', '9TH' /


      PI = 4.0*ATAN(1.0)
      TPI = 2.0*PI

      PRINT *, '  Type the name and format of the time series data.'
      READ 5, FILNM1, FORMT1
      PRINT *, '  Type the size (NX x NY) of analysis station array.'
      READ *, NX, NY
      NST = NX*NY
      PRINT *, '  Type the number of samples at each station.'
      READ *, NPTS
      FNPTS = FLOAT(NPTS)
      SNPTS = SQRT(FNPTS)
      PRINT *, '  First index of the input array: (1: time, 2: space).'
      READ *, IRD
      PRINT *, '  Type smoothing option (0:No, M:Moving average lag).'
      READ *, LAG
      PRINT *, '  Type cycle period for detrending (0: No).'
      READ *, IDTR
      PRINT *, '  Type the area adjustment option (0: No, 1: Yes).'
      READ *, IARA
      PRINT *, '  Type the starting latitude and increment.'
      READ *, SLAT, DLAT
      PRINT *, '  Type percent variance to be achieved.'
      READ *, PVAR
      PRINT *, '  Type pattern scaling factor.'
      READ *, SCL
      PRINT *, '  type the number of eigenfunctions to be printed.'
      READ *, NMD
      PRINT *, '  Type the PC normalization option (0: no, 1: yes)'
      READ *, INORM
      PRINT *, '  Type the name and format of the EOF output file.'
      READ 5, FILNM2, FORMT2
      PRINT *, '  Type the name and format of the PC time series file.'
      READ 5, FILNM3, FORMT3
5     FORMAT(A50)

C ------- Allocate space for dynamic arrays
      ALLOCATE(DMTRX(NPTS,NPTS))
      ALLOCATE(ARR(NPTS))
      ALLOCATE(AVG(IDTR,NST))
      ALLOCATE(COV(NPTS,NPTS))
      ALLOCATE(EIGV(NPTS))
      ALLOCATE(EIGF(NPTS,NPTS))
      ALLOCATE(PCTS(NPTS))
      ALLOCATE(TSER(NPTS,NST))
      ALLOCATE(TSER1(NPTS,576*361))    !  Lim
      ALLOCATE(EOF(NST))
      ALLOCATE(INDX(NPTS))


C ------- Read Dataset
      SELECT CASE (FORMT1)
      CASE ('DIR')
        IF (IRD.EQ.1) THEN
          OPEN(UNIT=11, FILE=FILNM1, STATUS='OLD',
     &         ACCESS='DIRECT', RECL=NPTS)
          DO L=1,NST
            READ(11,REC=L)  (TSER(I,L), I=1,NPTS)
          END DO
        ELSE
          OPEN(UNIT=11, FILE=FILNM1, STATUS='OLD',
     &         ACCESS='DIRECT', RECL=576*361)      
c     &         ACCESS='DIRECT', RECL=NST)      
          DO I=1,NPTS
            READ(11,REC=I)  (TSER1(I,L), L=1,576*361)  ! Lim
c            READ(11,REC=I)  (TSER(I,L), L=1,NST)
          END DO
        END IF
      CASE ('SEQ')
        OPEN(UNIT=11, FILE=FILNM1, STATUS='OLD', FORM='UNFORMATTED')
        IF (IRD.EQ.1) THEN
          DO L=1,NST
            READ(11)  (TSER(I,L), I=1,NPTS)
          END DO
        ELSE
          DO I=1,NPTS
            READ(11)  (TSER(I,L), L=1,NST)
          END DO
        END IF
      CASE DEFAULT
        OPEN(UNIT=11, FILE=FILNM1, STATUS='OLD')
        IF (IRD.EQ.1) THEN
          DO L=1,NST
            READ(11,FORMT1)  (TSER(I,L), I=1,NPTS)
          END DO
        ELSE
          DO I=1,NPTS
          DO L=1,NY
            READ(11,FORMT1)  (TSER(I,K+(L-1)*NX), K=1,NX)
          END DO
          END DO
        END IF
      END SELECT

C ------- Lim
      DO I=1,NPTS 
        DO J=1,NST 
          TSER(I,J)=TSER1(I,576*180+J)
        ENDDO
      ENDDO
C -------

C ------- Smoothing
      DO 10 J=1,NST
        DO I=1,NPTS
          KS = MAX(I-LAG,1)
          KE = MIN(I+LAG,NPTS)
          KN = KE-KS+1
          SUM = 0.0
          DO K=KS,KE
            SUM = SUM + TSER(K,J)
          END DO
          ARR(I) = SUM/FLOAT(KN)
        END DO
        DO I=1,NPTS
          TSER(I,J) = ARR(I)
        END DO
10    CONTINUE

C ------- Subtract (Monthly) Mean
      IF (IDTR.NE.0) THEN
        OPEN(UNIT=9, FILE='avg.d', STATUS='UNKNOWN')
        DO J=1,NST
          DO 15 IM=1,IDTR
            SUM = 0.0
            DO K=IM,NPTS,IDTR
              SUM = SUM + TSER(K,J)/FLOAT((NPTS-IM)/IDTR+1)
            END DO
            AVG(IM,J) = SUM
            DO K=IM,NPTS,IDTR
              TSER(K,J) = TSER(K,J) - AVG(IM,J)
            END DO
15        CONTINUE
        END DO
        DO IM=1,IDTR
          WRITE(9,'(6E13.5)')  (AVG(IM,J), J=1,NST)
        END DO
      END IF

C ------- Area adjustment
      IF (IARA.EQ.1) THEN
        TAREA = 0.0
        DO J=1,NY
          JJ = J-1
          ALAT = SLAT + FLOAT(JJ)*DLAT
          TAREA = TAREA + COS(ALAT*PI/180.)
        END DO
        TAREA = TAREA*FLOAT(NX)

        DO K=1,NPTS
        DO J=1,NY
          JJ = J-1
          ALAT = SLAT + FLOAT(JJ)*DLAT
          SCLF = SQRT(COS(ALAT*PI/180.)/TAREA)*SQRT(FLOAT(NST))
          DO I=1,NX
            IJ = (J-1)*NX+I
            TSER(K,IJ) = TSER(K,IJ)*SCLF
          END DO
        END DO
        END DO
      END IF

C ------- Covariance Matrix
      DO 20 J=1,NPTS
      DO 20 I=1,NPTS
        SUMC = 0.0
        DO K=1,NST
          SUMC = SUMC + TSER(I,K)*TSER(J,K)
        END DO
        SUMC = SUMC
        COV(I,J) = SUMC/FLOAT(NST)
20    CONTINUE

C ------- Total Variance
      OPEN(UNIT=7, FILE='inform.d', STATUS='UNKNOWN')
      TVAR = 0.0
      DO 25 I=1,NPTS
        TVAR = TVAR + COV(I,I)
25    CONTINUE
      TVAR = TVAR/FNPTS
      WRITE(7,30) TVAR
30    FORMAT(5X,'TOTAL VARIANCE = ',E15.7,///)

C ------- Call Eigenvalue Routines
      CALL JACOBI(COV,NPTS,NPTS,EIGV,EIGF,NROT)
      CALL EIGSRT(EIGV,EIGF,NPTS,NPTS)
      PRINT *, '# OF JOCOBI ROTATION :', NROT
      PRINT *

C ------- Write Eigenmodes (PCs) and Modal Contributions
      SELECT CASE (FORMT3)
      CASE ('DIR')
        OPEN(UNIT=22, FILE=FILNM3, STATUS='UNKNOWN',
     &       ACCESS='DIRECT', RECL=NPTS)
      CASE ('SEQ')
        OPEN(UNIT=22, FILE=FILNM3, STATUS='UNKNOWN',
     &       FORM='UNFORMATTED')
      CASE DEFAULT
        OPEN(UNIT=22, FILE=FILNM3, STATUS='UNKNOWN')
      END SELECT

      SUM = 0.0
      DO 45 I=1,NPTS
        EIGV(I) = EIGV(I)/FNPTS
        STD = SQRT(EIGV(I))
        VAR = EIGV(I)/TVAR
        SUM = SUM + VAR
        WRITE(7,35) VAR, SUM
35      FORMAT(5X,'VARIANCE AND CUMULATIVE VARIANCE = ',2E16.7,/)
        DO J=1,NPTS
          IF (INORM.EQ.1) THEN
            PCTS(J) = EIGF(J,I)*SNPTS
          ELSE
            PCTS(J) = EIGF(J,I)*SNPTS*STD
          END IF
        END DO
        NMODE = I

        SELECT CASE (FORMT3)
        CASE ('DIR')
          WRITE(22,REC=I)  (PCTS(J), J=1,NPTS)
        CASE ('SEQ')
          WRITE(22)  (PCTS(J), J=1,NPTS)
        CASE DEFAULT
          WRITE(22,FORMT3)  (PCTS(J), J=1,NPTS)
        END SELECT

        IF (SUM*100. .GE. PVAR)  GO TO 50
45    CONTINUE
50    PRINT *, NMODE

C ------- Write EOF patterns
      SELECT CASE (FORMT2)
      CASE ('DIR')
        OPEN(UNIT=21, FILE=FILNM2, STATUS='UNKNOWN',
     &       ACCESS='DIRECT', RECL=NST)
      CASE ('SEQ')
        OPEN(UNIT=21, FILE=FILNM2, STATUS='UNKNOWN',
     &       FORM='UNFORMATTED')
      CASE DEFAULT
        OPEN(UNIT=21, FILE=FILNM2, STATUS='UNKNOWN')
      END SELECT

      DO IM=1,MIN(NMODE,NMD)
C ------- EOF Pattern
        DO J=1,NST
          SUM = 0.0
          DO K=1,NPTS
            SUM = SUM + TSER(K,J)*EIGF(K,IM)
          END DO
          EOF(J) = SUM/SNPTS
        END DO

C ------- Normalization
C        SUM = 0.0
C        DO J=1,NST
C          SUM = SUM + EOF(J)*EOF(J)
C        END DO
C        STD = SQRT(SUM/FLOAT(NST))
C        STD = SQRT(SUM)
C        STD = SQRT(EIGV(IM))
        DO L=1,NY
          IF (IARA.EQ.1) THEN
            LL = L-1
            ALAT = SLAT + FLOAT(LL)*DLAT
            SCLF = SQRT(COS(ALAT*PI/180.)/TAREA)*SQRT(FLOAT(NST))
          ELSE
            SCLF = 1.0
          END IF
        DO K=1,NX
          J = (L-1)*NX+K
          IF (INORM.EQ.1) THEN
            EOF(J) = EOF(J)/SCLF
          ELSE
            EOF(J) = EOF(J)/SCLF/SQRT(EIGV(IM))
          END IF
        END DO
        END DO

        SELECT CASE (FORMT2)
        CASE ('DIR')
          WRITE(21,REC=IM)  (EOF(J)*SCL, J=1,NST)
        CASE ('SEQ')
          WRITE(21)  (EOF(J)*SCL, J=1,NST)
        CASE DEFAULT
          DO L=1,NY
            LL = (L-1)*NX
            WRITE(21,FORMT2) (EOF(K+LL)*SCL, K=1,NX)
          END DO
        END SELECT
      END DO

      STOP
      END

      SUBROUTINE JACOBI(A,N,NP,D,V,NROT)

*******************************************************************************
*
*     This subroutine computes all eigenvalues and eigenvectors of a real
*     symmetric matrix A, which is of size N by N, stored in a physical
*     NP by NP array.  On output, elements of A above the diagonal are
*     destroyed.  D returns eigenvalues of A in its first N elements.
*     V is a matrix with the same logical and physical dimensions as A
*     whose columns contain, on output, the normalized eigenvectors of A.
*     NROT returns the number of Jacobi rotation which were required.
*
*******************************************************************************

      PARAMETER (NMX=5000)
      DIMENSION A(NP,NP), D(NP), V(NP,NP), B(NMX), Z(NMX)


      DO 12 IP=1,N
        DO 11 IQ=1,N
          V(IP,IQ)=0.
11      CONTINUE
        V(IP,IP)=1.
12    CONTINUE
      DO 13 IP=1,N
        B(IP)=A(IP,IP)
        D(IP)=B(IP)
        Z(IP)=0.
13    CONTINUE
      NROT=0
      DO 24 I=1,50
        SM=0.
        DO 15 IP=1,N-1
          DO 14 IQ=IP+1,N
            SM=SM+ABS(A(IP,IQ))
14        CONTINUE
15      CONTINUE
        IF(SM.EQ.0.)RETURN
        IF(I.LT.4)THEN
          TRESH=0.2*SM/N**2
        ELSE
          TRESH=0.
        ENDIF
        DO 22 IP=1,N-1
          DO 21 IQ=IP+1,N
            G=100.*ABS(A(IP,IQ))
            IF((I.GT.4).AND.(ABS(D(IP))+G.EQ.ABS(D(IP)))
     *         .AND.(ABS(D(IQ))+G.EQ.ABS(D(IQ))))THEN
              A(IP,IQ)=0.
            ELSE IF(ABS(A(IP,IQ)).GT.TRESH)THEN
              H=D(IQ)-D(IP)
              IF(ABS(H)+G.EQ.ABS(H))THEN
                T=A(IP,IQ)/H
              ELSE
                THETA=0.5*H/A(IP,IQ)
                T=1./(ABS(THETA)+SQRT(1.+THETA**2))
                IF(THETA.LT.0.)T=-T
              ENDIF
              C=1./SQRT(1+T**2)
              S=T*C
              TAU=S/(1.+C)
              H=T*A(IP,IQ)
              Z(IP)=Z(IP)-H
              Z(IQ)=Z(IQ)+H
              D(IP)=D(IP)-H
              D(IQ)=D(IQ)+H
              A(IP,IQ)=0.
              DO 16 J=1,IP-1
                G=A(J,IP)
                H=A(J,IQ)
                A(J,IP)=G-S*(H+G*TAU)
                A(J,IQ)=H+S*(G-H*TAU)
16            CONTINUE
              DO 17 J=IP+1,IQ-1
                G=A(IP,J)
                H=A(J,IQ)
                A(IP,J)=G-S*(H+G*TAU)
                A(J,IQ)=H+S*(G-H*TAU)
17            CONTINUE
              DO 18 J=IQ+1,N
                G=A(IP,J)
                H=A(IQ,J)
                A(IP,J)=G-S*(H+G*TAU)
                A(IQ,J)=H+S*(G-H*TAU)
18            CONTINUE
              DO 19 J=1,N
                G=V(J,IP)
                H=V(J,IQ)
                V(J,IP)=G-S*(H+G*TAU)
                V(J,IQ)=H+S*(G-H*TAU)
19            CONTINUE
              NROT=NROT+1
            ENDIF
21        CONTINUE
22      CONTINUE
        DO 23 IP=1,N
          B(IP)=B(IP)+Z(IP)
          D(IP)=B(IP)
          Z(IP)=0.
23      CONTINUE
24    CONTINUE
      PAUSE '50 iterations should never happen'
      RETURN
      END

      SUBROUTINE EIGSRT(D,V,N,NP)

      DIMENSION D(NP),V(NP,NP)


      DO 13 I=1,N-1
        K=I
        P=D(I)
        DO 11 J=I+1,N
          IF(D(J).GE.P)THEN
            K=J
            P=D(J)
          ENDIF
11      CONTINUE
        IF(K.NE.I)THEN
          D(K)=D(I)
          D(I)=P
          DO 12 J=1,N
            P=V(J,I)
            V(J,I)=V(J,K)
            V(J,K)=P
12        CONTINUE
        ENDIF
13    CONTINUE
      RETURN
      END
