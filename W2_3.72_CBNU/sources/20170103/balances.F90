SUBROUTINE BALANCES

USE MAIN
USE GLOBAL;     USE NAMESC; USE GEOMC;  USE LOGICC; USE PREC;  USE SURFHE;  USE KINETIC; USE SHADEC; USE EDDY
  USE STRUCTURES; USE TRANS;  USE TVDC;   USE SELWC;  USE GDAYC; USE SCREENC; USE TDGAS;   USE RSTART
  USE MACROPHYTEC; USE POROSITYC; USE ZOOPLANKTONC
  IMPLICIT NONE
  EXTERNAL RESTART_OUTPUT
  REAL VOLINJW,VOLPRJW,VOLOUTJW,VOLWDJW,VOLEVJW,VOLDTJW,VOLTRBJW

!***********************************************************************************************************************************
!*                                                    TASK 2.6: BALANCES                                                          **
!***********************************************************************************************************************************

    QINT  = 0.0
    QOUTT = 0.0
    VOLSR = 0.0
    VOLTR = 0.0
    
    DO JW=1,NWB
    VOLINJW=0.0
    VOLPRJW=0.0
    VOLOUTJW=0.0
    VOLWDJW=0.0
    VOLEVJW=0.0
    VOLDTJW=0.0
    VOLTRBJW=0.0
    
      KT = KTWB(JW)
        IF (VOLUME_BALANCE(JW)) THEN
         DO JB=BS(JW),BE(JW)
          VOLSBR(JB) = VOLSBR(JB)+DLVOL(JB)
          VOLTBR(JB) = VOLEV(JB)+VOLPR(JB)+VOLTRB(JB)+VOLDT(JB)+VOLWD(JB)+VOLUH(JB)+VOLDH(JB)+VOLIN(JB)+VOLOUT(JB)
          VOLSR(JW)  = VOLSR(JW)+VOLSBR(JB)
          VOLTR(JW)  = VOLTR(JW)+VOLTBR(JB)
          QINT(JW)   = QINT(JW) +VOLIN(JB)+VOLTRB(JB)+VOLDT(JB)+VOLPR(JB)
          QOUTT(JW)  = QOUTT(JW)-VOLEV(JB)-VOLWD(JB) -VOLOUT(JB)
          IF (ABS(VOLSBR(JB)-VOLTBR(JB)) > VTOL .AND. VOLTBR(JB) > 100.0*VTOL) THEN
            IF (VOLUME_WARNING) THEN
              WRITE (WRN,'(A,F0.3,3(:/A,E15.8,A))') 'COMPUTATIONAL WARNING AT JULIAN DAY = ',JDAY,'SPATIAL CHANGE  =', VOLSBR(JB), &
                                                    ' M^3','TEMPORAL CHANGE =',VOLTBR(JB),' M^3','VOLUME ERROR    =',              &
                                                     VOLSBR(JB)-VOLTBR(JB),' M^3'
              WRITE(WRN,*)'LAYER CHANGE:',LAYERCHANGE(JW)
              WRITE(WRN,*)'SZ',SZ,'Z',Z,'H2KT',H2(KT,1:IMX),'H1KT',H1(KT,1:IMX),'WSE',ELWS,'Q',Q,'QC',QC,'T1',T1(KT,1:IMX),'T2',&
                           T2(KT,1:IMX),'SUKT',SU(KT,1:IMX),'UKT',U(KT,1:IMX),'QIN',QINSUM,'QTR',QTR,'QWD',QWD
              WARNING_OPEN   = .TRUE.
              VOLUME_WARNING = .FALSE.
            END IF
          END IF
          IF (VOLSR(JW) /= 0.0) DLVR(JW) = (VOLTR(JW)-VOLSR(JW))/VOLSR(JW)*100.0
            VOLINJW=VOLINJW+VOLIN(JB)
            VOLPRJW=VOLPRJW+VOLPR(JB)
            VOLOUTJW=VOLOUTJW+VOLOUT(JB)
            VOLWDJW=VOLWDJW+VOLWD(JB)
            VOLEVJW=VOLEVJW+VOLEV(JB)
            VOLDTJW=VOLDTJW+VOLDT(JB)
            VOLTRBJW=VOLTRBJW+VOLTRB(JB)
         END DO

        IF (CONTOUR(JW)) THEN
        IF (JDAY+(DLT/DAY) >= NXTMCP(JW) .OR. JDAY+(DLT/DAY) >= CPLD(CPLDP(JW)+1,JW))WRITE(9525,'(F10.3,",",1X,I3,",",10(E16.8,",",1X))')JDAY,JW,VOLINJW,VOLPRJW,VOLOUTJW,VOLWDJW,VOLEVJW,VOLDTJW,VOLTRBJW
        END IF  ! CONTOUR INTERVAL FOR WRITING OUT FLOW BALANCE 
        ENDIF   ! VOLUME BALANCE
      IF (ENERGY_BALANCE(JW)) THEN
        ESR(JW) = 0.0
        ETR(JW) = 0.0
        DO JB=BS(JW),BE(JW)
          ETBR(JB) = EBRI(JB)+TSSEV(JB)+TSSPR(JB)+TSSTR(JB)+TSSDT(JB)+TSSWD(JB)+TSSUH(JB)+TSSDH(JB)+TSSIN(JB)+TSSOUT(JB)+TSSS(JB)  &
                     +TSSB(JB)+TSSICE(JB)
          ESBR(JB) = 0.0
          DO I=CUS(JB),DS(JB)
            DO K=KT,KB(I)
              ESBR(JB) = ESBR(JB)+T1(K,I)*DLX(I)*BH1(K,I)
            END DO
          END DO
          ETR(JW) = ETR(JW)+ETBR(JB)
          ESR(JW) = ESR(JW)+ESBR(JB)
        END DO
      END IF
      IF (MASS_BALANCE(JW)) THEN
        DO JB=BS(JW),BE(JW)
          DO JC=1,NAC
            CMBRS(CN(JC),JB) = 0.0
            DO I=CUS(JB),DS(JB)
              DO K=KT,KB(I)
                CMBRS(CN(JC),JB) = CMBRS(CN(JC),JB)+C1(K,I,CN(JC))*DLX(I)*BH1(K,I)
                CMBRT(CN(JC),JB) = CMBRT(CN(JC),JB)+(CSSB(K,I,CN(JC))+CSSK(K,I,CN(JC))*BH1(K,I)*DLX(I))*DLT
              END DO
            END DO
          END DO
