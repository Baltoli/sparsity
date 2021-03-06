! dc550

SUBROUTINE INISELECTMOVE()
  
  USE COMMONS
  IMPLICIT NONE
  
  INTEGER :: J1
 
  ALLOCATE(SELTRANSSTEP(SELMOVNO))
  ALLOCATE(SELROTSCALE(SELMOVNO))
  ALLOCATE(SELMOVFREQ(SELMOVNO))
  ALLOCATE(SELMOVPROB(SELMOVNO))
  ALLOCATE(SELBEGIN(SELMOVNO))
  ALLOCATE(SELEND(SELMOVNO))
  ALLOCATE(SELSIZE(SELMOVNO))

  OPEN (UNIT=28,FILE='movablegroups',STATUS='OLD')
  
  DO J1 = 1, SELMOVNO
     
     READ (28, *) SELTRANSSTEP(J1), SELROTSCALE(J1), SELMOVFREQ(J1), SELMOVPROB(J1), SELBEGIN(J1), SELEND(J1), SELSIZE(J1)
     
  ENDDO

  CLOSE(28)

END SUBROUTINE INISELECTMOVE


SUBROUTINE TAKESTEPSELECTMOVE(JP)
  
  USE COMMONS
  IMPLICIT NONE

  INTEGER :: J1, J2, JP, NOGROUPSPERTYPE, ATOMNO
  DOUBLE PRECISION :: ROTSIZE, TRANSSIZE, DPRAND


  DO J1 = 1, SELMOVNO

     NOGROUPSPERTYPE = (SELEND(J1) - SELBEGIN(J1) + 1) / SELSIZE(J1)
     ATOMNO = SELBEGIN(J1)

     DO J2 = 1, NOGROUPSPERTYPE
        
        ROTSIZE = SELROTSCALE(J1)
        TRANSSIZE = SELTRANSSTEP(J1)

        IF ( DPRAND() < SELMOVPROB(J1) ) THEN
           CALL SELECTMOVETRANS(ATOMNO,SELSIZE(J1),TRANSSIZE, JP)
        ENDIF
        IF ( DPRAND() < SELMOVPROB(J1) ) THEN
           CALL SELECTMOVEROT(ATOMNO,SELSIZE(J1),ROTSIZE, JP)
        ENDIF

        ATOMNO = ATOMNO + SELSIZE(J1)

     ENDDO

  ENDDO

END SUBROUTINE TAKESTEPSELECTMOVE


SUBROUTINE SELECTMOVETRANS(ATOMNO,MOLSIZE,TRANSSIZE, JP)

  USE COMMONS
  IMPLICIT NONE

  INTEGER :: J1, J2, JP, ATOMNO, MOLSIZE
  DOUBLE PRECISION :: TRANSSIZE, XMOVE, YMOVE, ZMOVE, DPRAND

  XMOVE = (DPRAND()-0.5D0)*2.0D0 * TRANSSIZE
  YMOVE = (DPRAND()-0.5D0)*2.0D0 * TRANSSIZE
  ZMOVE = (DPRAND()-0.5D0)*2.0D0 * TRANSSIZE

  DO J1 = ATOMNO, ATOMNO+MOLSIZE-1
     
     COORDS(3*J1-2,JP) = COORDS(3*J1-2,JP) + XMOVE
     COORDS(3*J1-1,JP) = COORDS(3*J1-1,JP) + YMOVE
     COORDS(3*J1  ,JP) = COORDS(3*J1  ,JP) + ZMOVE

  ENDDO

END SUBROUTINE SELECTMOVETRANS


SUBROUTINE SELECTMOVEROT(ATOMNO,MOLSIZE,ROTSIZE, JP)

  USE COMMONS
  IMPLICIT NONE

  INTEGER :: J1, J2, JP, ATOMNO, MOLSIZE
  DOUBLE PRECISION :: ROTSIZE, AMPLITUDE
  DOUBLE PRECISION :: AXIS(3), DUMMYCOORDS(3), LENGTH, DPRAND
  DOUBLE PRECISION :: COM(3), ROTMAT(3,3), DUMMYMAT(3,3)


  AXIS(1) = DPRAND()-0.5D0
  AXIS(2) = DPRAND()-0.5D0
  AXIS(3) = DPRAND()-0.5D0
  LENGTH = DSQRT(AXIS(1)**2 + AXIS(2)**2 + AXIS(3)**2)

  IF (LENGTH < 1.0D-3) THEN
     AXIS(1) = 1.0D0
     AXIS(2) = 0.0D0
     AXIS(3) = 0.0D0
     AMPLITUDE = 0.0D0
  ELSE
     AMPLITUDE = (DPRAND()-0.5D0)*2.0D0 * ROTSIZE
     AXIS(1) = AXIS(1) /LENGTH * AMPLITUDE
     AXIS(2) = AXIS(2) /LENGTH * AMPLITUDE
     AXIS(3) = AXIS(3) /LENGTH * AMPLITUDE
  ENDIF

  COM(:) = 0.0D0
  DO J1 = ATOMNO, ATOMNO+MOLSIZE-1

     COM(1) = COM(1) + COORDS(3*J1-2,JP)
     COM(2) = COM(2) + COORDS(3*J1-1,JP)
     COM(3) = COM(3) + COORDS(3*J1  ,JP)
     
  ENDDO
  COM = COM/MOLSIZE

  CALL RMDRVT(AXIS,ROTMAT,DUMMYMAT,DUMMYMAT,DUMMYMAT,.FALSE.)

  DO J1 = ATOMNO, ATOMNO+MOLSIZE-1

     DUMMYCOORDS(:) = COORDS(3*J1-2:3*J1,JP) - COM(:)
     COORDS(3*J1-2:3*J1,JP) = COM(:) + MATMUL(ROTMAT,DUMMYCOORDS)
     
  ENDDO

END SUBROUTINE SELECTMOVEROT
