      MODULE BUILDVERSION   ! SW 3/17/2015
      INTEGER :: INTEL_COMPILER_VERSION= __INTEL_COMPILER
      INTEGER :: INTEL_COMPILER_BUILD_DATE=__INTEL_COMPILER_BUILD_DATE
      CHARACTER(20) :: compiler_build_date=__DATE__
      CHARACTER(20) :: COMPILER_BUILD_TIME=__TIME__
      CHARACTER(40) :: BUILDTIME=__DATE__//' '//__TIME__    ! 3.72
      END MODULE BUILDVERSION