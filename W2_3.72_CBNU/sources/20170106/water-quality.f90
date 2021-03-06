
!***********************************************************************************************************************************
!**                                            S U B R O U T I N E   K I N E T I C S                                              **
!***********************************************************************************************************************************

SUBROUTINE KINETICS
  USE SCREENC; USE GLOBAL; USE KINETIC; USE GEOMC; USE TVDC; USE LOGICC; USE SURFHE
  USE MACROPHYTEC; USE ZOOPLANKTONC; USE MAIN, ONLY:EPIPHYTON_CALC, BOD_CALC, ALG_CALC, BOD_CALCN, BOD_CALCP, PO4_CALC, N_CALC, DSI_CALC  ! cb 10/13/2011

! Type declarations
  IMPLICIT NONE
  
  REAL                                :: LAM1,   LAM2,   NH4PR,  NO3PR,  LIMIT,  LIGHT,  L, L0, L1
  REAL                                :: KW,     INCR,   OH,     K1,     K2, bicart
  REAL                                :: CART,ALKT,T1K,S2,SQRS2,DH1,DH2,H2CO3T,CO3T,PHT,F,HION,HCO3T
  REAL                                :: LTCOEFM, LAVG,  MACEXT, TMAC,MACEXT1         ! CB 4/20/11
  REAL                                :: FETCH, U2, COEF1,COEF2,COEF3,COEF4,HS,TS,COEF,UORB,TAU
  REAL                                :: EPSILON, CBODSET, DOSAT,O2EX,CO2EX,SEDSI,SEDEM, SEDSO,SEDSIP
  REAL                                :: SEDSOP,SEDSON,SEDSOC,SEDSIC,SEDSIDK,SEDSUM,SEDSUMK,XDUM
  REAL                                :: BLIM, SEDSIN, COLB,COLDEP,BMASS,BMASSTEST,CVOL
  REAL                                :: ALGEX, SSEXT, TOTMAC, ZOOEXT, TOTSS0, FDPO4, ZMINFAC, SSR   !, SSF                 !SR 04/21/13
  REAL                                :: ZGZTOT,CBODCT,CBODNT,CBODPT,BODTOT  ! CB 6/6/10
  REAL                                :: ALGP,ALGN,ZOOP,ZOON,TPSS,XX   ! SW 4/5/09
  REAL, ALLOCATABLE, DIMENSION(:,:)   :: OMTRM,  SODTRM, NH4TRM, NO3TRM, BIBH2
  REAL, ALLOCATABLE, DIMENSION(:,:)   :: DOM,    POM,    PO4BOD, NH4BOD, TICBOD
  REAL, ALLOCATABLE, DIMENSION(:,:)   :: LAM2M  
  REAL, ALLOCATABLE, DIMENSION(:,:,:) :: ATRM,   ATRMR,  ATRMF
  REAL, ALLOCATABLE, DIMENSION(:,:,:) :: ETRM,   ETRMR,  ETRMF
  INTEGER                             :: K, JA, JE, M, JS, JT, JJ, JJZ, JG, JCB, JBOD, LLM,J,JD
  INTEGER                             :: MI,JAF,N,ITER,IBOD
  INTEGER                             :: ASTYPE   ! CSW 1/4/16 CYANO BUYANCY PARAMETER 
  SAVE

! Allocation declarations

  ALLOCATE (OMTRM(KMX,IMX),    SODTRM(KMX,IMX),    NH4TRM(KMX,IMX),    NO3TRM(KMX,IMX), DOM(KMX,IMX), POM(KMX,IMX))
  ALLOCATE (PO4BOD(KMX,IMX),   NH4BOD(KMX,IMX),    TICBOD(KMX,IMX))
  ALLOCATE (ATRM(KMX,IMX,NAL), ATRMR(KMX,IMX,NAL), ATRMF(KMX,IMX,NAL))
  ALLOCATE (ETRM(KMX,IMX,NEP), ETRMR(KMX,IMX,NEP), ETRMF(KMX,IMX,NEP))
  ALLOCATE (lam2m(KMX,kmx),    BIBH2(KMX,IMX))

! CSW++  OPEN AND READ w2_cyano.npt FILE
    OPEN(9550,FILE='W2_CYANO.NPT',STATUS='OLD')
    READ(9550,'(//I8,6F8.0)')ASTYPE, ARHOI, ARHOL, ARHOU, ARAD, RCOL, AFORM
    ARAD = ARAD/1000000
!    ARHOZ = ARHOI
    READ(9550,'(/)')
    READ(9550,'(5F8.0)')AC1,AC2,AC3,AKH, PARA
    CLOSE(9550)
! CSW-- 1/4/17                      
RETURN

!***********************************************************************************************************************************
!**                                      T E M P E R A T U R E  R A T E  M U L T I P L I E R S                                    **
!***********************************************************************************************************************************

ENTRY TEMPERATURE_RATES
  DO I=IU,ID
    DO K=KT,KB(I)
      LAM1        = FR(T1(K,I),NH4T1(JW),NH4T2(JW),NH4K1(JW),NH4K2(JW))
      NH4TRM(K,I) = LAM1/(1.0+LAM1-NH4K1(JW))
      LAM1        = FR(T1(K,I),NO3T1(JW),NO3T2(JW),NO3K1(JW),NO3K2(JW))
      NO3TRM(K,I) = LAM1/(1.0+LAM1-NO3K1(JW))
      LAM1        = FR(T1(K,I),OMT1(JW),OMT2(JW),OMK1(JW),OMK2(JW))
      OMTRM(K,I)  = LAM1/(1.0+LAM1-OMK1(JW))
      LAM1        = FR(T1(K,I),SODT1(JW),SODT2(JW),SODK1(JW),SODK2(JW))
      SODTRM(K,I) = LAM1/(1.0+LAM1-SODK1(JW))
      DO JA=1,NAL
        IF(ALG_CALC(JA))THEN
        LAM1          = FR(T1(K,I),AT1(JA),AT2(JA),AK1(JA),AK2(JA))
        LAM2          = FF(T1(K,I),AT3(JA),AT4(JA),AK3(JA),AK4(JA))
        ATRMR(K,I,JA) = LAM1/(1.0+LAM1-AK1(JA))
        ATRMF(K,I,JA) = LAM2/(1.0+LAM2-AK4(JA))
        ATRM(K,I,JA)  = ATRMR(K,I,JA)*ATRMF(K,I,JA)
        ENDIF
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))then
        LAM1          = FR(T1(K,I),ET1(JE),ET2(JE),EK1(JE),EK2(JE))
        LAM2          = FF(T1(K,I),ET3(JE),ET4(JE),EK3(JE),EK4(JE))
        ETRMR(K,I,JE) = LAM1/(1.0+LAM1-EK1(JE))
        ETRMF(K,I,JE) = LAM2/(1.0+LAM2-EK4(JE))
        ETRM(K,I,JE)  = ETRMR(K,I,JE)*ETRMF(K,I,JE)
        endif
      END DO
      DO M=1,NMC
      IF(MACROPHYTE_CALC(JW,M))THEN
        LAM1    = FR(T1(K,I),MT1(M),MT2(M),MK1(M),MK2(M))
        LAM2    = FF(T1(K,I),MT3(M),MT4(M),MK3(M),MK4(M))
        MACTRMR(K,I,M) = LAM1/(1.0+LAM1-MK1(M))
        MACTRMF(K,I,M) = LAM2/(1.0+LAM2-MK4(M))
        MACTRM(K,I,M)  = MACTRMR(K,I,M)*MACTRMF(K,I,M)
      endif
      end do
      IF(ZOOPLANKTON_CALC)THEN
	    DO JZ = 1, NZP
          LAM1       = FR(T1(K,I),ZT1(JZ),ZT2(JZ),ZK1(JZ),ZK2(JZ))
          LAM2       = FF(T1(K,I),ZT3(JZ),ZT4(JZ),ZK3(JZ),ZK4(JZ))
          ZOORMR(K,I,JZ)= LAM1/(1.+LAM1-ZK1(JZ))
          ZOORMF(K,I,JZ)= LAM2/(1.+LAM2-ZK4(JZ))
          ZOORM(K,I,JZ) = ZOORMR(K,I,JZ)*ZOORMF(K,I,JZ)
        END DO
	  end if
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                 K I N E T I C   R A T E S                                                     **
!***********************************************************************************************************************************

ENTRY KINETIC_RATES
! Decay rates
!!$OMP PARALLEL DO 
  DO I=IU,ID
    DO K=KT,KB(I)
      DO1(K,I)          = O2(K,I)/(O2(K,I)+KDO)                  
      DO2(K,I)          = 1.0 - DO1(K,I)                         !O2(K,I)/(O2(K,I)+KDO)
      DO3(K,I)          = (1.0+SIGN(1.0,O2(K,I)-1.E-10)) *0.5
      SEDD(K,I)         =   SODTRM(K,I) *SDKV(K,I)   *SED(K,I) *DO3(K,I)   !CB 10/22/06
      SEDDP(K,I)         =  SODTRM(K,I) *SDKV(K,I)   *SEDP(K,I) *DO3(K,I)
      SEDDN(K,I)         =  SODTRM(K,I) *SDKV(K,I)   *SEDN(K,I) *DO3(K,I)
      SEDDC(K,I)         =  SODTRM(K,I) *SDKV(K,I)   *SEDC(K,I) *DO3(K,I)
      SEDBR(K,I)         =  SEDB(JW)    *SED(K,I)                           !CB 11/30/06
      SEDBRP(K,I)        =  SEDB(JW)    *SEDP(K,I)                          !CB 11/30/06
      SEDBRN(K,I)        =  SEDB(JW)    *SEDN(K,I)                          !CB 11/30/06
      SEDBRC(K,I)        =  SEDB(JW)    *SEDC(K,I)                          !CB 11/30/06
      NH4D(K,I)         =  NH4TRM(K,I) *NH4DK(JW) *NH4(K,I) *DO1(K,I)
      NO3D(K,I)         =  NO3TRM(K,I) *NO3DK(JW) *NO3(K,I) *DO2(K,I)
      LDOMD(K,I)        =  OMTRM(K,I)  *LDOMDK(JW)*LDOM(K,I)*DO3(K,I)
      RDOMD(K,I)        =  OMTRM(K,I)  *RDOMDK(JW)*RDOM(K,I)*DO3(K,I)
      LPOMD(K,I)        =  OMTRM(K,I)  *LPOMDK(JW)*LPOM(K,I)*DO3(K,I)
      RPOMD(K,I)        =  OMTRM(K,I)  *RPOMDK(JW)*RPOM(K,I)*DO3(K,I)
      LRDOMD(K,I)       =  OMTRM(K,I)  *LRDDK(JW) *LDOM(K,I)*DO3(K,I)
      LRPOMD(K,I)       =  OMTRM(K,I)  *LRPDK(JW) *LPOM(K,I)*DO3(K,I)
      CBODD(K,I,1:NBOD) =  KBOD(1:NBOD)*TBOD(1:NBOD)**(T1(K,I)-20.0)*DO3(K,I)
        IF(K == KB(I))THEN     ! SW 4/18/07
	  SODD(K,I)         =  SOD(I)/BH2(K,I)*SODTRM(K,I)*BI(K,I)
	    ELSE
      SODD(K,I)         =  SOD(I)/BH2(K,I)*SODTRM(K,I)*(BI(K,I)-BI(K+1,I))
	    ENDIF

! Inorganic suspended solids settling rates - P adsorption onto SS and Fe
      FPSS(K,I) = PARTP(JW)         /(PARTP(JW)*TISS(K,I)+PARTP(JW)*FE(K,I)*DO1(K,I)+1.0)
      FPFE(K,I) = PARTP(JW)*FE(K,I) /(PARTP(JW)*TISS(K,I)+PARTP(JW)*FE(K,I)*DO1(K,I)+1.0)
      SSSI(K,I) = SSSO(K-1,I)
      TOTSS0    = 0.0
      DO JS=1,NSS
        TOTSS0 = TOTSS0+SSS(JS)*FPSS(K,I)*SS(K,I,JS)
      END DO
      SSSO(K,I) = (TOTSS0+FES(JW)*FPFE(K,I))*BI(K,I)/BH2(K,I)*DO1(K,I)                ! SW 11/7/07
      FPSS(K,I) =  FPSS(K,I)*TISS(K,I)

