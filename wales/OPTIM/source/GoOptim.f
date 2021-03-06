      SUBROUTINE Go(qo,NATOMS,grad,energy,GTEST,STEST)
      USE KEY
      implicit NONE
      INTEGER NATOMS
      DOUBLE PRECISION qo(3*NATOMS), grad(3*NATOMS)
      DOUBLE PRECISION ENERGY

!      DOUBLE PRECISION  Rb(NATOMS), bK(NATOMS), ANTC(NATOMS), 
!     Q Tk(NATOMS), PK(NATOMS), GAMS1(NATOMS), GAMS3(NATOMS), 
!     Q GAMC1(NATOMS), GAMC3(NATOMS), Sigma(NATOMS*10), 
!     Q EpsC(NATOMS*10),  NNCsigma(NATOMS*NATOMS),NCsigma(NATOMS*NATOMS)
!      INTEGER  Ib1(NATOMS), Ib2(NATOMS), IT(NATOMS), JT(NATOMS), 
!     Q KT(NATOMS),IP(NATOMS), JP(NATOMS), KP(NATOMS), 
!     Q LP(NATOMS), IC(NATOMS*10), JC(NATOMS*10),INC(NATOMS*NATOMS), 
!     Q JNC(NATOMS*NATOMS), NBA, NTA, NPA, NC, NNC
      LOGICAL :: CALLED=.FALSE.
      LOGICAL GTEST, STEST
        integer NgoMAX
        parameter(NgoMAX=500)
      DOUBLE PRECISION  Rb(NgoMAX), bK(NgoMAX), ANTC(NgoMAX),
     Q Tk(NgoMAX), PK(NgoMAX), GAMS1(NgoMAX), GAMS3(NgoMAX),
     Q GAMC1(NgoMAX), GAMC3(NgoMAX), Sigma(NgoMAX*10),
     Q EpsC(NgoMAX*10),  NNCsigma(NgoMAX*NgoMAX),NCsigma(NgoMAX*NgoMAX)
      INTEGER  Ib1(NgoMAX), Ib2(NgoMAX), IT(NgoMAX), JT(NgoMAX),
     Q KT(NgoMAX),IP(NgoMAX), JP(NgoMAX), KP(NgoMAX),
     Q LP(NgoMAX), IC(NgoMAX*10), JC(NgoMAX*10),INC(NgoMAX*NgoMAX),
     Q JNC(NgoMAX*NgoMAX), NBA, NTA, NPA, NC, NNC

        common /double precision/ Rb, bK, ANTC, Tk,PK, GAMS1, GAMS3, GAMC1, GAMC3,
     Q sigma, epsC, NNCsigma, NCsigma
        common /int/ Ib1, Ib2, IT, JT, KT, IP,
     Q JP, KP, LP,IC, JC, INC, JNC, NBA, NTA, NPA, NC, NNC


        if(NATOMS.gt. NgoMAx)then
        write(*,*) 'TOO MANY ATOMS FOR GO, change NgoMAX'
        STOP
        endif

!  DIMENSION(:):: 
!      SAVE  NATOMS,Ib1, Ib2,Rb, bK, IT, JT, KT, ANTC, Tk, IP, JP, KP, LP, PK,
!     Q GAMS1, GAMS3, GAMC1, GAMC3,IC, JC, Sigma, EpsC, INC, JNC, NNCsigma,NBA, NTA, NPA, NC, NNC
!  put in a line that reads in the parameters, if this is the first time it has been called

       if(.NOT.CALLED)then
!        CALLED=.TRUE.
!        endIF
       call Goinit(NATOMS,Ib1, Ib2,Rb, bK, IT, JT, KT, ANTC, Tk, IP, 
     Q JP, KP, LP, PK, GAMS1, GAMS3, GAMC1, GAMC3,IC, JC, Sigma, 
     Q EpsC, INC, JNC, NNCsigma, NCsigma,NBA, NTA, NPA, NC, NNC)

        CALLED=.TRUE.
        endIF
! call the energy routine

      call calc_energy_Go(qo,natoms, GRAD, energy, Ib1, Ib2,
     Q Rb, bK, IT, JT, KT, ANTC, Tk, IP, JP, KP, LP, PK,
     Q GAMS1, GAMS3, GAMC1, GAMC3,IC, JC, Sigma, EpsC, INC, 
     Q JNC, NNCsigma,NCsigma,NBA, NTA, NPA, NC, NNC)


      IF (STEST) THEN
         PRINT '(A)','ERROR - second derivatives not available for this potential'
         STOP
      ENDIF
      return
      end