! MACROPHYTES
          DO M=1,NMC
            IF(MACROPHYTE_CALC(JW,M))THEN
              MACMBRS(JB,M) = 0.0
              DO I=CUS(JB),DS(JB)
                IF(KTICOL(I))THEN
                  JT=KTI(I)
                ELSE
                  JT=KTI(I)+1
                END IF
                JE=KB(I)
                DO J=JT,JE
                  IF(J.LT.KT)THEN
                    COLB=EL(J+1,I)
                  ELSE
                     COLB=EL(KT+1,I)
                  END IF
                  COLDEP=ELWS(I)-COLB
                  MACMBRS(JB,M) = MACMBRS(JB,M)+MACRM(J,KT,I,M)
                  MACMBRT(JB,M) = MACMBRT(JB,M)+(MACSS(J,KT,I,M)*COLDEP*CW(J,I)*DLX(I))*DLT
                END DO
                DO K=KT+1,KB(I)
                  JT=K
                  JE=KB(I)
                  DO J=JT,JE
                    MACMBRS(JB,M) =MACMBRS(JB,M)+MACRM(J,K,I,M)
!                    MACMBRT(JB,M) = MACMBRT(JB,M)+(MACSS(J,K,I,M)*H2(K,I)*CW(J,I)*DLX(I))*DLT
                    MACMBRT(JB,M) = MACMBRT(JB,M)+(MACSS(J,K,I,M)*(CW(J,I)/B(K,I))*BH1(K,I)*DLX(I))*DLT
                  END DO
                END DO
              END DO
            END IF
          END DO
! END MACROPHYTES
        END DO
      END IF
    END DO

    RETURN
    END SUBROUTINE BALANCES