! OM stoichiometry
        ORGPLD(K,I)=0.0
        ORGPRD(K,I)=0.0
        ORGPLP(K,I)=0.0
        ORGPRP(K,I)=0.0
        ORGNLD(K,I)=0.0
        ORGNRD(K,I)=0.0
        ORGNLP(K,I)=0.0
        ORGNRP(K,I)=0.0
        IF(CAC(NLDOMP) == '      ON')THEN
          IF(LDOM(K,I).GT.0.0)THEN
          ORGPLD(K,I)=LDOMP(K,I)/LDOM(K,I)
          ELSE
          ORGPLD(K,I)=ORGP(JW)
          ENDIF
        ELSE
          ORGPLD(K,I)=ORGP(JW)
        END IF
        IF(CAC(NRDOMP) == '      ON')THEN
          IF(RDOM(K,I).GT.0.0)THEN
          ORGPRD(K,I)=RDOMP(K,I)/RDOM(K,I)
          ELSE
          ORGPRD(K,I)=ORGP(JW)
          ENDIF
        ELSE
          ORGPRD(K,I)=ORGP(JW)
        END IF
        IF(CAC(NLPOMP) == '      ON')THEN
          IF(LPOM(K,I).GT.0.0)THEN
          ORGPLP(K,I)=LPOMP(K,I)/LPOM(K,I)
          ELSE
          ORGPLP(K,I)=ORGP(JW)
          ENDIF
        ELSE
          ORGPLP(K,I)=ORGP(JW)
        END IF
        IF(CAC(NRPOMP) == '      ON')THEN
          IF(RPOM(K,I).GT.0.0)THEN
          ORGPRP(K,I)=RPOMP(K,I)/RPOM(K,I)
          ELSE
          ORGPRP(K,I)=ORGP(JW)
          ENDIF
        ELSE
          ORGPRP(K,I)=ORGP(JW)
        END IF
        IF(CAC(NLDOMN) == '      ON')THEN
          IF(LDOM(K,I).GT.0.0)THEN
          ORGNLD(K,I)=LDOMN(K,I)/LDOM(K,I)
          ELSE
          ORGNLD(K,I)=ORGN(JW)
          ENDIF
        ELSE
          ORGNLD(K,I)=ORGN(JW)
        END IF
        IF(CAC(NRDOMN) == '      ON')THEN
          IF(RDOM(K,I).GT.0.0)THEN
          ORGNRD(K,I)=RDOMN(K,I)/RDOM(K,I)
          ELSE
          ORGNRD(K,I)=ORGN(JW)
          ENDIF
        ELSE
          ORGNRD(K,I)=ORGN(JW)
        END IF
        IF(CAC(NLPOMN) == '      ON')THEN
          IF(LPOM(K,I).GT.0.0)THEN
          ORGNLP(K,I)=LPOMN(K,I)/LPOM(K,I)
          ELSE
          ORGNLP(K,I)=ORGN(JW)
          ENDIF
        ELSE
          ORGNLP(K,I)=ORGN(JW)
        END IF
        IF(CAC(NRPOMP) == '      ON')THEN
          IF(RPOM(K,I).GT.0.0)THEN
          ORGNRP(K,I)=RPOMN(K,I)/RPOM(K,I)
          ELSE
          ORGNRP(K,I)=ORGN(JW)
          ENDIF
        ELSE
          ORGNRP(K,I)=ORGN(JW)
        END IF

! Light Extinction Coefficient
      IF (.NOT. READ_EXTINCTION(JW)) THEN
      ALGEX = 0.0; SSEXT = 0.0; ZOOEXT = 0.0                                                     ! SW 11/8/07
        DO JA=1,NAL
          IF(ALG_CALC(JA))ALGEX = ALGEX+EXA(JA)*ALG(K,I,JA)
        END DO
        DO JS=1,NSS
          SSEXT = SSEXT+EXSS(JW)*SS(K,I,JS)
        END DO
 !       TOTMAC=0.0                                                                ! SW 4/20/11 Delete this section?
 !       DO M=1,NMC
 !         IF(MACROPHYTE_CALC(JW,M))THEN
 !           JT=KTI(I)
 !           JE=KB(I)
 !           DO JJ=JT,JE
 !             TOTMAC = EXM(M)*MACRM(JJ,K,I,M)+TOTMAC
 !           END DO
 !         END IF
 !       END DO
 !       MACEXT=TOTMAC/(BH2(K,I)*DLX(I))

	    IF(ZOOPLANKTON_CALC)THEN
	        DO JZ = 1,NZP
	        ZOOEXT = ZOOEXT + ZOO(K,I,JZ)*EXZ(JZ)
	        END DO
	    ENDIF
		
		GAMMA(K,I) = EXH2O(JW)+SSEXT+EXOM(JW)*(LPOM(K,I)+RPOM(K,I))+ALGEX+ZOOEXT         ! sw 4/21/11
		
	    IF(NMC>0)THEN    ! cb 4/20/11
	      MACEXT1=0.0    ! cb 4/20/11
          IF(KTICOL(I))THEN
            JT=KTI(I)
          ELSE
            JT=KTI(I)+1
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            TOTMAC=0.0
            DO M=1,NMC
              IF(MACROPHYTE_CALC(JW,M))THEN
                TOTMAC = EXM(M)*MACRM(JJ,K,I,M)+TOTMAC
              END IF
            END DO
            IF(CW(JJ,I).GT.0.0)THEN
              MACEXT=TOTMAC/(CW(JJ,I)*DLX(I)*H2(K,I))
            ELSE
              MACEXT=0.0
            END IF
			GAMMAJ(JJ,K,I) = GAMMA(K,I)+MACEXT       ! SW 4/20/11
            MACEXT1 = MACEXT*CW(JJ,I)+MACEXT1    ! cb 4/20/11
          END DO
          GAMMA(K,I) = GAMMA(K,I) + MACEXT1/B(JT,I)                                      ! SW 4/21/11
        end if
      ELSE
        GAMMA(K,I) = EXH2O(JW)
      END IF

! Zooplankton Rates
   IF(ZOOPLANKTON_CALC)THEN
      DO JZ=1,NZP
        TGRAZE(K,I,JZ)=PREFP(JZ)*LPOM(K,I)
        DO JJZ = 1, NZP
          TGRAZE(K,I,JZ) = TGRAZE(K,I,JZ) + PREFZ(JJZ,JZ)*ZOO(K,I,JJZ)          !CB 5/17/2007
      END DO
        DO JA=1,NAL
          IF(ALG_CALC(JA))TGRAZE(K,I,JZ)=PREFA(JA,JZ)*ALG(K,I,JA)+TGRAZE(K,I,JZ)
        END DO
        ZMINFAC  = (1.0+SIGN(1.0,ZOO(K,I,JZ)-ZOOMIN(JZ)))*0.5
        ZRT(K,I,JZ) =  ZOORMR(K,I,JZ)*ZR(JZ)*ZMINFAC*DO3(K,I)
        IF (TGRAZE(K,I,JZ) <= 0.0 .OR. O2(K,I) < 2.0) THEN
          ZMU(K,I,JZ)       = 0.0
          AGZ(K,I,1:NAL,JZ) = 0.0
		  ZGZ(K,I,JZ,:) = 0.0
          IF (O2(K,I) < 2.0) ZMINFAC = 2*ZMINFAC
        ELSE
          ZMU(K,I,JZ) = MAX(ZOORM(K,I,JZ)*ZG(JZ)*(TGRAZE(K,I,JZ)-ZOOMIN(JZ))/(TGRAZE(K,I,JZ)+ZS2P(JZ)), 0.0)
          DO JA=1,NAL
          IF(ALG_CALC(JA))AGZ(K,I,JA,JZ) = ZMU(K,I,JZ)*ZOO(K,I,JZ)*(ALG(K,I,JA)*PREFA(JA,JZ)/TGRAZE(K,I,JZ))                      !  KV 5/26/2007
          END DO
          DO JJZ = 1,NZP ! OMNIVOROUS ZOOPLANKTON
          ZGZ(K,I,JJZ,JZ)  = ZMU(K,I,JZ)*ZOO(K,I,JZ)*(ZOO(K,I,JJZ)*PREFZ(JJZ,JZ)/TGRAZE(K,I,JZ))         !KV 5/26/2007
          END DO
        END IF
        ZMT(K,I,JZ) = MAX(1.0-ZOORMF(K,I,JZ),0.02)*ZM(JZ)*ZMINFAC
      END DO   ! ZOOP LOOP
   ENDIF

    END DO ! K LOOP
  END DO   ! I LOOP
!!$OMP END PARALLEL DO

! Algal rates
!! CSW++  OPEN AND READ w2_cyano.npt FILE
!    OPEN(9550,FILE='W2_CYANO.NPT',STATUS='OLD')
!    READ(9550,'(//I8,6F8.0)')ASTYPE, ARHOI, ARHOL, ARHOU, ARAD, RCOL, AFORM
!    ARAD = ARAD/1000000
!!    ARHOZ = ARHOI
!    READ(9550,'(/)')
!    READ(9550,'(5F8.0)')AC1,AC2,AC3,AKH, PARA
!    CLOSE(9550)
!! CSW-- 1/4/17                    
   DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
      DO i=iu,id
!**** Limiting factor
      LIGHT = (1.0-BETA(JW))*SRON(JW)*SHADE(I)/ASAT(JA)
      LAM1  =  LIGHT
      LAM2  =  LIGHT
      DO K=KT,KB(I)

!****** Limiting factor
        LAM1           = LAM2
        LAM2           = LAM1*EXP(-GAMMA(K,I)*H2(K,I))
        FDPO4          = 1.0-FPSS(K,I)-FPFE(K,I)
        ALLIM(K,I,JA)  = 2.718282*(EXP(-LAM2)-EXP(-LAM1))/(GAMMA(K,I)*H2(K,I))
        IF (AHSP(JA)  /= 0.0 .and. po4_calc) APLIM(K,I,JA) =  FDPO4*PO4(K,I)/(FDPO4*PO4(K,I)+AHSP(JA)+NONZERO)       ! cb 10/12/11
        IF (AHSN(JA)  /= 0.0 .and. n_calc) ANLIM(K,I,JA) = (NH4(K,I)+NO3(K,I))/(NH4(K,I)+NO3(K,I)+AHSN(JA)+NONZERO)  ! cb 10/12/11
        IF (AHSSI(JA) /= 0.0 .and. DSI_CALC) ASLIM(K,I,JA) =  DSI(K,I)/(DSI(K,I)+AHSSI(JA)+NONZERO)                  ! cb 10/12/11
        LIMIT          = MIN(APLIM(K,I,JA),ANLIM(K,I,JA),ASLIM(K,I,JA),ALLIM(K,I,JA))

!****** Algal rates
        AGR(K,I,JA) =  ATRM(K,I,JA)*AG(JA)*LIMIT
        ARR(K,I,JA) =  ATRM(K,I,JA)*AR(JA)*DO3(K,I)
        AMR(K,I,JA) = (ATRMR(K,I,JA)+1.0-ATRMF(K,I,JA))*AM(JA)
        AER(K,I,JA) =  MIN((1.0-ALLIM(K,I,JA))*AE(JA)*ATRM(K,I,JA),AGR(K,I,JA))
!***** CSW ++ Cyano buoyancy control
        ! 1) Open and Read w2_cyano.npt
        ! 2) IF (ASTYPE .EQ. 1) THEN
        !    RHO(K,I) = DENSITY(T1(K,I),MAX(TDS(K,I),0.0),MAX(TISS(K,I),0.0))  ! CSW 07/30/15
        !    VISCOS(K,I)  = (10*EXP(-1.65+(262/(T1(K,I)+139))))/1000
        ! 3) PARZ(K, I)=(1.0-BETA(JW))*SRON(JW)*SHADE(I)*EXP(-GAMMA(K,I)*H2(K,I))
        ! 4) IF (PARZ(K,I) > 0) THEN  
        ! 5)   ARHOZ(K,I)=ARHOZ(K,I)+DEL*(AC1*(1-EXP(PARZ(K,I)/AKH)-AC3)
        ! 6) ELSE
        ! 7)   ARHOZ(K,I)=ARHOZ(K,I)+DEL*(AC2*PARA-AC3)
        ! 8) ENDIF
        ! 9) ASCYA(K,I) = 2*9.8*ARAD*ARAD*RCOL*(AROHZ(K,I)-RHO(K,I))/(9*AFORM*VISCOS(K,I))
       IF((JA .EQ. 2) .AND. (ASTYPE .EQ. 1)) THEN         
          RHO(K,I) = DENSITY(T1(K,I),MAX(TDS(K,I),0.0),MAX(TISS(K,I),0.0))  ! CSW 07/30/15
          VISCOS(K,I)  = (10*EXP(-1.65+(262/(T1(K,I)+139))))/1000
          PARZ(K, I)=((1.0-BETA(JW))*SRON(JW)*SHADE(I)*EXP(-GAMMA(K,I)*DEPTHM(K,I)))/0.235   ! W/M2/S ->uE/M2/S
           IF(PARZ(K,I) > 0)THEN 