!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* Goinit() reads the atom positions from file.  If 1 is selected for  *
!* startt then the velocities are assigned, otherwise, they are read   *
!* by selecting 2, or generated by selecting 3                         *
!***********************************************************************

      subroutine Goinit(NATOMS,Ib1, Ib2,Rb, bK, IT, JT, KT, ANTC, Tk,
     Q  IP, JP, KP, LP, PK,GAMS1, GAMS3, GAMC1, GAMC3,IC, JC, Sigma, 
     Q EpsC, INC, JNC, NNCsigma, NCsigma,NBA, NTA, NPA, NC, NNC)
      USE KEY
      implicit NONE

        integer i,j,MaxCon,NNCmax,NATOMS,storage, dummy,  ANr, IB11,
     Q IB12, Ib22, Ib21,IT1, JT1, KT1, IT2, JT2, KT2, IP1, JP1,
     Q KP1, LP1, IP2, JP2, KP2,
     Q LP2, nBA1, nTA1, nPA1, nBA2, nTA2, nPA2,  ind1, ind2, ANt,
     Q  MDT1, MDT2, cl1, cl2

      DOUBLE PRECISION  Rb(NATOMS), bK(NATOMS), ANTC(NATOMS), 
     Q Tk(NATOMS), PK(NATOMS), GAMS1(NATOMS), GAMS3(NATOMS),
     Q GAMC1(NATOMS), GAMC3(NATOMS), Sigma(NATOMS*10), EpsC(NATOMS*10),  
     Q NNCsigma(NATOMS*NATOMS),NCsigma(NATOMS*NATOMS)
      INTEGER  Ib1(NATOMS), Ib2(NATOMS), IT(NATOMS), JT(NATOMS), 
     Q KT(NATOMS),IP(NATOMS), JP(NATOMS), KP(NATOMS),
     Q LP(NATOMS), IC(NATOMS*10), JC(NATOMS*10),INC(NATOMS*NATOMS), 
     Q JNC(NATOMS*NATOMS), NBA, NTA, NPA, NC, NNC

       DOUBLE PRECISION  pinitmax, TK1, TK2, PK1, PK2, APTtemp, msT,
     Q SigmaT1, SigmaT2, epstemp
!      integer i,j,MaxCon,NNCmax,NATOMS,storage, dummy,  ANr, IB11, 
!     Q IB12, Ib22, Ib21,IT1, JT1, KT1, IT2, JT2, KT2, IP1, JP1, 
!     Q KP1, LP1, IP2, JP2, KP2,
!     Q LP2, nBA1, nTA1, nPA1, nBA2, nTA2, nPA2,  ind1, ind2, ANt, 
!     Q  MDT1, MDT2, cl1, cl2
        character(LEN=20) FMTB, FMTT, FMTP, CA, RP

       DOUBLE PRECISION NNCeps
       dimension NNCeps(NATOMS*NATOMS)
      DOUBLE PRECISION dx,dy,dz
       double precision PI
      pi = 3.14159265358979323846264338327950288419716939937510

        NNCmax = NATOMS*NATOMS
        MaxCon=NATOMS*10
! old formatting
        FMTB="(3I5,2F8.3)"
        FMTT="(4I5,2F8.3)"
        FMTP="(5I5,2F8.3)"
        CA="(3I5,F10.3, F9.6)"
        RP="(I5,2I5, 2F8.3)"

! new formatting
!        FMTB="(3I5,2F8.3)"
!        FMTT="(4I5,2F8.3)"
!        FMTP="(5I5,2F8.3)"
!        CA="(3I5,F10.3,F9.6)"
!        RP="(I8,2I5, 2F10.3)"


! These lines read in the parameters.
        open(30, file='GO.INP', status='old', access='sequential')

          read(30,*) nBA

        do i=1, nBA
          read(30,*) j, Ib1(i), Ib2(i),Rb(i), bK(i)
        end do

          read(30,*) nTA
        do i=1, nTA
          read(30,*) j, IT(i), JT(i), KT(i), ANTC(i), Tk(i)
        enddo

          read(30,*) nPA

! this reads in the dihedral angles and calculates the cosines and sines
! in order to make the force and energy calculations easier, later.
        do i=1, npA
           read(30,*) j, IP(i), JP(i), KP(i), LP(i), APTtemp, PK(i)

!1010   if(APTtemp .gt. PI)then
!       APTtemp = APTtemp -2*Pi
!       goto 1010
!        else
!1010    if(APTtemp .lt. 0.0)then
!        APTtemp = APTtemp+2*Pi
!        goto 1010
!        endif
         
            GAMS1(i)= PK(i)*Sin(APTtemp)
            GAMC1(i)= PK(i)*Cos(APTtemp)

!1020    if(3*APTtemp .gt. PI)then
!        APTtemp = APTtemp -2.0/3.0*Pi
!        goto 1020
!        else
!1020    if(3*APTtemp .lt. 0.0)then
!        APTtemp = APTtemp +2.0/3.0*Pi
!        goto 1020

!        endif

            GAMS3(i)= PK(i)*Sin(3.0*APTtemp)/2
            GAMC3(i)= PK(i)*Cos(3.0*APTtemp)/2

        END DO


        read(30,*) NC

          if(NC .gt. MaxCon)then
             write(*,*) 'too many contacts'
             STOP
          endif

        do i=1, NC

          read(30, *) ind1, IC(i), JC(i), Sigma(i), EpsC(i)
        end do

 
! read non-native interactions
        read(30,*) NNC
        if(NNC .gt. NNCmax)then
        write(*,*) 'too many non contacts'
        STOP
        endif        
        do i=1, NNC
           read(30,*) ind1, INC(i), JNC(i), NCsigma(i), NNCeps(i)
