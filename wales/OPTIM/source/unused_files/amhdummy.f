      SUBROUTINE WALESAMH_INITIAL()
      RETURN
      END

      SUBROUTINE WALESAMH_INTERFACE(COORD_MCP,GRAD_FOR_WALES,E_FOR_WALES)

      IMPLICIT NONE

      DOUBLE PRECISION GRAD_FOR_WALES(*),E_FOR_WALES
      DOUBLE PRECISION COORD_MCP(*)

      RETURN
      END

      SUBROUTINE AMHFINALIO(QMINP)
        DOUBLE PRECISION QMINP(*)
        RETURN
      END

!     MODULE AMHGLOBALS
!       INTEGER IRES(1) 
!       DOUBLE PRECISION X_MCP(1)
!       INTEGER WALES_NMRES
!       INTEGER NMRES
!     END MODULE AMHGLOBALS