!             ARHOZ(K,I)=ARHOZ(K,I)+DLT*(AC1*(1-EXP(-PARZ(K,I)/AKH)-AC3))/60             ! CAEDYM equation
              ARHOZ(K,I)=ARHOZ(K,I)+DLT*(AC1*(PARZ(K,I)/(PARZ(K,I)+AKH)-AC3))/60          ! Kromkamp and Walsby, 1990  
              ARHOZ(K,I)=MIN(ARHOU, ARHOZ(K,I))
           ELSE
              ARHOZ(K,I)=ARHOZ(K,I)+DLT*(-AC2*PARA-AC3)/60
              ARHOZ(K,I)=MAX(ARHOL, ARHOZ(K,I))
           ENDIF
           ASCYA(K,I) = 2*9.8*ARAD*ARAD*RCOL*(ARHOZ(K,I)-RHO(K,I))/(9*AFORM*VISCOS(K,I))     ! CSW 1/4/17
           IF (ASCYA(K,I) >= 0.0) THEN
              ASCYA(K,I) = MIN(AS(JA), ASCYA(K,I))    ! CSW 1/6/17  Maximum settling velocity as AS in w2_con.npt            
              IF(K == KT)THEN
                 ASR(K,I,JA) =  ASCYA(K,I)*(-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
              ELSE
                 ASR(K,I,JA) = ASCYA(K,I)*(ALG(K-1,I,JA)-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
              ENDIF
           ELSE
              IF(K == KB(I))THEN
                 ASR(K,I,JA) = -ASCYA(K,I)*(-ALG(K,I,JA)  *BI(K,I)/BH2(K,I))                                           !SW 11/8/07
              ELSEIF(K == KT)THEN
                 ASR(K,I,JA) = -ASCYA(K,I)* ALG(K+1,I,JA)*BI(K+1,I)*DLX(I)/VOL(K,I)                                   !SW 11/8/07
              ELSE
                 ASR(K,I,JA) = -ASCYA(K,I)*(ALG(K+1,I,JA)*BI(K+1,I)/BH2(K,I)-ALG(K,I,JA)*BI(K,I)/BH2(K,I))             !SP 8/27/07
              END IF
           END IF
       ELSE
!***** CSW -- 1/4/17
        IF (AS(JA) >= 0.0) THEN
          IF(K == KT)THEN
             ASR(K,I,JA) =  AS(JA)*(-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
          ELSE
             ASR(K,I,JA) =  AS(JA)*(ALG(K-1,I,JA)-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
          ENDIF
        ELSE
          IF(K == KB(I))THEN
            ASR(K,I,JA) = -AS(JA)*(-ALG(K,I,JA)  *BI(K,I)/BH2(K,I))                                           !SW 11/8/07
          ELSEIF(K == KT)THEN
            ASR(K,I,JA) = -AS(JA)* ALG(K+1,I,JA)*BI(K+1,I)*DLX(I)/VOL(K,I)                                   !SW 11/8/07
          ELSE
            ASR(K,I,JA) = -AS(JA)*(ALG(K+1,I,JA)*BI(K+1,I)/BH2(K,I)-ALG(K,I,JA)*BI(K,I)/BH2(K,I))             !SP 8/27/07
          END IF
        END IF         
       ENDIF
      end do
    end do
    ENDIF
   END DO    ! ALGAE LOOP

! Macrophyte Light/Nutrient Limitation and kinetic rates
  do m=1,nmc
  if(macrophyte_calc(jw,m))then
    DO I=IU,ID
      LTCOEFm = (1.0-BETA(jw))*SRON(jw)*SHADE(I)
      if(kticol(i))then
        jt=kti(i)
      else
        jt=kti(i)+1
      end if
      je=kb(i)
      do jj=jt,je
        lam1=ltcoefm
        lam2m(jj,kt)=lam1*exp(-gammaj(jj,kt,i)*h2(kt,i))
        lavg=(lam1-lam2m(jj,kt))/(GAMMAj(jj,kt,i)*H2(kt,i))
        mLLIM(jj,kt,I,m) = lavg/(lavg+msat(m))
        IF (mHSP(m)  /= 0.0.and.psed(m) < 1.0)then
          mPLIM(kt,I,m) =  FDPO4*PO4(kt,I)/(FDPO4*PO4(kt,I)+mHSP(m)+nonzero)
        else
          mPLIM(kt,I,m)=1.0
        end if
        IF (mHSN(m)  /= 0.0.and.nsed(m) < 1.0)then
          mNLIM(kt,I,m) = NH4(kt,I)/(NH4(kt,I)+mHSN(m)+nonzero)
        else
          mNLIM(kt,I,m)=1.0
        end if
        IF (mHSc(m) /= 0.0)then
          mcLIM(kt,i,m) = co2(kt,I)/(co2(kt,I)+mHSc(m)+NONZERO)
        end if
        LIMIT          = MIN(mPLIM(kt,I,m),mNLIM(kt,I,m),mcLIM(kt,I,m),mLLIM(jj,kt,I,m))

!************* sources/sinks

        mGR(jj,Kt,I,m) = macTRM(Kt,I,m)*mG(m)*LIMIT

      end do

      mRR(Kt,I,m) = macTRM(Kt,I,m)*mR(m)*DO3(Kt,I)
      mMR(Kt,I,m) = (macTRMR(Kt,I,m)+1.0-mAcTRMF(Kt,I,m))*mM(m)

      DO K=KT+1,KB(I)
        jt=k
        je=kb(i)
        do jj=jt,je
          lam1=lam2m(jj,k-1)
          lam2m(jj,k)=lam1*exp(-gammaj(jj,k,i)*h2(k,i))
          lavg=(lam1-lam2m(jj,k))/(GAMMAj(jj,k,i)*H2(k,i))
          mLLIM(jj,K,I,m) = lavg/(lavg+msat(m))
          IF (mHSP(m)  /= 0.0.and.psed(m) < 1.0)then
            mPLIM(K,I,m) =  FDPO4*PO4(K,I)/(FDPO4*PO4(K,I)+mHSP(m)+nonzero)
          else
            mPLIM(K,I,m)=1.0
          end if
          IF (mHSN(m)  /= 0.0.and.nsed(m) < 1.0)then
            mNLIM(K,I,m) = NH4(K,I)/(NH4(K,I)+mHSN(m)+nonzero)
          else
             mNLIM(K,I,m)=1.0
          end if
          IF (mHSc(m) /= 0.0)then
            mcLIM(k,i,m) = co2(K,I)/(co2(K,I)+mHSc(m)+NONZERO)
          end if
          LIMIT          = MIN(mPLIM(K,I,m),mNLIM(K,I,m),mcLIM(K,I,m),mLLIM(jj,K,I,m))

!************* sources/sinks

          mGR(jj,K,I,m) = macTRM(K,I,m)*mG(m)*LIMIT

        end do

        mRR(K,I,m) = macTRM(K,I,m)*mR(m)*DO3(K,I)
        mMR(K,I,m) = (macTRMR(K,I,m)+1.0-mAcTRMF(K,I,m))*mM(m)
      end do
    END DO
    ENDIF
  END DO
RETURN

!***********************************************************************************************************************************
!**                                             G E N E R I C   C O N S T I T U E N T                                             **
!***********************************************************************************************************************************

ENTRY GENERIC_CONST (JG)
xx=0.0
DO I=IU,ID
      DO K=KT,KB(I)

         IF (CGS(JG) > 0.0) THEN
          IF(K == KT)THEN
          xx =  CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)    ! AS(JA)*(-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
          ELSE
          xx =  CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)     !AS(JA)*(ALG(K-1,I,JA)-ALG(K,I,JA))*BI(K,I)/BH2(K,I)
          ENDIF
         ELSEif(cgs(jg)<0.0)then
          IF(K == KB(I))THEN
            xx = -CGS(JG)*(-CG(K,I,JG))*BI(K,I)/BH2(K,I)    !-AS(JA)*(-ALG(K,I,JA)  *BI(K,I)/BH2(K,I))                                           !SW 11/8/07
          ELSEIF(K == KT)THEN
            xx = -CGS(JG)*CG(K+1,I,JG)*BI(K+1,I)*DLX(I)/VOL(K,I)    !-AS(JA)* ALG(K+1,I,JA)*BI(K+1,I)*DLX(I)/VOL(K,I)                                   !SW 11/8/07
          ELSE
            xx = -CGS(JG)*(CG(K+1,I,JG)*BI(K+1,I)/BH2(K,I)-CG(K,I,JG)*BI(K,I)/BH2(K,I))    !-AS(JA)*(ALG(K+1,I,JA)*BI(K+1,I)/BH2(K,I)-ALG(K,I,JA)*BI(K,I)/BH2(K,I))             !SP 8/27/07
          END IF
         ENDIF
         !CSW++  If GC is Gen4 then include Geosmin Sources
         IF( JG .EQ. 4 ) THEN 
                xx = ALG(K,I,2)*(AER(K,I,2)+AMR(K,I,2))*AGEOS(2)
!                xx = ALG(K,I,1)*(AER(K,I,1)+(1.0-APOM(1))*AMR(K,I,1))*AGEOS(1)
         ENDIF    
         !CSW--
         IF (CGQ10(JG) /= 0.0) THEN
             CGSS(K,I,JG) = -CG0DK(JG)*CGQ10(JG)**(T1(K,I)-20.0)-CG1DK(JG)*CGQ10(JG)**(T1(K,I)-20.0)*CG(K,I,JG)+xx            ! SW 4/5/09 CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)
         ELSE
             CGSS(K,I,JG) = -CG0DK(JG)-CG1DK(JG)*CG(K,I,JG)+xx                                                                ! SW 4/5/09 CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)              
         ENDIF
     END DO
   END DO
 RETURN  



!  IF (CGQ10(JG) /= 0.0) THEN
!    DO I=IU,ID
!      DO K=KT,KB(I)
!        CGSS(K,I,JG) = -CG0DK(JG)*CGQ10(JG)**(T1(K,I)-20.0)-CG1DK(JG)*CGQ10(JG)**(T1(K,I)-20.0)*CG(K,I,JG)+xx            ! SW 4/5/09 CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)
!      END DO
!    END DO
!  ELSE
!    DO I=IU,ID
!      DO K=KT,KB(I)
!        CGSS(K,I,JG) = -CG0DK(JG)-CG1DK(JG)*CG(K,I,JG)+                                                                   ! SW 4/5/09 CGS(JG)*(CG(K-1,I,JG)-CG(K,I,JG))*BI(K,I)/BH2(K,I)
!      END DO
!    END DO
!  END IF
!RETURN

!***********************************************************************************************************************************
!**                                               S U S P E N D E D   S O L I D S                                                 **
!***********************************************************************************************************************************

ENTRY SUSPENDED_SOLIDS (J)
  DO I=IU,ID
    SSR = 0.0
    IF (SEDIMENT_RESUSPENSION(J)) THEN
      FETCH = FETCHD(I,JB)
      IF (COS(PHI(JW)-PHI0(I)) < 0.0) FETCH = FETCHU(I,JB)
      FETCH = MAX(FETCH,BI(KT,I),DLX(I))
      U2    = WIND(JW)*WSC(I)*WIND(JW)*WSC(I)+NONZERO
      COEF1 = 0.53  *(G*DEPTHB(KT,I)/U2)**0.75
      COEF2 = 0.0125*(G*FETCH/U2)**0.42
      COEF3 = 0.833* (G*DEPTHB(KT,I)/U2)**0.375
      COEF4 = 0.077* (G*FETCH/U2)**0.25
      HS    = 0.283 *U2/G*0.283*TANH(COEF1)*TANH(COEF2/TANH(COEF1))
     ! TS    = 2.0*PI*U2/G*1.2*  TANH(COEF3)*TANH(COEF4/TANH(COEF3))
      TS    = 2.0*PI*sqrt(U2)/G*1.2*  TANH(COEF3)*TANH(COEF4/TANH(COEF3))   ! cb 7/15/14
      L0    = G*TS*TS/(2.0*PI)
    END IF
    SSSS(KT,I,J) = -SSS(J)*SS(KT,I,J)*BI(KT,I)/BH2(KT,I)+SSR
 !   DO K=KT-1,KB(I)-1                                             ! SW 4/3/09   KT,KB
     DO K=KT+1,KB(I)-1                 ! cb 9/29/14
      IF (SEDIMENT_RESUSPENSION(J)) THEN
        L1 = L0
        L  = L0*TANH(2.0*PI*DEPTHB(K,I)/L1)
        DO WHILE (ABS(L-L1) > 0.001)
          L1 = L
          L  = L0*TANH(2.0*PI*DEPTHB(K,I)/L1)
        END DO
        COEF = MIN(710.0,2.0*PI*DEPTHB(K,I)/L)
        UORB = PI*HS/TS*100.0/SINH(COEF)
        TAU  = 0.003*UORB*UORB
        IF (TAU-TAUCR(J) > 0.0) EPSILON = MAX(0.0,0.008/49.0*(TAU-TAUCR(J))**3*10000.0/DLT)
		if(k == kb(i))then   ! SW 4/18/07
		SSR = EPSILON*DLX(I)*BI(K,I)/VOL(K,I)
		else
        SSR = EPSILON*DLX(I)*(BI(K,I)-BI(K+1,I))/VOL(K,I)
		endif
      END IF
      SSSS(K,I,J) = SSS(J)*(SS(K-1,I,J)-SS(K,I,J))*BI(K,I)/BH2(K,I)+SSR
    END DO
    IF (SEDIMENT_RESUSPENSION(J)) SSR = EPSILON*DLX(I)*BI(KB(I),I)/VOL(KB(I),I)
    SSSS(KB(I),I,J) = SSS(J)*(SS(KB(I)-1,I,J)-SS(KB(I),I,J))/H(KB(I),JW)+SSR

  ! Flocculation              !SR                                                      !New section on flocculation          !SR 04/21/13
    !DO K=KT,KB(I)
    !  SSF = 0.0
    !  IF (J > 1 .AND. SSFLOC(J-1) > 0.0) THEN
    !    IF (FLOCEQN(J-1) == 0) THEN
    !      SSF = MIN(SSFLOC(J-1), SS(K,I,J-1)/DLT)
    !    ELSE IF (FLOCEQN(J-1) == 1) THEN
    !      SSF = SSFLOC(J-1)*SS(K,I,J-1)
    !    ELSE IF (FLOCEQN(J-1) == 2) THEN
    !      SSF = SSFLOC(J-1)*SS(K,I,J-1)*SS(K,I,J-1)
    !    END IF
    !  END IF
    !  IF (J < NSS .AND. SSFLOC(J) > 0.0) THEN
    !    IF (FLOCEQN(J) == 0) THEN
    !      SSF = SSF - MIN(SSFLOC(J), SS(K,I,J)/DLT)
    !    ELSE IF (FLOCEQN(J) == 1) THEN
    !      SSF = SSF - SSFLOC(J)*SS(K,I,J)
    !    ELSE IF (FLOCEQN(J) == 2) THEN
    !      SSF = SSF - SSFLOC(J)*SS(K,I,J)*SS(K,I,J)
    !    END IF
    !  END IF
    !  SSSS(K,I,J) = SSSS(K,I,J) + SSF
    !END DO                                                                        !End new section on flocculation      !SR 04/21/13
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      P H O S P H O R U S                                                      **
!***********************************************************************************************************************************