! this simplifies calculations later
           NNCsigma(i) = 12*NNCEps(i)*NCsigma(i)**6
        end do


!        read(30,*) AN
       close(30)
       end

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^end of Goinit^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


C
C Calculate the Forces and energies
C
      subroutine calc_energy_Go(qo,natoms,GRAD, energy,Ib1, Ib2,
     Q Rb, bK, IT, JT, KT, ANTC, Tk, IP, JP, KP, LP, PK,
     Q GAMS1, GAMS3, GAMC1, GAMC3,IC, JC, Sigma, EpsC, INC, JNC, 
     Q NNCsigma,NCsigma,NBA, NTA, NPA, NC, NNC)

      INTEGER I, J, NATOMS,NBA, NTA, NPA, NC, NNC

      DOUBLE PRECISION qo(3*NATOMS), grad(3*NATOMS), ENERGY
      DOUBLE PRECISION x(NATOMS), y(NATOMS), z(NATOMS)

        DOUBLE PRECISION Rb(NBA), bK(NBA), ANTC(NTA), Tk(NTA), PK(NPA), 
     Q GAMS1(NPA), GAMS3(NPA), GAMC1(NPA), GAMC3(NPA), Sigma(NC), 
     Q EpsC(NC),  NNCsigma(NNC),NCsigma(NNC)
        INTEGER Ib1(NBA), Ib2(NBA), IT(NTA), JT(NTA), KT(NTA),IP(NPA), 
     Q JP(NPA), KP(NPA), LP(NPA), IC(NC), JC(NC), INC(NNC), JNC(NNC)
      DOUBLE PRECISION dx,dy,dz

      do i = 1, natoms
         j = (i-1)*3
         x(i) = qo(j+1)
         y(i) = qo(j+2)
         z(i) = qo(j+3)
         grad(j+1) = 0.0
        grad(j+2) = 0.0
        grad(j+3) = 0.0
      enddo

      energy = 0.0

      call Gobonds(x,y,z,grad, energy, natoms,Ib1, Ib2,Rb, bK,NBA)
      call Goangl(x,y,z,grad, energy, natoms,IT,JT,KT,ANTC,Tk,NTA)
        call GoDihedral(x,y,z,grad, energy, natoms,IP,JP,KP,LP,PK,
     Q GAMS1, GAMS3, GAMC1, GAMC3,NPA)
        call GoContacts(x,y,z,grad, energy, natoms, IC, JC, 
     Q Sigma, EpsC, NC)
        call GoNonContacts(x,y,z,grad, energy, natoms, INC, 
     Q JNC, NCsigma,NNCsigma,NNC)

      end


!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* GoBonds  computes the hookean force and energy between chosen atoms *
!***********************************************************************

      subroutine GoBonds(x,y,z,grad,energy, natoms,Ib1, Ib2,Rb, bK,NBA)
      USE KEY
      implicit NONE
      integer I2, J2,  outE,I, N, J, NATOMS, NBA
      DOUBLE PRECISION x(NATOMS), y(NATOMS), z(NATOMS), grad(3*NATOMS),
     Q energy
      DOUBLE PRECISION r2, f, r1
      DOUBLE PRECISION dx,dy,dz

        DOUBLE PRECISION Rb(NBA), bK(NBA)
        INTEGER Ib1(NBA), Ib2(NBA)


        do 1 i=1, nBA
           I2 = Ib1(i)
           J2 = Ib2(i)

        dx = X(I2) - X(J2)
        dy = Y(I2) - Y(J2)
        dz = Z(I2) - Z(J2)

          r2 = dx**2 + dy**2 + dz**2
          r1 = sqrt(r2)

! energy calculation
             Energy = Energy + bk(i)*(r1-Rb(i))**2/2.0

! End energy calculation

! f_over_r is the force over the magnitude of r so there is no need to resolve
! the dx, dy and dz into unit vectors

! the index i indicates the interaction between particle i and i+1

             f = -bk(i)*(r1-Rb(i))/r1
!            f = Rb(i)*bK(i)/r1 - bK(i)
        !write(*,*) i, f
            ! now add the force
              grad(I2*3-2) = grad(I2*3-2) - f * dx
              grad(I2*3-1) = grad(I2*3-1) - f * dy
              grad(I2*3)   = grad(I2*3)   - f * dz
! the negative sign is due to the computation of dx, dy and dz
              grad(J2*3-2) = grad(J2*3-2) + f * dx
              grad(J2*3-1) = grad(J2*3-1) + f * dy
              grad(J2*3)   = grad(J2*3)   + f * dz

1         continue
      !STOP
      END

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^END OF GoBONDS^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* GoANGL  computes the Force due to the bond angles                   *
!* This code is taken from AMBER, and modified                         *
!***********************************************************************

      SUBROUTINE GoANGL(x,y,z,grad, energy, NATOMS,IT, JT, KT, 
     Q ANTC, Tk,NTA)
      USE KEY
      implicit NONE
      integer NATOMS
      DOUBLE PRECISION x(NATOMS), y(NATOMS), z(NATOMS), grad(3*NATOMS),
     Q energy
      integer I, N, J, NTA
! "XX, IX," was right after "X," but has been taken out for the time being
!      IMPLICIT _REAL_ (A-H,O-Z)
      LOGICAL SKIP,NOCRST
C
C     ----- ROUTINE TO GET THE ANGLE ENERGIES AND FORCES FOR THE
C           POTENTIAL OF THE TYPE CT*(T-T0)**2
C

      DOUBLE PRECISION CST,EAW,RIJ,RKJ,RIK,DFW,ANT,XIJ,YIJ,
     + ZIJ,XKJ,YKJ,
     + ZKJ, DF
      dimension  XIJ(NTA),YIJ(NTA),ZIJ(NTA),XKJ(NTA),YKJ(NTA),
     + ZKJ(NTA),CST(NTA),EAW(NTA),RIJ(NTA),RKJ(NTA),RIK(NTA),
     + DFW(NTA),ANT(NTA)
      DOUBLE PRECISION CT0, CT1, CT2, RIJ0, RKJ0, RIK0, ANT0, DA, ST, 
     + CIK, CII, CKK, DT1, DT2, DT3, DT4, DT5, DT6, DT7, DT8, DT9, pt999
     Q , ebal,STH

! These are all replaced with global arrays that don't need to declared
! I think AMBER uses this method since it has such a large memory
! If I need to, I will use this method later.
!      DIMENSION IT(*),JT(*),KT(*),ICT(*),X(*),F(*)

! ",XX(*),IX(*)" was removed from Dimension above
        DOUBLE PRECISION ANTC(NTA), Tk(NTA)
        INTEGER JN, IT(NTA), JT(NTA), KT(NTA)
        INTEGER I3, J3, K3

      data pt999 /1.0d0/
      ebal= 0.0d0


!        X(1) = 1.0 
!        Y(2) = 0.0
!        Z(2) = 0.0

!        X(2) = 0.0
!        Y(2) = 0.0
!        Z(2) = 0.0
 
!        DO JN=3, NTA

 !       X(JN) = cos(3.14159*2*(JN-3)/200.)
!        Y(JN) = sin(3.14159*2*(JN-3)/200.)
!        Z(JN) = 0.0


!        enddo

          DO JN = 1, nTA
            I3 = IT(JN)
            J3 = JT(JN)
            K3 = KT(JN)

!            I3 = 1
!            J3 = 2
!            K3 = KT(JN)



C
C           ----- CALCULATION OF THE angle -----
C
            XIJ(JN) = X(I3)-X(J3)
            YIJ(JN) = Y(I3)-Y(J3)
            ZIJ(JN) = Z(I3)-Z(J3)
            XKJ(JN) = X(K3)-X(J3)
            YKJ(JN) = Y(K3)-Y(J3)
            ZKJ(JN) = Z(K3)-Z(J3)
          END DO
C
          DO JN = 1,nTA
            RIJ0 = XIJ(JN)*XIJ(JN)+YIJ(JN)*YIJ(JN)+ZIJ(JN)*ZIJ(JN)
            RKJ0 = XKJ(JN)*XKJ(JN)+YKJ(JN)*YKJ(JN)+ZKJ(JN)*ZKJ(JN)
            RIK0 = SQRT(RIJ0*RKJ0)
            CT0 = (XIJ(JN)*XKJ(JN)+YIJ(JN)*YKJ(JN)+ZIJ(JN)*ZKJ(JN))/RIK0
            CT1 = MAX(-pt999,CT0)
            CT2 = MIN(pt999,CT1)
            CST(JN) = CT2
            ANT(JN) = ACOS(CT2)
            RIJ(JN) = RIJ0
            RKJ(JN) = RKJ0
            RIK(JN) = RIK0
          END DO

! end of insertion


C
C         ----- CALCULATION OF THE ENERGY AND DER -----
C

          DO JN = 1,nTA
            ANT0 = ANT(JN)
            DA = ANT0 - ANTC(JN)
            DF = TK(JN)*DA


! These lines were in AMBER, but I don't need them... yet...
!            if(idecomp.eq.1 .or. idecomp.eq.2) then
!             II = (IT(JN) + 3)/3
!             JJ = (JT(JN) + 3)/3
!             KK = (KT(JN) + 3)/3
!              call decangle(XX,IX,II,JJ,KK,EAW(JN))
!            endif
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!            DFW(JN) = -(DF+DF)/SIN(ANT0)
            DFW(JN) = -(DF)/SIN(ANT0)

          END DO
C
C         ----- CALCULATION OF THE FORCE -----
C
          DO JN = 1,nTA
            I3 = IT(JN)
            J3 = JT(JN)
            K3 = KT(JN)
C
            ST = DFW(JN)
            STH = ST*CST(JN)
            CIK = ST/RIK(JN)
            CII = STH/RIJ(JN)
            CKK = STH/RKJ(JN)
            DT1 = CIK*XKJ(JN)-CII*XIJ(JN)
            DT2 = CIK*YKJ(JN)-CII*YIJ(JN)
            DT3 = CIK*ZKJ(JN)-CII*ZIJ(JN)
            DT7 = CIK*XIJ(JN)-CKK*XKJ(JN)
            DT8 = CIK*YIJ(JN)-CKK*YKJ(JN)
            DT9 = CIK*ZIJ(JN)-CKK*ZKJ(JN)
            DT4 = -DT1-DT7
            DT5 = -DT2-DT8
            DT6 = -DT3-DT9