ENTRY PHOSPHORUS
  PO4AR(:,IU:ID) = 0.0; PO4AG(:,IU:ID) = 0.0; PO4ER(:,IU:ID) = 0.0; PO4EG(:,IU:ID) = 0.0; PO4BOD(:,IU:ID) = 0.0
  PO4MR(:,IU:ID) = 0.0; PO4MG(:,IU:ID) = 0.0; PO4ZR(:,IU:ID)=0.0   

  DO I=IU,ID
    DO K=KT,KB(I)
      DO JCB=1,NBOD
!        IF(BOD_CALC(JCB))PO4BOD(K,I) = PO4BOD(K,I)+CBODD(K,I,JCB)*CBOD(K,I,JCB)*BODP(JCB)
         IF(BOD_CALCp(JCB))then                                                ! cb 5/19/11
           PO4BOD(K,I) = PO4BOD(K,I)+CBODD(K,I,JCB)*CBODp(K,I,JCB)    
         else
           PO4BOD(K,I) = PO4BOD(K,I)+CBODD(K,I,JCB)*CBOD(K,I,JCB)*BODP(JCB)
         end if
      END DO
      DO JA=1,NAL
        IF(ALG_CALC(JA))THEN
        PO4AG(K,I) = PO4AG(K,I)+AGR(K,I,JA)*ALG(K,I,JA)*AP(JA)
        PO4AR(K,I) = PO4AR(K,I)+ARR(K,I,JA)*ALG(K,I,JA)*AP(JA)
        ENDIF
      END DO
      DO JE=1,NEP
      IF (EPIPHYTON_CALC(JW,JE))then
        PO4EG(K,I) = PO4EG(K,I)+EGR(K,I,JE)*EPC(K,I,JE)*EP(JE)
        PO4ER(K,I) = PO4ER(K,I)+ERR(K,I,JE)*EPC(K,I,JE)*EP(JE)
      endif
      END DO
      PO4EP(K,I)  = PO4ER(K,I)-PO4EG(K,I)
      PO4AP(K,I)  = PO4AR(K,I)-PO4AG(K,I)
      PO4POM(K,I) = ORGPLP(k,i)*LPOMD(K,I)+orgprp(k,i)*RPOMD(K,I)
      PO4DOM(K,I) = ORGPLD(k,i)*LDOMD(K,I)+orgprd(k,i)*RDOMD(K,I)
      PO4OM(K,I)  = PO4POM(K,I)+PO4DOM(K,I)
      PO4SD(K,I)  = SEDDp(K,I)
      PO4SR(K,I)  = PO4R(JW)*SODD(K,I)*DO2(K,I)
      PO4NS(K,I)  = SSSI(K,I)*PO4(K-1,I)-SSSO(K,I)*PO4(K,I)

      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            PO4MG(K,I)= PO4MG(K,I)+MGR(JJ,K,I,M)*MACRM(JJ,K,I,M)*MP(M)*(1.0-PSED(M))
            PO4MR(K,I)= PO4MR(K,I)+MRR(K,I,M)*MACRM(JJ,K,I,M)*MP(M)
          END DO
        END IF
      END DO
      PO4MR(K,I)=PO4MR(K,I)/(DLX(I)*BH(K,I))
      PO4MG(K,I)=PO4MG(K,I)/(DLX(I)*BH(K,I))
      IF(ZOOPLANKTON_CALC)THEN
      DO JZ = 1,NZP
        PO4ZR(K,I) = PO4ZR(K,I) + ZRT(K,I,JZ)*ZOO(K,I,JZ)*ZP(JZ)
	  END DO
	  ENDIF


      PO4SS(K,I)  = PO4AP(K,I)+PO4EP(K,I)+PO4OM(K,I)+PO4SD(K,I)+PO4SR(K,I)+PO4NS(K,I)+PO4BOD(K,I)  &
                    +PO4MR(K,I)-PO4MG(K,I) +PO4ZR(K,I)    

    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                        A M M O N I U M                                                        **
!***********************************************************************************************************************************

ENTRY AMMONIUM
  NH4AG(:,IU:ID) = 0.0; NH4AR(:,IU:ID) = 0.0; NH4ER(:,IU:ID) = 0.0; NH4EG(:,IU:ID) = 0.0; NH4BOD(:,IU:ID) = 0.0
  NH4MG(:,IU:ID) = 0.0; NH4MR(:,IU:ID) = 0.0; NH4ZR(:,IU:ID)=0.0   
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JCB=1,NBOD
!        IF(BOD_CALC(JCB))NH4BOD(K,I) =  NH4BOD(K,I)+CBODD(K,I,JCB)*CBOD(K,I,JCB)*BODN(JCB)
         IF(BOD_CALCn(JCB))then                                                ! cb 5/19/11
           NH4BOD(K,I) =  NH4BOD(K,I)+CBODD(K,I,JCB)*CBODn(K,I,JCB)
         else
           NH4BOD(K,I) =  NH4BOD(K,I)+CBODD(K,I,JCB)*CBOD(K,I,JCB)*BODN(JCB)
         end if
      END DO
      DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
        IF (ANEQN(JA).EQ.2) THEN
        NH4PR      = NH4(K,I)*NO3(K,I)/((ANPR(JA)+NH4(K,I))*(ANPR(JA)+NO3(K,I)))+NH4(K,I)*ANPR(JA)/((NO3(K,I)  &
                                        +NH4(K,I)+NONZERO)*(ANPR(JA)+NO3(K,I)))
        ELSE
        NH4PR = NH4(K,I)/(NH4(K,I)+NO3(K,I)+NONZERO)
        ENDIF
        IF (AHSN(JA) > 0.0) NH4AG(K,I) = NH4AG(K,I)+AGR(K,I,JA)*ALG(K,I,JA)*AN(JA)*NH4PR
        NH4AR(K,I) = NH4AR(K,I)+ARR(K,I,JA)*ALG(K,I,JA)*AN(JA)
      ENDIF
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))then
        IF (ENEQN(JE) == 2)THEN
        NH4PR = NH4(K,I)*NO3(K,I)/((ENPR(JE)+NH4(K,I))*(ENPR(JE)+NO3(K,I)))+NH4(K,I)*ENPR(JE)/((NO3(K,I)  &
                                        +NH4(K,I)+NONZERO)*(ENPR(JE)+NO3(K,I)))
        ELSE
        NH4PR = NH4(K,I)/(NH4(K,I)+NO3(K,I)+NONZERO)
        ENDIF
        IF (EHSN(JE) > 0.0) NH4EG(K,I) = NH4EG(K,I)+EGR(K,I,JE)*EPC(K,I,JE)*EN(JE)*NH4PR
        NH4ER(K,I) = NH4ER(K,I)+ERR(K,I,JE)*EPC(K,I,JE)*EN(JE)
        endif
      END DO
      NH4EP(K,I)  =  NH4ER(K,I) -NH4EG(K,I)
      NH4AP(K,I)  =  NH4AR(K,I) -NH4AG(K,I)

      NH4DOM(K,I) = LDOMD(K,I)*orgnld(k,i) +RDOMD(K,I)*ORGNrd(k,i)
      NH4POM(K,I) = LPOMD(K,I)*orgnlp(k,i) +RPOMD(K,I)*ORGNrp(k,i)

      NH4OM(K,I)  =  NH4DOM(K,I)+NH4POM(K,I)

      NH4SD(K,I)  =  SEDDn(K,I)
      NH4SR(K,I)  =  NH4R(JW) *SODD(K,I)*DO2(K,I)

      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            NH4MR(K,I)= NH4MR(K,I)+MRR(K,I,M)*MACRM(JJ,K,I,M)*MN(M)
            NH4MG(K,I)= NH4MG(K,I)+MGR(JJ,K,I,M)*MACRM(JJ,K,I,M)*MN(M)*(1.0-NSED(M))
          END DO
        END IF
      END DO
      NH4MR(K,I)=NH4MR(K,I)/(DLX(I)*BH(K,I))
      NH4MG(K,I)=NH4MG(K,I)/(DLX(I)*BH(K,I))
	  IF(ZOOPLANKTON_CALC)THEN
	  DO JZ = 1,NZP
	    NH4ZR(K,I) = NH4ZR(K,I) + ZRT(K,I,JZ)*ZOO(K,I,JZ)*ZN(JZ) 
	  END DO
	  ENDIF
      NH4SS(K,I)  =  NH4AP(K,I)+NH4EP(K,I)+NH4OM(K,I)+NH4SD(K,I)+NH4SR(K,I)+NH4BOD(K,I)-NH4D(K,I)  &
         +NH4MR(K,I)-NH4MG(K,I) +NH4ZR(K,I)     
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                          N I T R A T E                                                        **
!***********************************************************************************************************************************

ENTRY NITRATE
  NO3AG(:,IU:ID) = 0.0; NO3EG(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
        NO3PR = 1.0-NH4(K,I)/(NH4(K,I)+NO3(K,I)+NONZERO)
        IF (ANEQN(JA).EQ.2)  NO3PR      = 1.0-(NH4(K,I)*NO3(K,I)/((ANPR(JA)+NH4(K,I))*(ANPR(JA)+NO3(K,I)))+NH4(K,I)*ANPR(JA)       &
                                          /((NO3(K,I)+NH4(K,I)+NONZERO)*(ANPR(JA)+NO3(K,I))))
        IF (AHSN(JA).GT.0.0) NO3AG(K,I) = NO3AG(K,I)+AGR(K,I,JA)*ALG(K,I,JA)*NO3PR*AN(JA)
      ENDIF
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))then
        NO3PR = 1.0-NH4(K,I)/(NH4(K,I)+NO3(K,I)+NONZERO)
        IF (ENEQN(JE).EQ.2)  NO3PR      = 1.0-(NH4(K,I)*NO3(K,I)/((ENPR(JE)+NH4(K,I))*(ENPR(JE)+NO3(K,I)))+NH4(K,I)*ENPR(JE)       &
                                          /((NO3(K,I)+NH4(K,I)+NONZERO)*(ENPR(JE)+NO3(K,I))))
        IF (EHSN(JE).GT.0.0) NO3EG(K,I) = NO3EG(K,I)+EGR(K,I,JE)*EPC(K,I,JE)*NO3PR*EN(JE)
        ENDIF
      END DO
      IF(K == KB(I)) THEN      ! SW 4/18/07
      NO3SED(K,I) = NO3(K,I)*NO3S(JW)*NO3TRM(K,I)*(BI(K,I))/BH2(K,I)
	  ELSE
      NO3SED(K,I) = NO3(K,I)*NO3S(JW)*NO3TRM(K,I)*(BI(K,I)-BI(K+1,I))/BH2(K,I)
	  ENDIF
      NO3SS(K,I)  = NH4D(K,I)-NO3D(K,I)-NO3AG(K,I)-NO3EG(K,I)-NO3SED(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  D I S S O L V E D   S I L I C A                                              **
!***********************************************************************************************************************************

ENTRY DISSOLVED_SILICA
  DSIAG(:,IU:ID) = 0.0; DSIEG(:,IU:ID) = 0.0                          !; DSIBOD = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
        DSIAG(K,I) = DSIAG(K,I)+AGR(K,I,JA)*ALG(K,I,JA)*ASI(JA)
      ENDIF
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))DSIEG(K,I) = DSIEG(K,I)+EGR(K,I,JE)*EPC(K,I,JE)*ESI(JE)
      END DO
      DSID(K,I)  =  PSIDK(JW)*PSI(K,I)
      DSISD(K,I) =  SEDD(K,I)*ORGSI(JW)
      DSISR(K,I) =  DSIR(JW)*SODD(K,I)*DO2(K,I)
      DSIS(K,I)  = (SSSI(K,I)*DSI(K-1,I)-SSSO(K,I)*DSI(K,I))*PARTSI(JW)
      DSISS(K,I) =  DSID(K,I)+DSISD(K,I)+DSISR(K,I)+DSIS(K,I)-DSIAG(K,I)-DSIEG(K,I)    !+DSIBOD
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                P A R T I C U L A T E   S I L I C A                                            **
!***********************************************************************************************************************************