C

            grad(I3*3-2) = grad(I3*3-2)+ DT1
            grad(I3*3-1) = grad(I3*3-1)+ DT2
            grad(I3*3)   = grad(I3*3)  + DT3
            grad(J3*3-2) = grad(J3*3-2)+ DT4
            grad(J3*3-1) = grad(J3*3-1)+ DT5
            grad(J3*3)   = grad(J3*3)  + DT6
            grad(K3*3-2) = grad(K3*3-2)+ DT7
            grad(K3*3-1) = grad(K3*3-1)+ DT8
            grad(K3*3)   = grad(K3*3)  + DT9

!         write(100,*) DT1,DT2,DT3,DT4,DT5,DT6,DT7,DT8,DT9
          END DO
!         STOP
! Energy Calculations


          do i=1, nTA
             energy = energy + TK(i)*(ANTC(i)- ANT(i))**2/2.0
          end do

       RETURN
       END

!^^^^^^^^^^^^^^^^^^^^^^^^End of GoANGL^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* Godihedral computes the dihedral angles and the forces due to them *
!**********************************************************************

      SUBROUTINE Godihedral(x,y,z,grad, energy, NATOMS,IP,JP,KP,LP,PK,
     Q GAMS1, GAMS3, GAMC1, GAMC3,NPA)
      USE KEY
      implicit NONE
      integer I, N, J, NATOMS, NPA, JN
      DOUBLE PRECISION x(NATOMS),y(NATOMS),z(NATOMS),
     Q grad(3*NATOMS),energy


      DOUBLE PRECISION PK(NPA),GAMS1(NPA),GAMS3(NPA),
     Q GAMC1(NPA),GAMC3(NPA)
      INTEGER IP(NPA), JP(NPA), KP(NPA), LP(NPA) 

      double precision lfac
      integer I3, J3, K3, L3
      double precision  XIJ,YIJ,ZIJ,XKJ,YKJ,
     + ZKJ,XKL,YKL,ZKL,DX,DY,
     + DZ, GX,GY,GZ,CT,CPHI,
     + SPHI,Z1, Z2,FXI,FYI,FZI,
     + FXJ,FYJ,FZJ, FXK,FYK,FZK,
     + FXL,FYL,FZL,DF,Z10,Z20,Z12,Z11,Z22,ftem,CT0,CT1,AP0,AP1,
     + Dums,DFLIM, DF1, DF0, DR1, DR2,DR3,DR4,DR5,DR6,DRX,DRY,DRZ,
     +  DC1, DC2, DC3, DC4, DC5, DC6,S

      DIMENSION XIJ(NPA),YIJ(NPA),ZIJ(NPA),XKJ(NPA),YKJ(NPA),
     + ZKJ(NPA),XKL(NPA),YKL(NPA),ZKL(NPA),DX(NPA),DY(NPA),
     + DZ(NPA), GX(NPA),GY(NPA),GZ(NPA),CT(NPA),CPHI(NPA),
     + SPHI(NPA),Z1(NPA), Z2(NPA),FXI(NPA),FYI(NPA),FZI(NPA),
     + FXJ(NPA),FYJ(NPA),FZJ(NPA), FXK(NPA),FYK(NPA),FZK(NPA),
     + FXL(NPA),FYL(NPA),FZL(NPA),DF(NPA)
C
      double precision  TM24,TM06,tenm3,zero,one,two,four,six,twelve

      DATA TM24,TM06,tenm3/1.0d-24,1.0d-06,1.0d-03/
      data zero,one,two,four,six,twelve/0.d0,1.d0,2.d0,4.d0,6.d0,12.d0/

      double precision pi,SINNP,COSNP,SINNP3,COSNP3
      pi = 3.14159265358979323846264338327950288419716939937510

!      pi = 3.141592653589793
C
C     ----- GRAND LOOP FOR THE DIHEDRAL STUFF -----
C
          DO JN = 1,nPA

            I3 = IP(JN)
            J3 = JP(JN)
            K3 = KP(JN)
            L3 = LP(JN)

C
C           ----- CALCULATION OF ij, kj, kl VECTORS -----
C
 

            XIJ(JN) = X(I3)-X(J3)
            YIJ(JN) = Y(I3)-Y(J3)
            ZIJ(JN) = Z(I3)-Z(J3)
            XKJ(JN) = X(K3)-X(J3)
            YKJ(JN) = Y(K3)-Y(J3)
            ZKJ(JN) = Z(K3)-Z(J3)
            XKL(JN) = X(K3)-X(L3)
            YKL(JN) = Y(K3)-Y(L3)
            ZKL(JN) = Z(K3)-Z(L3)                                  
          END DO