ENTRY PARTICULATE_SILICA
  PSIAM(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
        PSIAM(K,I) = PSIAM(K,I)+AMR(K,I,JA)*PSI(K,I)*ASI(JA)
      ENDIF
      END DO
      PSID(K,I)  = PSIDK(JW)*PSI(K,I)
      PSINS(K,I) = PSIS(JW)*(PSI(K-1,I)*DO1(K-1,I)-PSI(K,I)*DO1(K,I))*BI(K,I)/BH2(K,I)
      PSISS(K,I) = PSIAM(K,I)-PSID(K,I)+PSINS(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                            I R O N                                                            **
!***********************************************************************************************************************************

ENTRY IRON
  DO I=IU,ID
    DO K=KT,KB(I)
      FENS(K,I) = FES(JW)*(FE(K-1,I)*DO1(K-1,I)-FE(K,I)*DO1(K,I))*BI(K,I)/BH2(K,I)
      FESR(K,I) = FER(JW)*SODD(K,I)*DO2(K,I)
      FESS(K,I) = FESR(K,I)+FENS(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                       L A B I L E   D O M                                                     **
!***********************************************************************************************************************************

ENTRY LABILE_DOM
  LDOMAP(:,IU:ID) = 0.0; LDOMEP(:,IU:ID) = 0.0; LDOMMAC(:,IU:ID)= 0.0  
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LDOMAP(K,I) = LDOMAP(K,I)+(AER(K,I,JA)+(1.0-APOM(JA))*AMR(K,I,JA))*ALG(K,I,JA)
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LDOMEP(K,I) = LDOMEP(K,I)+(EER(K,I,JE)+(1.0-EPOM(JE))*EMR(K,I,JE))*EPC(K,I,JE)
      END DO

      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            LDOMMAC(K,I)=LDOMMAC(K,I)+(1.0-MPOM(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)
          END DO
        END IF
      END DO
      LDOMMAC(K,I)=LDOMMAC(K,I)/(DLX(I)*BH(K,I))
      LDOMSS(K,I) = LDOMAP(K,I)+LDOMEP(K,I)-LDOMD(K,I)-LRDOMD(K,I)+LDOMMAC(K,I)

    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   D O M                                                  **
!***********************************************************************************************************************************

ENTRY REFRACTORY_DOM
  DO I=IU,ID
    DO K=KT,KB(I)
      RDOMSS(K,I) = LRDOMD(K,I)-RDOMD(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      L A B I L E   P O M                                                      **
!***********************************************************************************************************************************

ENTRY LABILE_POM
  LPOMAP(:,IU:ID) = 0.0; LPOMEP(:,IU:ID) = 0.0;   LPOMMAC(:,IU:ID) = 0.0; LPZOOIN(:,IU:ID)=0.0;LPZOOOUT(:,IU:ID)=0.0   ! cb 5/19/06
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LPOMAP(K,I) = LPOMAP(K,I)+APOM(JA)*(AMR(K,I,JA)*ALG(K,I,JA))
      END DO
      DO JE=1,NEP                                                          ! cb 5/19/06
        IF (EPIPHYTON_CALC(JW,JE))LPOMEP(K,I) = LPOMEP(K,I)+EPOM(JE)*(EMR(K,I,JE)*EPC(K,I,JE))       ! cb 5/19/06
      END DO                                                               ! cb 5/19/06
      LPOMNS(K,I) = POMS(JW)*(LPOM(K-1,I)-LPOM(K,I))*BI(K,I)/BH2(K,I)

      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            LPOMMAC(K,I)=LPOMMAC(K,I)+MPOM(M)*LRPMAC(M)*MMR(K,I,M)*MACRM(JJ,K,I,M)
          END DO
        END IF
      END DO
      LPOMMAC(K,I)=LPOMMAC(K,I)/(DLX(I)*BH(K,I))
      IF(ZOOPLANKTON_CALC)THEN
      DO JZ = 1,NZP
        IF(TGRAZE(K,I,JZ) > 0.0)THEN
          LPZOOOUT(K,I)=LPZOOOUT(K,I)+ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))
          LPZOOIN(K,I)=LPZOOIN(K,I)+ZOO(K,I,JZ)*PREFP(JZ)*ZMU(K,I,JZ)*LPOM(K,I)/TGRAZE(K,I,JZ)
        ELSE
          LPZOOOUT(K,I)=LPZOOOUT(K,I)+ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))
          LPZOOIN(K,I)=0.0
        END IF
      END DO
      ENDIF
      LPOMSS(K,I) = LPOMAP(K,I)+LPOMEP(K,I)-LPOMD(K,I)+LPOMNS(K,I)-LRPOMD(K,I)+LPOMMAC(K,I)+LPZOOOUT(K,I)-LPZOOIN(K,I)       ! cb 5/19/06
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   P O M                                                  **
!***********************************************************************************************************************************

ENTRY REFRACTORY_POM
  RPOMMAC(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      RPOMNS(K,I) = POMS(JW)*(RPOM(K-1,I)-RPOM(K,I))*BI(K,I)/BH2(K,I)
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            RPOMMAC(K,I)=RPOMMAC(K,I)+MPOM(M)*(1.0-LRPMAC(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)
          END DO
        END IF
      END DO
      RPOMMAC(K,I)=RPOMMAC(K,I)/(DLX(I)*BH(K,I))
      RPOMSS(K,I) = LRPOMD(K,I)+RPOMNS(K,I)-RPOMD(K,I)+RPOMMAC(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                         A L G A E                                                             **
!***********************************************************************************************************************************

ENTRY ALGAE (J)
  AGZT(:,IU:ID,J) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      IF(ZOOPLANKTON_CALC)THEN
      DO JZ = 1,NZP
	  AGZT(K,I,J) = AGZT(K,I,J) + AGZ(K,I,J,JZ)                       ! CB 5/26/07
	  END DO
	  ENDIF
      ASS(K,I,J) = ASR(K,I,J)+(AGR(K,I,J)-AER(K,I,J)-AMR(K,I,J)-ARR(K,I,J))*ALG(K,I,J)-AGZT(K,I,J)	
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                            B I O C H E M I C A L   O 2   D E M A N D                                          **
!***********************************************************************************************************************************

ENTRY BIOCHEMICAL_O2_DEMAND(JBOD)
  IF(JBOD == 1)CBODNS(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      CBODSET = CBODS(JBOD)*(CBOD(K-1,I,JBOD)-CBOD(K,I,JBOD))*BI(K,I)/BH2(K,I)
      CBODNS(K,I)=CBODNS(K,I)+CBODSET
      CBODSS(K,I,JBOD) = -CBODD(K,I,JBOD)*CBOD(K,I,JBOD)+CBODSET
    END DO
  END DO
RETURN

! VARIABLE STOCHIOMETRY FOR CBOD SECTION ! CB 6/6/10
!***********************************************************************************************************************************
!**                                            B I O C H E M I C A L   O 2   D E M A N D   P H O S P H O R U S                    **
!***********************************************************************************************************************************

ENTRY BIOCHEMICAL_O2_DEMAND_P(JBOD)
  IF(JBOD == 1)CBODNSP(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      CBODSET = CBODS(JBOD)*(CBODP(K-1,I,JBOD)-CBODP(K,I,JBOD))*BI(K,I)/BH2(K,I)
      CBODNSP(K,I)=CBODNSP(K,I)+CBODSET
      CBODPSS(K,I,JBOD) = -CBODD(K,I,JBOD)*CBODP(K,I,JBOD)+CBODSET
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                            B I O C H E M I C A L   O 2   D E M A N D   N I T R O G E N                        **
!***********************************************************************************************************************************

ENTRY BIOCHEMICAL_O2_DEMAND_N(JBOD)
  IF(JBOD == 1)CBODNSN(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      CBODSET = CBODS(JBOD)*(CBODN(K-1,I,JBOD)-CBODN(K,I,JBOD))*BI(K,I)/BH2(K,I)
      CBODNSN(K,I)=CBODNSN(K,I)+CBODSET
      CBODNSS(K,I,JBOD) = -CBODD(K,I,JBOD)*CBODN(K,I,JBOD)+CBODSET
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                D I S S O L V E D   O X Y G E N                                                **
!***********************************************************************************************************************************

ENTRY DISSOLVED_OXYGEN
  DOAP(:,IU:ID) = 0.0; DOAR(:,IU:ID) = 0.0; DOEP(:,IU:ID) = 0.0; DOER(:,IU:ID) = 0.0; DOBOD(:,IU:ID) = 0.0
  DOMP(:,IU:ID) = 0.0; DOMR(:,IU:ID) = 0.0; DOZR(:,IU:ID)=0.0   

  DO I=IU,ID
    DOSS(KT,I) = 0.0
    DO K=KT,KB(I)
      DO JCB=1,NBOD
        IF(BOD_CALC(JCB))DOBOD(K,I) = DOBOD(K,I)+RBOD(JCB)*CBODD(K,I,JCB)*CBOD(K,I,JCB)
      END DO
      DO JA=1,NAL
      IF(ALG_CALC(JA))THEN
        DOAP(K,I) = DOAP(K,I)+AGR(K,I,JA)*ALG(K,I,JA)*O2AG(JA)
        DOAR(K,I) = DOAR(K,I)+ARR(K,I,JA)*ALG(K,I,JA)*O2AR(JA)
      ENDIF
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))THEN
        DOEP(K,I) = DOEP(K,I)+EGR(K,I,JE)*EPC(K,I,JE)*O2EG(JE)
        DOER(K,I) = DOER(K,I)+ERR(K,I,JE)*EPC(K,I,JE)*O2ER(JE)
        ENDIF
      END DO

      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            DOMP(K,I)=DOMP(K,I)+MGR(JJ,K,I,M)*MACRM(JJ,K,I,M)*O2MG(M)
            DOMR(K,I)=DOMR(K,I)+MRR(K,I,M)*MACRM(JJ,K,I,M)*O2MR(M)
          END DO
        END IF
      END DO
      DOMP(K,I)=DOMP(K,I)/(DLX(I)*BH(K,I))
      DOMR(K,I)=DOMR(K,I)/(DLX(I)*BH(K,I))
      DOPOM(K,I) = (LPOMD(K,I)+RPOMD(K,I))*O2OM(JW)
      DODOM(K,I) = (LDOMD(K,I)+RDOMD(K,I))*O2OM(JW)
      DOOM(K,I)  =  DOPOM(K,I)+DODOM(K,I)+DOBOD(K,I)      
      DONIT(K,I) =  NH4D(K,I)*O2NH4(JW)
      DOSED(K,I) =  SEDD(K,I)*O2OM(JW)
      DOSOD(K,I) =  SODD(K,I)*DO3(K,I)
     IF(ZOOPLANKTON_CALC)THEN
     DO JZ = 1, NZP
      DOZR(K,I)  = DOZR(K,I)+ZRT(K,I,JZ)*ZOO(K,I,JZ)*O2ZR(JZ)
	 END DO
	 ENDIF
    DOSS(K,I)  =  DOAP(K,I)+DOEP(K,I)-DOAR(K,I)-DOER(K,I)-DOOM(K,I)-DONIT(K,I)-DOSOD(K,I)-DOSED(K,I)  &
                    +DOMP(K,I)-DOMR(K,I)-DOZR(K,I)
    END DO
    DOSAT = SATO(T1(KT,I),TDS(KT,I),PALT(I),SALT_WATER(JW))
    IF (.NOT. ICE(I)) THEN
      CALL GAS_TRANSFER
      O2EX       =  REAER(I)
      DOAE(KT,I) = (DOSAT-O2(KT,I))*O2EX*BI(KT,I)/BH2(KT,I)
      DOSS(KT,I) =  DOSS(KT,I)+DOAE(KT,I)
    END IF
  END DO
RETURN

!***********************************************************************************************************************************
!**                                              I N O R G A N I C   C A R B O N                                                  **
!***********************************************************************************************************************************

ENTRY INORGANIC_CARBON
  TICAP(:,IU:ID) = 0.0; TICEP(:,IU:ID) = 0.0; TICBOD(:,IU:ID) = 0.0
  ticmc(:,iu:id) = 0.0; ticzr(:,iu:id)=0.0  !v3.5
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JCB=1,NBOD
        IF(BOD_CALC(JCB))TICBOD(K,I) = TICBOD(K,I)+CBODD(K,I,JCB)*CBOD(K,I,JCB)*BODC(JCB)
      END DO
      DO JA=1,NAL
        IF(ALG_CALC(JA))TICAP(K,I) = TICAP(K,I)+AC(JA)*(ARR(K,I,JA)-AGR(K,I,JA))*ALG(K,I,JA)
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))TICEP(K,I) = TICEP(K,I)+EC(JE)*(ERR(K,I,JE)-EGR(K,I,JE))*EPC(K,I,JE)
      END DO
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            TICMC(K,I)=TICMC(K,I)+(MRR(K,I,M)-MGR(JJ,K,I,M))*MACRM(JJ,K,I,M)*MC(M)
          END DO
        END IF
      END DO
      TICMC(K,I)=TICMC(K,I)/(DLX(I)*BH(K,I))
      IF(ZOOPLANKTON_CALC)THEN
      DO JZ = 1,NZP
        TICZR(K,I)=TICZR(K,I)+ZRT(K,I,JZ)*ZOO(K,I,JZ)*ZC(JZ) !MLM
	  END DO
	  ENDIF
      TICSS(K,I) = TICAP(K,I)+TICEP(K,I)+SEDDC(K,I)+ORGC(JW)*(LPOMD(K,I)+RPOMD(K,I)+LDOMD(K,I)+RDOMD(K,I))                          &
                   +CO2R(JW)*SODD(K,I)*DO3(K,I)+TICBOD(K,I)+TICMC(K,I)+TICZR(K,I)      
    END DO
    IF (.NOT. ICE(I)) THEN
      IF (REAER(I) == 0.0) CALL GAS_TRANSFER
      CO2EX       = REAER(I)*0.923
      CO2REAER(KT,I)=CO2EX*(0.286*EXP(-0.0314*(T2(KT,I))*PALT(I))-CO2(KT,I))*BI(KT,I)/BH2(KT,I)
      TICSS(KT,I) = TICSS(KT,I)+CO2REAER(KT,I)
    END IF
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      S E D I M E N T                                                          **
!***********************************************************************************************************************************

ENTRY SEDIMENT
  SEDAS(:,IU:ID) = 0.0; LPOMEP(:,IU:ID) = 0.0; SEDCB(:,IU:ID) = 0.0
  DO I=IU,ID
    SEDSI=0.0
    DO K=KT,KB(I)
    IF(K == KB(I))THEN
    BIBH2(K,I)=BI(K,I)/BH2(K,I)
    ELSE
    BIBH2(K,I)=BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
    ENDIF
      DO JA=1,NAL
        IF(ALG_CALC(JA))SEDAS(K,I) = SEDAS(K,I)+MAX(AS(JA),0.0)*ALG(K,I,JA)*BIBH2(K,I)                !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      SEDEM = 0.0   ! CB 5/19/06
      DO JE=1,NEP
!        LPOMEP(K,I) = LPOMEP(K,I)+EPOM(JE)*(EMR(K,I,JE)*EPC(K,I,JE))
        IF (EPIPHYTON_CALC(JW,JE))SEDEM = SEDEM+EBR(K,I,JE)/H1(K,I)*EPC(K,I,JE)    ! cb 5/19/06
      END DO
      DO JD=1,NBOD
        IF(BOD_CALC(JD))SEDCB(K,I) = SEDCB(K,I)+MAX(CBODS(JD),0.0)*CBOD(K,I,JD)*BIBH2(K,I)/O2OM(JW)           !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      SEDOMS(K,I) = pomS(JW)*(LPOM(K,I)+RPOM(K,I))*BIBH2(K,I)                        !cb 10/22/06
      IF(K==KB(I))THEN
      SEDSO       = 0.0
      ELSE
      SEDSO       = SEDS(JW)*SED(K,I)*BI(K+1,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      ENDIF
      SEDNS(K,I)  = SEDSI-SEDSO
      SEDSI       = SEDSO
      SED(K,I)    = MAX(SED(K,I)+(SEDEM+SEDAS(K,I)+SEDCB(K,I)+SEDOMS(K,I)+SEDNS(K,I)-SEDD(K,I)-SEDBR(K,I))*DLT,0.0)   ! cb 11/30/06
    END DO
  END DO
RETURN


!***********************************************************************************************************************************
!**                                                      S E D I M E N T   P H O S P H O R U S                                    **
!***********************************************************************************************************************************

ENTRY SEDIMENTP
  SEDASP(:,IU:ID) = 0.0; LPOMEPP(:,IU:ID) = 0.0; SEDCBP(:,IU:ID) = 0.0
  DO I=IU,ID
    SEDSIP=0.0
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))SEDASP(K,I) = SEDASP(K,I)+MAX(AS(JA),0.0)*AP(JA)*ALG(K,I,JA)*BIBH2(K,I)          !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LPOMEPP(K,I) = LPOMEPP(K,I)+EPOM(JE)*EP(JE)*(EMR(K,I,JE)*EPC(K,I,JE))
      END DO
      DO JD=1,NBOD
!        IF(BOD_CALC(JD))SEDCBP(K,I)=SEDCBP(K,I)+MAX(CBODS(JD),0.0)*BODP(JD)*CBOD(K,I,JD)*BIBH2(K,I)      !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
        IF(BOD_CALC(JD))SEDCBP(K,I)=SEDCBP(K,I)+MAX(CBODS(JD),0.0)*CBODP(K,I,JD)*BIBH2(K,I)    ! CB 6/6/10
      END DO
      SEDOMSP(K,I) = POMS(JW)*(LPOMP(K,I)+RPOMP(K,I))*BIBH2(K,I)                         !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))  !CB 10/22/06
      IF(K == KB(I))THEN
      SEDSOP       = 0.0
      ELSE
      SEDSOP       = SEDS(JW)*SEDP(K,I)*BI(K+1,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      ENDIF
      SEDNSP(K,I)  = SEDSIP-SEDSOP
      SEDSIP       = SEDSOP
      SEDP(K,I)    = MAX(SEDP(K,I)+(LPOMEPP(K,I)+SEDASP(K,I)+SEDOMSP(K,I)+SEDCBP(K,I)+SEDNSP(K,I)-SEDDP(K,I)   &
                     -SEDBRP(K,I))*DLT,0.0)                                                                 !cb 11/30/06
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      S E D I M E N T   N I T R O G E N                                        **
!***********************************************************************************************************************************

ENTRY SEDIMENTN
  SEDASN(:,IU:ID) = 0.0; LPOMEPN(:,IU:ID) = 0.0; SEDCBN(:,IU:ID) = 0.0
  DO I=IU,ID
    SEDSIN=0.0
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))SEDASN(K,I) = SEDASN(K,I)+MAX(AS(JA),0.0)*AN(JA)*ALG(K,I,JA)*BIBH2(K,I)            !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LPOMEPN(K,I) = LPOMEPN(K,I)+EPOM(JE)*EN(JE)*(EMR(K,I,JE)*EPC(K,I,JE))
      END DO
      DO JD=1,NBOD