C
C         ----- GET THE NORMAL VECTOR -----
C
          DO JN = 1,nPA
            DX(JN) = YIJ(JN)*ZKJ(JN)-ZIJ(JN)*YKJ(JN)
            DY(JN) = ZIJ(JN)*XKJ(JN)-XIJ(JN)*ZKJ(JN)
            DZ(JN) = XIJ(JN)*YKJ(JN)-YIJ(JN)*XKJ(JN)
            GX(JN) = ZKJ(JN)*YKL(JN)-YKJ(JN)*ZKL(JN)
            GY(JN) = XKJ(JN)*ZKL(JN)-ZKJ(JN)*XKL(JN)
            GZ(JN) = YKJ(JN)*XKL(JN)-XKJ(JN)*YKL(JN)
          END DO
C
          DO JN = 1,nPA
            FXI(JN) = SQRT(DX(JN)*DX(JN)
     Q                    +DY(JN)*DY(JN)
     Q                    +DZ(JN)*DZ(JN)+TM24)
            FYI(JN) = SQRT(GX(JN)*GX(JN)
     Q                    +GY(JN)*GY(JN)
     Q                    +GZ(JN)*GZ(JN)+TM24)
            CT(JN) = DX(JN)*GX(JN)+DY(JN)*GY(JN)+DZ(JN)*GZ(JN)
          END DO
C
C         ----- BRANCH IF LINEAR DIHEDRAL -----
C                             
         DO JN = 1,nPA
!#ifdef CRAY_PVP
!            BIT = one/FXI(JN)
!            BIK = one/FYI(JN)
!            Z10 = CVMGT(zero,BIT,tenm3.GT.FXI(JN))
!            Z20 = CVMGT(zero,BIK,tenm3.GT.FYI(JN))
!#else
            z10 = one/FXI(jn)
            z20 = one/FYI(jn)
            if (tm24 .gt. FXI(jn)) z10 = zero
            if (tm24 .gt. FYI(jn)) z20 = zero
!#endif
            Z12 = Z10*Z20
            Z1(JN) = Z10
            Z2(JN) = Z20
!#ifdef CRAY_PVP
!            FTEM = CVMGZ(zero,one,Z12)
!#else
            ftem = zero
            if (z12 .ne. zero) ftem = one
!#endif
            FZI(JN) = FTEM
            CT0 = MIN(one,CT(JN)*Z12)
            CT1 = MAX(-one,CT0)
            S = XKJ(JN)*(DZ(JN)*GY(JN)-DY(JN)*GZ(JN))+
     Q          YKJ(JN)*(DX(JN)*GZ(JN)-DZ(JN)*GX(JN))+
     Q          ZKJ(JN)*(DY(JN)*GX(JN)-DX(JN)*GY(JN))
            AP0 = ACOS(CT1)
            AP1 = PI-SIGN(AP0,S)
            CT(JN) = AP1
!1050    if(AP1 .gt. PI)then
!        AP1 = AP1-2*Pi
!        goto 1050
!        else
!1050       if(AP1 .lt. 0.0)then
!        AP1 = AP1+2*Pi
!        goto 1050
!        endif

            CT(JN) = AP1
            CPHI(JN) = COS(AP1)
            SPHI(JN) = SIN(AP1)
         END DO
C
C         ----- CALCULATE THE ENERGY AND THE DERIVATIVES WITH RESPECT TO
C               COSPHI -----
C
        DO JN = 1,nPA
            CT0 = CT(JN)
!1030       if(CT0 .gt. PI)then
!             CT0 = CT0-2*Pi
!             goto 1030
!           else
!1030          if(CT0 .lt. 0.0)then
!        CT0 = CT0+2*Pi
!        goto 1030
!        endif

            COSNP = COS(CT0)
            SINNP = SIN(CT0)
!        write(100,*) JN, SPHI(JN),SINNP
!1040    if(3*CT0 .gt. PI)then
!        CT0 = CT0 -2.0/3.0*Pi
!        goto 1040
!        else
!1040       if(3*CT0 .lt. 0.0)then
!        CT0 = CT0 +2.0/3.0*Pi
!        goto 1040

!        endif


            COSNP3 = cos(CT0*3.0)
            SINNP3 = sin(CT0*3.0)

!DEBUG LINES
!             if(JN .le. 10)then
!               write(*,*) COSNP, GAMC11(JN), COSNP3, 2*GAMC31(JN)
!               write(*,*) SINNP, GAMS11(JN), SINNP3, 2*GAMS31(JN)

!            end if



!later            EPW(JN) = (PK(MC)+COSNP*GAMC(MC)+SINNP*GAMS(MC))*FZI(JN)
!            if(idecomp.eq.1 .or. idecomp.eq.2) then
!              II = (IP(JN+IST) + 3)/3
!              JJ = (JP(JN+IST) + 3)/3
!              KK = (IABS(KP(JN+IST)) + 3)/3
!              LL = (IABS(LP(JN+IST)) + 3)/3
!              call decphi(xx,ix,II,JJ,KK,LL,EPW(JN))
!            endif

! Here is the energy part

            Energy =  Energy + (3.0/2.0*PK(JN)-GAMC1(JN)*COSNP - 
     Q GAMS1(JN)*SINNP - GAMC3(JN)*COSNP3 - GAMS3(JN)*SINNP3)*FZI(JN)
!       if(FZI(JN) .eq. 0.0)then
!       write(77,*) JN, FZI(JN)
!       endif
! End of energy part(at least until the bottom of this routine

        DF0 = (GAMS1(JN)*COSNP - GAMC1(JN)*SINNP + 3*GAMC3(JN)*COSNP3 - 3*GAMC3(JN)*SINNP3)

            DF0 = -((GAMC1(JN)*SINNP-GAMS1(JN)*COSNP)
     Q + 3*(GAMC3(JN)*SINNP3-GAMS3(JN)*COSNP3))

            DUMS = SPHI(JN)+SIGN(TM24,SPHI(JN))
!           write(89,*) JN, SPHI(JN)

!            DFLIM = GAMC(JN)*(PN(MC)-GMUL(INC)+GMUL(INC)*CPHI(JN))
! DFLIM was as is written above, but if SPhi is small ~ 0, then CPHI
! ~ 1, which means that the terms of Gmul(Gmul is zero for odd powered dihedrals) will almost perfectly cancel.
! and all you will have left is PN, which in this case is the 1+3=4

            DFLIM = GAMC1(JN) + 3*GAMC3(JN)

!#ifdef CRAY_PVP
!            DF1 = CVMGT(DFLIM,DF0/DUMS,TM06.GT.ABS(DUMS))
!#else
            df1 = df0/dums
            if(tm24.gt.abs(dums))then
            df1 = dflim
            endif

!#endif
            DF(JN) = DF1*FZI(JN)
    
!         write(8881,"(I4,5F12.8)") JN, DF(JN), SPHI(JN), CPHI(JN), GAMC1(JN), GAMS1(JN)
          END DO
C                                     
C         ----- NOW DO TORSIONAL FIRST DERIVATIVES -----
C
         DO JN = 1,nPA
C
C           ----- NOW, SET UP ARRAY DC = FIRST DER. OF COSPHI W/RESPECT
C                 TO THE CARTESIAN DIFFERENCES T -----
C
            Z11 = Z1(JN)*Z1(JN)
            Z12 = Z1(JN)*Z2(JN)
            Z22 = Z2(JN)*Z2(JN)
            DC1 = -GX(JN)*Z12-CPHI(JN)*DX(JN)*Z11
            DC2 = -GY(JN)*Z12-CPHI(JN)*DY(JN)*Z11
            DC3 = -GZ(JN)*Z12-CPHI(JN)*DZ(JN)*Z11
            DC4 =  DX(JN)*Z12+CPHI(JN)*GX(JN)*Z22
            DC5 =  DY(JN)*Z12+CPHI(JN)*GY(JN)*Z22
            DC6 =  DZ(JN)*Z12+CPHI(JN)*GZ(JN)*Z22
C
C           ----- UPDATE THE FIRST DERIVATIVE ARRAY -----
C
            DR1 = DF(JN)*(DC3*YKJ(JN) - DC2*ZKJ(JN))
            DR2 = DF(JN)*(DC1*ZKJ(JN) - DC3*XKJ(JN))
            DR3 = DF(JN)*(DC2*XKJ(JN) - DC1*YKJ(JN))
            DR4 = DF(JN)*(DC6*YKJ(JN) - DC5*ZKJ(JN))
            DR5 = DF(JN)*(DC4*ZKJ(JN) - DC6*XKJ(JN))
            DR6 = DF(JN)*(DC5*XKJ(JN) - DC4*YKJ(JN))
            DRX = DF(JN)*(-DC2*ZIJ(JN) + DC3*YIJ(JN) +
     +               DC5*ZKL(JN) - DC6*YKL(JN))
            DRY = DF(JN)*( DC1*ZIJ(JN) - DC3*XIJ(JN) -
     +               DC4*ZKL(JN) + DC6*XKL(JN))
            DRZ = DF(JN)*(-DC1*YIJ(JN) + DC2*XIJ(JN) +
     +               DC4*YKL(JN) - DC5*XKL(JN))
 
            I3 = IP(JN)
            J3 = JP(JN)
            K3 = KP(JN)
            L3 = LP(JN)


            grad(I3*3-2) =  grad(I3*3-2) +  DR1
            grad(I3*3-1) =  grad(I3*3-1) +  DR2
            grad(I3*3)   =  grad(I3*3)   +  DR3
            grad(J3*3-2) =  grad(J3*3-2) +  DRX -  DR1
            grad(J3*3-1) =  grad(J3*3-1) +  DRY -  DR2
            grad(J3*3)   =  grad(J3*3)   +  DRZ -  DR3
            grad(K3*3-2) =  grad(K3*3-2) -  DRX -  DR4
            grad(K3*3-1) =  grad(K3*3-1) -  DRY -  DR5
            grad(K3*3)   =  grad(K3*3)   -  DRZ -  DR6
            grad(L3*3-2) =  grad(L3*3-2) +  DR4
            grad(L3*3-1) =  grad(L3*3-1) +  DR5
            grad(L3*3)   =  grad(L3*3)   +  DR6

          END DO

          END


!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^END of GoDihedral^^^^^^^^^^^^^^^^^^^^^^^^^^^


!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* GoCONTACTS: computes the force on all atoms due to contacts via a   *
!* 10-12 potential                                                     *
!***********************************************************************

      subroutine Gocontacts(x,y,z,grad,energy,
     Q NATOMS,IC,JC,Sigma,EpsC,NC)
      USE KEY
      implicit NONE
      integer I, N, J,NATOMS,NC

      DOUBLE PRECISION x(NATOMS), y(NATOMS), z(NATOMS) 
     Q , grad(3*NATOMS), energy
      DOUBLE PRECISION dx,dy,dz

      integer C1, C2, ConfID, Q, SC1, SC2, Cf1, cf2
      DOUBLE PRECISION  r2, rm2, rm10, f_over_r, dsig, deps, 
     Q s1, s2, ep1, ep2, r1, rc,r, summm

        DOUBLE PRECISION Sigma(NC), EpsC(NC)
        INTEGER IC(NC), JC(NC)


!      Q = 0
!      Conts = 0

!      do i=1, NC
!         count(i) = 0
!      end do
!      write(89,*) NC
       do i=1, NC
       
           C1 = IC(i)
           C2 = JC(i)
!        write(*,*) C1, C2

        dx = X(C1) - X(C2)

         dy = Y(C1) - Y(C2)

        dz = Z(C1) - Z(C2)

          r2 = dx**2 + dy**2 + dz**2

              rm2 = 1.0/r2
              rm2 = rm2*sigma(i)
              rm10 = rm2**5


        energy = energy + epsC(i)*rm10*(5*rm2-6.0)
!         energy=energy+epsC(i)*rm10*(5*rm2-6)
        f_over_r = -epsc(i)*60.0*rm10*(rm2-1.0)/r2
!        write(99,*) f_over_r,C1,C2,i
        !write(*,*) f_over_r
!         f_over_r = -epsC(i)*rm10*(rm2-1.0)*60.0/r2

! now add the acceleration 
              grad(3*C1-2) = grad(3*C1-2) + f_over_r * dx
              grad(3*C1-1) = grad(3*C1-1) + f_over_r * dy
              grad(3*C1)   = grad(3*C1)   + f_over_r * dz

               grad(3*C2-2) =  grad(3*C2-2) - f_over_r * dx
              grad(3*C2-1) =  grad(3*C2-1) - f_over_r * dy
              grad(3*C2)   =  grad(3*C2)   - f_over_r * dz
!        write(89,*) C1,C2
!        write(90,*) dx,dy,dz
 !       write(100,*) f_over_r, epsC(i),sigma(i), r2,rm2,rm10
              enddo
        !STOP

      end

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^end of GoContacts^^^^^^^^^^^^^^^^^^^^^^^^^^^


!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!* GoNonContacts computes the forces due to non native contacts       *
!**********************************************************************

      subroutine Gononcontacts(x,y,z,grad, energy, 
     Q NATOMS, INC, JNC, NCsigma,NNCsigma,NNC)
      USE KEY
      implicit NONE
      integer I, N, J, AN, NATOMS

      DOUBLE PRECISION x(NATOMS), y(NATOMS), z(NATOMS), 
     Q grad(3*NATOMS), energy

      integer C1, C2
      DOUBLE PRECISION  r2, rm2, rm14, f_over_r 

        integer NNC 

        DOUBLE PRECISION NNCsigma(NNC),NCsigma(NNC)
        INTEGER INC(NNC), JNC(NNC)
      DOUBLE PRECISION dx,dy,dz



!      write(*,*) Npairnum
        do i=1, NNC
           
           C1 = INC(i)
           C2 = JNC(i)

        dx = X(C1) - X(C2)

         dy = Y(C1) - Y(C2)

        dz = Z(C1) - Z(C2)

          r2 = dx**2 + dy**2 + dz**2

             rm2 = 1/r2
             rm14 = rm2**7

! NNCsigma1 is actually 12*eps*sigma**12 (look at read.f and init.f)

!NCsigma(i), NNCeps(i
                energy = energy  + NCsigma(i)**6/r2**6
!              energy = energy + NNCSigma(i)*rm14*r2/12.0
                f_over_r = - 12.0*NCsigma(i)**6/r2**7


! f_over_r is the force over the magnitude of r so there is no need to resolve
! the dx, dy and dz into unit vectors
!              f_over_r = -NNCSigma(i)*rm14

! now add the acceleration 
              grad(C1*3-2) = grad(C1*3-2) + f_over_r * dx
              grad(C1*3-1) = grad(C1*3-1) + f_over_r * dy
              grad(C1*3)   = grad(C1*3)   + f_over_r * dz

               grad(C2*3-2) =  grad(C2*3-2) - f_over_r * dx
              grad(C2*3-1) =  grad(C2*3-1) - f_over_r * dy
              grad(C2*3)   =  grad(C2*3)   - f_over_r * dz

           end do


      END

!^^^^^^^^^^^^^^^^^^^^^^^^^^^End of GoNonContacts^^^^^^^^^^^^^^^^^^^^^^^^^