!        IF(BOD_CALC(JD))SEDCBN(K,I)=SEDCBN(K,I)+MAX(CBODS(JD),0.0)*BODN(JD)*CBOD(K,I,JD)*BIBH2(K,I)        !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
        IF(BOD_CALC(JD))SEDCBN(K,I)=SEDCBN(K,I)+MAX(CBODS(JD),0.0)*CBODN(K,I,JD)*BIBH2(K,I)    ! CB 6/6/10
      END DO
      SEDOMSN(K,I) = POMS(JW)*(LPOMN(K,I)+RPOMN(K,I))*BIBH2(K,I)                           !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))  !CB 10/22/06
      
      IF(K == KB(I)) THEN      ! SW 12/16/07
      SEDNO3(K,I)  = FNO3SED(JW)*NO3(K,I)*NO3S(JW)*NO3TRM(K,I)*(BI(K,I))/BH2(K,I)
      SEDSON       = 0.0
	  ELSE
      SEDNO3(K,I)  = FNO3SED(JW)*NO3(K,I)*NO3S(JW)*NO3TRM(K,I)*(BI(K,I)-BI(K+1,I))/BH2(K,I)
      SEDSON       = SEDS(JW)*SEDN(K,I)*BI(K+1,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
	  ENDIF
      SEDNSN(K,I)  = SEDSIN-SEDSON
      SEDSIN       = SEDSON
      SEDN(K,I)    = MAX(SEDN(K,I)+(LPOMEPN(K,I)+SEDASN(K,I)+SEDOMSN(K,I)+SEDCBN(K,I)+SEDNSN(K,I)+SEDNO3(K,I)   &
                     -SEDDN(K,I)-SEDBRN(K,I))*DLT,0.0)  !CB 11/30/06                    
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      S E D I M E N T   C A R B O N                                            **
!***********************************************************************************************************************************

ENTRY SEDIMENTC
  SEDASC(:,IU:ID) = 0.0; LPOMEPC(:,IU:ID) = 0.0; SEDCBC(:,IU:ID) = 0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      SEDSIP=0.0
      DO JA=1,NAL
        IF(ALG_CALC(JA))SEDASC(K,I) = SEDASC(K,I)+MAX(AS(JA),0.0)*AC(JA)*ALG(K,I,JA)*BIBH2(K,I)             !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LPOMEPC(K,I) = LPOMEPC(K,I)+EPOM(JE)*EC(JE)*(EMR(K,I,JE)*EPC(K,I,JE))
      END DO
      DO JD=1,NBOD
        IF(BOD_CALC(JD))SEDCBC(K,I)=SEDCBC(K,I)+MAX(CBODS(JD),0.0)*BODC(JD)*CBOD(K,I,JD)*BIBH2(K,I)         !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      END DO
      SEDOMSC(K,I) = POMS(JW)*ORGC(JW)*(LPOM(K,I)+RPOM(K,I))*BIBH2(K,I)                     !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))   !CB 10/22/06
      IF(K == KB(I))THEN
      SEDSOC       = 0.0
      ELSE
      SEDSOC       = SEDS(JW)*SEDC(K,I)*BI(K+1,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))
      ENDIF
      SEDNSC(K,I)  = SEDSIC-SEDSOC
      SEDSIC       = SEDSOC
      SEDC(K,I)    = MAX(SEDC(K,I)+(LPOMEPC(K,I)+SEDASC(K,I)+SEDOMSC(K,I)+SEDCBC(K,I)+SEDNSC(K,I)-SEDDC(K,I)    &
                     -SEDBRC(K,I))*DLT,0.0)                                                                   !CB 11/30/06
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      S E D I M E N T   D E C A Y    R A T E                                   **
!***********************************************************************************************************************************

ENTRY SEDIMENT_DECAY_RATE
  DO I=IU,ID
    SEDSIDK=0.0
    DO K=KT,KB(I)
      SEDSUM=0.0
      SEDSUMK=0.0
      
      DO JA=1,NAL
        IF(ALG_CALC(JA))THEN
        XDUM=MAX(AS(JA),0.0)*ALG(K,I,JA)*BIBH2(K,I)
        SEDSUMK = SEDSUMK + XDUM * LPOMDK(JW)    
        SEDSUM  = SEDSUM  + XDUM
        ENDIF
      END DO
      
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))THEN
        XDUM=EPOM(JE)*(EMR(K,I,JE)*EPC(K,I,JE))
        SEDSUMK = SEDSUMK + XDUM * LPOMDK(JW)
        SEDSUM  = SEDSUM  + XDUM
        ENDIF
      END DO
      
      DO JD=1,NBOD
        IF(BOD_CALC(JD))THEN
        XDUM=MAX(CBODS(JD),0.0)*CBOD(K,I,JD)*BIBH2(K,I)*RBOD(JD)/O2OM(JW)
        SEDSUMK = SEDSUMK+XDUM*CBODD(K,I,JD)               
        SEDSUM  = SEDSUM + XDUM
        ENDIF
      END DO
      
      SEDSUMK = SEDSUMK + POMS(JW)*(LPOM(K,I)*LPOMDK(JW)+RPOM(K,I)*RPOMDK(JW))*BIBH2(K,I)        !BI(K,I)/BH2(K,I)*(1.0-BI(K+1,I)/BI(K,I))  ! CB 10/22/06
      SEDSUM  = SEDSUM  + POMS(JW)*(LPOM(K,I)+RPOM(K,I))*BIBH2(K,I)
      
      SEDSUMK = SEDSUMK*DLT
      SEDSUM  = SEDSUM*DLT  
    
      IF((SEDSUM+SED(K,I)) > 0.0)THEN
      SDKV(K,I)    = (SEDSUMK+SED(K,I) * SDKV(K,I))/(SEDSUM+ SED(K,I))
      ELSE
      SDKV(K,I)=0.0
      ENDIF
            
    END DO
  END DO
RETURN


!***********************************************************************************************************************************
!*                                                         E P I P H Y T O N                                                      **
!***********************************************************************************************************************************

ENTRY EPIPHYTON (J)
  DO I=IU,ID

!** Limiting factor

    LIGHT = (1.0-BETA(JW))*SRON(JW)*SHADE(I)/ESAT(J)
    LAM2  =  LIGHT
    LAM1  =  LIGHT
    DO K=KT,KB(I)

!**** Limiting factor

      LAM1          = LAM2
      LAM2          = LAM1*EXP(-GAMMA(K,I)*H1(K,I))
      FDPO4         = 1.0-FPSS(K,I)-FPFE(K,I)
      ELLIM(K,I,J)  = 2.718282*(EXP(-LAM2)-EXP(-LAM1))/(GAMMA(K,I)*H1(K,I))
      IF (EHSP(J)  /= 0.0) EPLIM(K,I,J) =  FDPO4*PO4(K,I)/(FDPO4*PO4(K,I)+EHSP(J)+NONZERO)
      IF (EHSN(J)  /= 0.0) ENLIM(K,I,J) = (NH4(K,I)+NO3(K,I))/(NH4(K,I)+NO3(K,I)+EHSN(J)+NONZERO)
      IF (EHSSI(J) /= 0.0) ESLIM(K,I,J) =  DSI(K,I)/(DSI(K,I)+EHSSI(J)+NONZERO)
      LIMIT         =  MIN(EPLIM(K,I,J),ENLIM(K,I,J),ESLIM(K,I,J),ELLIM(K,I,J))
      BLIM          =  1.0-EPD(K,I,J)/(EPD(K,I,J)+EHS(J))

!**** Sources/sinks

      EGR(K,I,J) =  MIN(ETRM(K,I,J)*EG(J)*LIMIT*BLIM,PO4(K,I)/(EP(J)*DLT*EPD(K,I,J)/H1(KT,I)+NONZERO),(NH4(K,I)+NO3(K,I))/(EN(J)   &
                    *DLT*EPD(K,I,J)/H1(K,I)+NONZERO))
      ERR(K,I,J) =  ETRM(K,I,J)*ER(J)*DO3(K,I)
      EMR(K,I,J) = (ETRMR(K,I,J)+1.0-ETRMF(K,I,J))*EM(J)
      EER(K,I,J) =  MIN((1.0-ELLIM(K,I,J))*EE(J)*ETRM(K,I,J),EGR(K,I,J))
!      EPD(K,I,J) =  MAX(EPD(K,I,J)+EPD(K,I,J)*(EGR(K,I,J)-ERR(K,I,J)-EMR(K,I,J)-EER(K,I,J)-EBR(K,I,J)/(H1(K,I)*0.0025))*DLT,0.0)
      EPD(K,I,J) =  MAX(EPD(K,I,J)+EPD(K,I,J)*(EGR(K,I,J)-ERR(K,I,J)-EMR(K,I,J)-EER(K,I,J)-EBR(K,I,J)/H1(K,I))*DLT,0.00)   ! cb 5/18/06
      if(k == kb(i)) then      ! SW 12/16/07
      EPM(K,I,J) =  EPD(K,I,J)*(BI(K,I)+2.0*H1(K,I))*DLX(I)
	  else
      EPM(K,I,J) =  EPD(K,I,J)*(BI(K,I)-BI(K+1,I)+2.0*H1(K,I))*DLX(I)
	  endif
      EPC(K,I,J) =  EPM(K,I,J)/VOL(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                       L A B I L E   D O M   P H O S P H O R U S                               **
!***********************************************************************************************************************************

ENTRY LABILE_DOM_P
  LDOMPAP(:,IU:ID) = 0.0; LDOMPEP(:,IU:ID) = 0.0; LDOMPMP(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LDOMPAP(K,I) = LDOMPAP(K,I)+(AER(K,I,JA)+(1.0-APOM(JA))*AMR(K,I,JA))*ALG(K,I,JA)*AP(JA)
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LDOMPEP(K,I) = LDOMPEP(K,I)+(EER(K,I,JE)+(1.0-EPOM(JE))*EMR(K,I,JE))*EPC(K,I,JE)*EP(JE)
      END DO
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            LDOMPMP(K,I)=LDOMPMP(K,I)+(1.0-MPOM(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)*MP(M)
          END DO
        END IF
      END DO
      LDOMPMP(K,I)=LDOMPMP(K,I)/(DLX(I)*BH(K,I))
      LDOMPSS(K,I) = LDOMPAP(K,I)+LDOMPEP(K,I)+LDOMPMP(K,I)-(LDOMD(K,I)+LRDOMD(K,I))*ORGPLD(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   D O M   P H O S P H O R U S                            **
!***********************************************************************************************************************************

ENTRY REFRACTORY_DOM_P
  DO I=IU,ID
    DO K=KT,KB(I)
      RDOMPSS(K,I) = LRDOMD(K,I)*ORGPLD(K,I)-RDOMD(K,I)*ORGPRD(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      L A B I L E   P O M   P H O S P H O R U S                                **
!***********************************************************************************************************************************

ENTRY LABILE_POM_P
  LPOMPAP(:,IU:ID) = 0.0;LPOMPMP(:,IU:ID)=0.0;LPZOOINP(:,IU:ID)=0.0; LPZOOOUTP(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LPOMPAP(K,I) = LPOMPAP(K,I)+APOM(JA)*(AMR(K,I,JA)*ALG(K,I,JA))*AP(JA)
      END DO
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            LPOMPMP(K,I)=LPOMPMP(K,I)+MPOM(M)*LRPMAC(M)*MMR(K,I,M)*MACRM(JJ,K,I,M)*MP(M)
          END DO
        END IF
      END DO
      LPOMPMP(K,I)=LPOMPMP(K,I)/(DLX(I)*BH(K,I))
	IF(ZOOPLANKTON_CALC)THEN
	DO JZ = 1,NZP
      IF(TGRAZE(K,I,JZ) > 0.0)THEN
        LPZOOOUTP(K,I)=LPZOOOUTP(K,I) + ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))*ZP(JZ)
        LPZOOINP(K,I)=LPZOOINP(K,I) + ZOO(K,I,JZ)*ZMU(K,I,JZ)*PREFP(JZ)*LPOM(K,I)/TGRAZE(K,I,JZ)*ZP(JZ)
      ELSE
        LPZOOOUTP(K,I)=LPZOOOUTP(K,I)+ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))*ZP(JZ)
        LPZOOINP(K,I)=0.0
      END IF
    END DO
    ENDIF
      LPOMPNS(K,I) = POMS(JW)*(LPOM(K-1,I)*ORGPLP(K-1,I)-LPOM(K,I)*ORGPLP(K,I))*BI(K,I)/BH2(K,I)
      LPOMPSS(K,I) = LPOMPAP(K,I)+LPOMPMP(K,I)-LPOMD(K,I)*ORGPLP(K,I)+LPOMPNS(K,I)-LRPOMD(K,I)*ORGPLP(K,I)
	  IF(ZOOPLANKTON_CALC)THEN
	!  DO JZ = 1,NZP                                           ! KV 4/24/12
	   LPOMPSS(K,I) =LPOMPSS(K,I) + LPZOOOUTP(K,I)-LPZOOINP(K,I)
	!  END DO                                                  ! KV 4/24/12
	  ENDIF

	END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   P O M   P H O S P H O R U S                            **
!***********************************************************************************************************************************

ENTRY REFRACTORY_POM_P
  RPOMPMP(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            RPOMPMP(K,I)=RPOMPMP(K,I)+MPOM(M)*(1.0-LRPMAC(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)*MP(M)
          END DO
        END IF
      END DO
      RPOMPMP(K,I)=RPOMPMP(K,I)/(DLX(I)*BH(K,I))
      RPOMPNS(K,I) = POMS(JW)*(RPOM(K-1,I)*ORGPRP(K-1,I)-RPOM(K,I)*ORGPRP(K,I))*BI(K,I)/BH2(K,I)
      RPOMPSS(K,I) = LRPOMD(K,I)*ORGPLP(K,I)+RPOMPNS(K,I)-RPOMD(K,I)*ORGPRP(K,I)+RPOMPMP(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                       L A B I L E   D O M   N I T R O G E N                                   **
!***********************************************************************************************************************************

ENTRY LABILE_DOM_N
  LDOMNAP(:,IU:ID) = 0.0; LDOMNEP(:,IU:ID) = 0.0; LDOMNMP(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LDOMNAP(K,I) = LDOMNAP(K,I)+(AER(K,I,JA)+(1.0-APOM(JA))*AMR(K,I,JA))*ALG(K,I,JA)*AN(JA)
      END DO
      DO JE=1,NEP
        IF (EPIPHYTON_CALC(JW,JE))LDOMNEP(K,I) = LDOMNEP(K,I)+(EER(K,I,JE)+(1.0-EPOM(JE))*EMR(K,I,JE))*EPC(K,I,JE)*EN(JE)
      END DO
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          IF(K.EQ.KT)THEN
            JT=KTI(I)
          ELSE
            JT=K
          END IF
          JE=KB(I)
          DO JJ=JT,JE
            LDOMNMP(K,I)=LDOMNMP(K,I)+(1.0-MPOM(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)*MN(M)
          END DO
        END IF
      END DO
      LDOMNMP(K,I)=LDOMNMP(K,I)/(DLX(I)*BH(K,I))
      LDOMNSS(K,I) = LDOMNAP(K,I)+LDOMNEP(K,I)+LDOMNMP(K,I)-(LDOMD(K,I)+LRDOMD(K,I))*ORGNLD(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   D O M   N I T R O G E N                                **
!***********************************************************************************************************************************

ENTRY REFRACTORY_DOM_N
  DO I=IU,ID
    DO K=KT,KB(I)
      RDOMNSS(K,I) = LRDOMD(K,I)*ORGNLD(K,I)-RDOMD(K,I)*ORGNRD(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                      L A B I L E   P O M   N I T R O G E N                                    **
!***********************************************************************************************************************************

ENTRY LABILE_POM_N
  LPOMNAP(:,IU:ID) = 0.0;LPOMNMP(:,IU:ID)=0.0;LPZOOINN(:,IU:ID)=0.0; LPZOOOUTN(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO JA=1,NAL
        IF(ALG_CALC(JA))LPOMNAP(K,I) = LPOMNAP(K,I)+APOM(JA)*(AMR(K,I,JA)*ALG(K,I,JA))*AN(JA)
      END DO
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            LPOMNMP(K,I)=LPOMNMP(K,I)+MPOM(M)*LRPMAC(M)*MMR(K,I,M)*MACRM(JJ,K,I,M)*MN(M)
          END DO
        END IF
      END DO
      LPOMNMP(K,I)=LPOMNMP(K,I)/(DLX(I)*BH(K,I))
	IF(ZOOPLANKTON_CALC)THEN
	DO JZ = 1,NZP
      IF(TGRAZE(K,I,JZ) > 0.0)THEN
        LPZOOOUTN(K,I)=LPZOOOUTN(K,I)+ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))*ZN(JZ)
        LPZOOINN(K,I)=LPZOOINN(K,I)+ZOO(K,I,JZ)*PREFP(JZ)*ZMU(K,I,JZ)*LPOM(K,I)/TGRAZE(K,I,JZ)*ZN(JZ)
      ELSE
        LPZOOOUTN(K,I)=LPZOOOUTN(K,I)+ZOO(K,I,JZ)*(ZMT(K,I,JZ)+(ZMU(K,I,JZ)-(ZMU(K,I,JZ)*ZEFF(JZ))))*ZN(JZ)
        LPZOOINN(K,I)=0.0
      END IF
	END DO
	ENDIF
      LPOMNNS(K,I) = POMS(JW)*(LPOM(K-1,I)*ORGNLP(K-1,I)-LPOM(K,I)*ORGNLP(K,I))*BI(K,I)/BH2(K,I)
      LPOMNSS(K,I) = LPOMNAP(K,I)+LPOMNMP(K,I)-LPOMD(K,I)*ORGNLP(K,I)+LPOMNNS(K,I)-LRPOMD(K,I)*ORGNLP(K,I) &
            + LPZOOOUTN(K,I)-LPZOOINN(K,I)
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                  R E F R A C T O R Y   P O M   N I T R O G E N                                **
!***********************************************************************************************************************************

ENTRY REFRACTORY_POM_N
  RPOMNMP(:,IU:ID)=0.0
  DO I=IU,ID
    DO K=KT,KB(I)
      DO M=1,NMC
        IF(MACROPHYTE_CALC(JW,M))THEN
          JT=K
          JE=KB(I)
          DO JJ=JT,JE
            RPOMNMP(K,I)=RPOMNMP(K,I)+MPOM(M)*(1.0-LRPMAC(M))*MMR(K,I,M)*MACRM(JJ,K,I,M)*MN(M)
          END DO
        END IF
      END DO
      RPOMNMP(K,I)=RPOMNMP(K,I)/(DLX(I)*BH(K,I))
      RPOMNNS(K,I) = POMS(JW)*(RPOM(K-1,I)*ORGNRP(K-1,I)-RPOM(K,I)*ORGNRP(K,I))*BI(K,I)/BH2(K,I)
      RPOMNSS(K,I) = LRPOMD(K,I)*ORGNLP(K,I)+RPOMNNS(K,I)-RPOMD(K,I)*ORGNRP(K,I)+RPOMNMP(K,I)
    END DO
  END DO
RETURN


!************************************************************************
!**                          M A C R O P H Y T E                       **
!************************************************************************

ENTRY MACROPHYTE(LLM)
  M=LLM
  DO I=IU,ID
    IF(KTICOL(I))THEN
      JT=KTI(I)
    ELSE
      JT=KTI(I)+1
    END IF
    JE=KB(I)
    DO JJ=JT,JE
      IF(JJ.LT.KT)THEN
        COLB=EL(JJ+1,I)
      ELSE
        COLB=EL(KT+1,I)
      END IF
      COLDEP=ELWS(I)-COLB
      IF(MACRC(JJ,KT,I,M).GT.MMAX(M))THEN
        MGR(JJ,KT,I,M)=0.0
      END IF
      MACSS(JJ,KT,I,M) = (MGR(JJ,KT,I,M)-MMR(KT,I,M)-MRR(KT,I,M))*MACRC(JJ,KT,I,M)
      MACRM(JJ,KT,I,M)   = MACRM(JJ,KT,I,M)+MACSS(JJ,KT,I,M)*DLT*COLDEP*CW(JJ,I)*DLX(I)
    END DO

    DO K=KT+1,KB(I)
      JT=K
      JE=KB(I)
      DO JJ=JT,JE
        IF(MACRC(JJ,K,I,M).GT.MMAX(M))THEN
          MGR(JJ,K,I,M)=0.0
        END IF
        MACSS(JJ,K,I,M) = (MGR(JJ,K,I,M)-MMR(K,I,M)-MRR(K,I,M))*MACRC(JJ,K,I,M)
        IF(MACT(JJ,K,I).GT.MBMP(M).AND.MACT(JJ,K-1,I).LT.MBMP(M).AND.MACSS(JJ,K,I,M).GT.0.0)THEN
          IF(K-1.EQ.KT)THEN
            BMASS=MACSS(JJ,K,I,M)*DLT*H2(K,I)*CW(JJ,I)*DLX(I)
            MACRM(JJ,K-1,I,M)=MACRM(JJ,K-1,I,M)+BMASS
            COLB=EL(KT+1,I)
            COLDEP=ELWS(I)-COLB
            MACSS(JJ,K-1,I,M)=BMASS/DLT/(COLDEP*CW(JJ,I)*DLX(I)) + MACSS(JJ,K-1,I,M)
          ELSE
            BMASS=MACSS(JJ,K,I,M)*DLT*H2(K,I)*CW(JJ,I)*DLX(I)
            MACRM(JJ,K-1,I,M)=MACRM(JJ,K-1,I,M)+BMASS
            MACSS(JJ,K-1,I,M)=BMASS/DLT/(H2(K-1,I)*CW(JJ,I)*DLX(I))+ MACSS(JJ,K-1,I,M)
          END IF
          MACSS(JJ,K,I,M)=0.0
        ELSE
          BMASSTEST=MACRM(JJ,K,I,M)+MACSS(JJ,K,I,M)*DLT*H2(K,I)*CW(JJ,I)*DLX(I)
          IF(BMASSTEST.GE.0.0)THEN
            MACRM(JJ,K,I,M)   = BMASSTEST
          ELSE
            MACSS(JJ,K,I,M)=-MACRM(JJ,K,I,M)/DLT/(H2(K,I)*CW(JJ,I)*DLX(I))
            MACRM(JJ,K,I,M)=0.0
          END IF
        END IF
      END DO
    END DO
  END DO
  DO I=IU,ID
    TMAC=0.0
    CVOL=0.0
    IF(KTICOL(I))THEN
      JT=KTI(I)
    ELSE
      JT=KTI(I)+1
    END IF
    JE=KB(I)

    DO JJ=JT,JE
      IF(JJ.LT.KT)THEN
        COLB=EL(JJ+1,I)
      ELSE
        COLB=EL(KT+1,I)
      END IF
      COLDEP=ELWS(I)-COLB
      IF(CW(JJ,I).GT.0.0)THEN
        MACRC(JJ,KT,I,M)=MACRM(JJ,KT,I,M)/(CW(JJ,I)*COLDEP*DLX(I))
      ELSE
        MACRC(JJ,KT,I,M)=0.0
      END IF
      TMAC=TMAC+MACRM(JJ,KT,I,M)
      CVOL=CVOL+CW(JJ,I)*COLDEP*DLX(I)
    END DO

    MAC(KT,I,M)=TMAC/CVOL

    DO K=KT+1,KB(I)
      JT=K
      JE=KB(I)
      TMAC=0.0
      CVOL=0.0
      DO JJ=JT,JE
        IF(CW(JJ,I).GT.0.0)THEN
          MACRC(JJ,K,I,M)=MACRM(JJ,K,I,M)/(CW(JJ,I)*H2(K,I)*DLX(I))
        ELSE
          MACRC(JJ,K,I,M)=0.0
        END IF
        TMAC=TMAC+MACRM(JJ,K,I,M)
        CVOL=CVOL+CW(JJ,I)*H2(K,I)*DLX(I)
      END DO
      MAC(K,I,M)=TMAC/CVOL
    END DO
  END DO

  DO I=IU,ID
    TMAC=0.0
    CVOL=0.0
    DO K=KT,KB(I)
      IF(K.EQ.KT)THEN
        JT=KTI(I)
      ELSE
        JT=K
      END IF
      JE=KB(I)
      DO JJ=JT,JE
        MACT(JJ,K,I)=0.0
        DO MI=1,NMC
          IF(MACROPHYTE_CALC(JW,MI))THEN
            MACT(JJ,K,I)=MACRC(JJ,K,I,MI)+MACT(JJ,K,I)
          END IF
        END DO
      END DO
    END DO
  END DO
  RETURN

!***********************************************************************************************************************************
!*                                                  K I N E T I C   F L U X E S                                                   **
!***********************************************************************************************************************************

ENTRY KINETIC_FLUXES
  DO JAF=1,NAF(JW)
    DO I=CUS(BS(JW)),DS(BE(JW))
      DO K=KT,KB(I)
        KFS(K,I,KFCN(JAF,JW)) = KFS(K,I,KFCN(JAF,JW))+KF(K,I,KFCN(JAF,JW))*VOL(K,I)*DLT
      END DO
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                                       p H   C O 2                                                             **
!***********************************************************************************************************************************

ENTRY PH_CO2

! pH and carbonate species

  DO I=IU,ID
    DO K=KT,KB(I)
      CART = TIC(K,I)/12000.0                ! CART=equivalents/liter of C    TIC=mg/l C (MW=12g/mole)
      ALKT = ALK(K,I)/5.0E+04                ! ALK=mg/l as CaCO3 (MW=50 g/mole; EQ=50g/eq))      ALKT=equivalents/l
      T1K  = T1(K,I)+273.15

!**** Ionic strength

      IF (FRESH_WATER(JW)) S2 = 2.5E-05*TDS(K,I)
      IF (SALT_WATER(JW))  S2 = 1.47E-3+1.9885E-2*TDS(K,I)+3.8E-5*TDS(K,I)*TDS(K,I)

!**** Debye-Huckel terms and activity coefficients

      SQRS2  =  SQRT(S2)
      DH1    = -0.5085*SQRS2/(1.0+1.3124*SQRS2)+4.745694E-03+4.160762E-02*S2-9.284843E-03*S2*S2
      DH2    = -2.0340*SQRS2/(1.0+1.4765*SQRS2)+1.205665E-02+9.715745E-02*S2-2.067746E-02*S2*S2
      H2CO3T =  10.0**(0.0755*S2)
      HCO3T  =  10.0**DH1
      CO3T   =  10.0**DH2
      OH     =  HCO3T

!**** Temperature adjustment

      KW = 10.0**(-283.971-0.05069842*T1K+13323.0/T1K+102.24447*LOG10(T1K)-1119669.0/(T1K*T1K))/OH
      K1 = 10.0**(-3404.71/T1K+14.8435-0.032786*T1K)*H2CO3T/HCO3T
      K2 = 10.0**(-2902.39/T1K+ 6.4980-0.023790*T1K)*HCO3T/CO3T

!**** pH evaluation

      PHT = -PH(K,I)-2.1
      IF (PH(K,I) <= 0.0) PHT = -14.0
      INCR = 10.0
      DO N=1,3
        F    = 1.0
        INCR = INCR/10.0
        ITER = 0
        DO WHILE (F > 0.0 .AND. ITER < 12)
          PHT    = PHT+INCR
          HION   = 10.0**PHT
          BICART = CART*K1*HION/(K1*HION+K1*K2+HION*HION)
          F      = BICART*(HION+2.0*K2)/HION+KW/HION-ALKT-HION/OH
          ITER   = ITER+1
        END DO
        PHT = PHT-INCR
      END DO

!**** pH, carbon dioxide, bicarbonate, and carbonate concentrations

      HION      =  10.0**PHT
      PH(K,I)   = -PHT
      CO2(K,I)  =  TIC(K,I)/(1.0+K1/HION+K1*K2/(HION*HION))          ! mg/l as C
      HCO3(K,I) =  TIC(K,I)/(1.0+HION/K1+K2/HION)                    ! mg/l as C
      CO3(K,I)  =  TIC(K,I)/((HION*HION)/(K1*K2)+HION/K2+1.0)        ! mg/l as C
    END DO
  END DO
RETURN

!**********************************************************
!**           SUBROUTINE ZOOPLANKTON                     **
!**********************************************************

ENTRY ZOOPLANKTON
  DO I=IU,ID
    DO K=KT,KB(I)
	  DO JZ = 1, NZP
            ZGZTOT=0.0                                                                                                   ! KV 5/9/2007
	        DO JJZ = 1,NZP
!             ZGZTOT=ZGZTOT+ZGZ(K,I,JZ,JJZ)*ZOO(K,I,JZ)                                                                   ! KV 5/9/2007
            ZGZTOT=ZGZTOT+ZGZ(K,I,JZ,JJZ)                                                                             ! CB 5/26/07
            END DO
        ZOOSS(K,I,JZ)= (ZMU(K,I,JZ)*ZEFF(JZ)-ZRT(K,I,JZ)-ZMT(K,I,JZ))*ZOO(K,I,JZ) - ZGZTOT   ! OMNIVOROUS ZOOPLANKTON    ! KV 5/9/2007
	  END DO
    END DO
  END DO
RETURN

!***********************************************************************************************************************************
!**                                              D E R I V E D   C O N S T I T U E N T S                                          **
!***********************************************************************************************************************************

ENTRY DERIVED_CONSTITUENTS
  APR = 0.0; ATOT = 0.0; TOTSS = 0.0; CHLA = 0.0; CBODU=0.0; DCELL = 0.0; CCELL=0.0; GCELL=0.0    ! CSW 1/3/17
  DO JW=1,NWB
    KT = KTWB(JW)
    DO JB=BS(JW),BE(JW)
      DO I=CUS(JB),DS(JB)
        DO K=KT,KB(I)
          DO JA=1,NAL
            IF(ALG_CALC(JA))APR(K,I) = APR(K,I)+(AGR(K,I,JA)-ARR(K,I,JA))*ALG(K,I,JA)*H2(K,I)*DAY
          END DO
        END DO
        DO K=KT,KB(I)
          CBODCT = 0.0; CBODNT = 0.0; CBODPT = 0.0; BODTOT = 0.0; ALGP = 0.0; ALGN = 0.0  ! cb 6/6/10
          DO JA=1,NAL
            IF(ALG_CALC(JA))ATOT(K,I) = ATOT(K,I)+ALG(K,I,JA)
          END DO
          DO IBOD=1,NBOD
          IF(BOD_CALC(IBOD))THEN      
            CBODCt  = CBODCt+CBOD(K,I,IBOD)*BODC(IBOD)    ! cb 6/6/10
            CBODNt  = CBODNt+CBODn(K,I,IBOD)              ! cb 6/6/10
            CBODPt  = CBODPt+CBODp(K,I,IBOD)              ! cb 6/6/10
            BODTOT = BODTOT+CBOD(K,I,IBOD)
            IF(CBODS(IBOD)>0.0)TOTSS(K,I) = TOTSS(K,I)+CBOD(K,I,IBOD)/O2OM(JW)               ! SW 9/5/13  Added particulate CBOD to TSS computation
          ENDIF
          END DO
          DOM(K,I) = LDOM(K,I)+RDOM(K,I)
          POM(K,I) = LPOM(K,I)+RPOM(K,I)
          DOC(K,I) = DOM(K,I)*ORGC(JW)+CBODCt             ! cb 6/6/10
          POC(K,I) = POM(K,I)*ORGC(JW)
          DO JA=1,NAL
          IF(ALG_CALC(JA))THEN
            POC(K,I) = POC(K,I)+ALG(K,I,JA)*AC(JA)
            ALGP     = ALGP+ALG(K,I,JA)*AP(JA)
            ALGN     = ALGN+ALG(K,I,JA)*AN(JA)
          ENDIF
          END DO
          IF(ZOOPLANKTON_CALC)THEN
            DO JZ=1,NZP
                POC(K,I)=POC(K,I)+ZC(JZ)*ZOO(K,I,JZ) !MLM BAULK
                ZOOP=ZOO(K,I,JZ)*ZP(JZ) !MLM BAULK
                ZOON=ZOO(K,I,JZ)*ZN(JZ) !MLM BAULK
                CBODU(K,I) = CBODU(K,I) + O2OM(JW)*ZOO(K,I,JZ)
                TOTSS(K,I) = TOTSS(K,I)+ZOO(K,I,JZ)               ! SW 9/5/13  Added zooplankton to TSS computation
	        END DO
	      ENDIF
          TOC(K,I)   = DOC(K,I)+POC(K,I)
          DOP(K,I)   = LDOM(K,I)*ORGPLD(K,I)+RDOM(K,I)*ORGPRD(K,I)+CBODPT    ! CB 6/6/10
          DON(K,I)   = LDOM(K,I)*ORGNLD(K,I)+RDOM(K,I)*ORGNRD(K,I)+CBODNT    ! CB 6/6/10
          POP(K,I)   = LPOM(K,I)*ORGPLP(K,I)+RPOM(K,I)*ORGPRP(K,I)+ALGP+ZOOP
          PON(K,I)   = LPOM(K,I)*ORGNLP(K,I)+RPOM(K,I)*ORGNRP(K,I)+ALGN+ZOOP
          TOP(K,I)   = DOP(K,I)+POP(K,I)
          TON(K,I)   = DON(K,I)+PON(K,I)
          TKN(K,I)   = TON(K,I)+NH4(K,I)
          CBODU(K,I) = CBODU(K,I)+O2OM(JW)*(DOM(K,I)+POM(K,I)+ATOT(K,I))+BODTOT
          TPSS       = 0.0
          DO JS=1,NSS
            TPSS = TPSS+SS(K,I,JS)*PARTP(JW)
          END DO
          TP(K,I)   =  TOP(K,I)+PO4(K,I)+TPSS
          TN(K,I)   =  TON(K,I)+NH4(K,I)+NO3(K,I)
          O2DG(K,I) = (O2(K,I)/SATO(T1(K,I),TDS(K,I),PALT(I),SALT_WATER(JW)))*100.0
          DO JA=1,NAL
          IF(ALG_CALC(JA))THEN
            CHLA(K,I)  = CHLA(K,I) +ALG(K,I,JA)/ACHLA(JA)
            TOTSS(K,I) = TOTSS(K,I)+ALG(K,I,JA)
            IF(JA .EQ. 1)THEN
               DCELL(K,I) = DCELL(K,I)+ALG(K,I,JA)/(ACHLA(JA)*CACEL(JA))*1000.0       ! CSW 1/3/17
            ELSE IF(JA .EQ. 2)THEN   
              CCELL(K,I) = CCELL(K,I)+ALG(K,I,JA)/(ACHLA(JA)*CACEL(JA))*1000.0       ! CSW 1/3/17
            ELSE IF(JA .EQ. 3)THEN 
              GCELL(K,I) = GCELL(K,I)+ALG(K,I,JA)/(ACHLA(JA)*CACEL(JA))*1000.0       ! CSW 1/3/17     
            END IF  
          ENDIF
          END DO
          TOTSS(K,I) = TOTSS(K,I)+TISS(K,I)+POM(K,I)
        END DO
      END DO
    END DO
  END DO
RETURN
ENTRY DEALLOCATE_KINETICS
  DEALLOCATE (OMTRM,  SODTRM, NH4TRM, NO3TRM, DOM, POM, PO4BOD, NH4BOD, TICBOD, ATRM,   ATRMR,  ATRMF, ETRM,   ETRMR,  ETRMF, BIBH2)
  DEALLOCATE (LAM2M)
RETURN
END SUBROUTINE KINETICS
