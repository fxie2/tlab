PROGRAM SMOOTH

#include "types.h"
#include "dns_const.h"

  USE DNS_GLOBAL
  USE THERMO_GLOBAL

  IMPLICIT NONE

#include "integers.h"

  TREAL qt_min, qt_max, qt_del, qt, qsat, dqldqt
  TREAL z1(2), e, rho, p, T, h
  TINTEGER opt

! ###################################################################
  CALL DNS_INITIALIZE

  imixture = MIXT_TYPE_AIRWATER
  CALL THERMO_INITIALIZE
  MRATIO = C_1_R

  WRITE(*,*) 'Case d-e (1) or d-p (2) or p-h (3) ?'
  READ(*,*) opt 

  WRITE(*,*) 'Minimum qt ?'
  READ(*,*) qt_min
  WRITE(*,*) 'Maximum qt ?'
  READ(*,*) qt_max
  WRITE(*,*) 'Increment qt ?'
  READ(*,*) qt_del

  IF ( opt .EQ. 1 ) THEN
     WRITE(*,*) 'Density value ?'
     READ(*,*) rho
     WRITE(*,*) 'Energy value ?'
     READ(*,*) e
  ELSE IF ( opt .EQ. 2 ) THEN
     WRITE(*,*) 'Density value ?'
     READ(*,*) rho
     WRITE(*,*) 'Pressure value ?'
     READ(*,*) p
  ELSE IF ( opt .EQ. 3 ) THEN
     WRITE(*,*) 'Pressure value ?'
     READ(*,*) p
     WRITE(*,*) 'Enthalpy value ?'
     READ(*,*) h
  ENDIF

  WRITE(*,*) 'Smoothing factor ?'
  READ(*,*) dsmooth

! ###################################################################
  OPEN(21,file='vapor.dat')
  WRITE(21,*) '# qt, ql, qv, qsat(T), r, T, p, e, h'

  qt = qt_min
  DO WHILE ( qt .LE. qt_max ) 

     z1(1) = qt
     IF ( opt .EQ. 1 ) THEN
        CALL THERMO_CALORIC_TEMPERATURE(i1, i1, i1, z1, e, rho, T, dqldqt)
        CALL THERMO_POLYNOMIAL_PSAT(i1, i1, i1, T, qsat)
        qsat = qsat/(rho*T*WGHT_INV(1))
        CALL THERMO_THERMAL_PRESSURE(i1, i1, i1, z1, rho, T, p)
        CALL THERMO_CALORIC_ENTHALPY(i1, i1, i1, z1, T, h)

     ELSE IF ( opt .EQ. 2 ) THEN
        CALL THERMO_AIRWATER_RP(i1, i1, i1, z1, p, rho, T, dqldqt)
        CALL THERMO_POLYNOMIAL_PSAT(i1, i1, i1, T, qsat)
        qsat = qsat/(rho*T*WGHT_INV(1))
        CALL THERMO_CALORIC_ENERGY(i1, i1, i1, z1, T, e)
        CALL THERMO_CALORIC_ENTHALPY(i1, i1, i1, z1, T, h)

     ELSE IF ( opt .EQ. 3 ) THEN
!        CALL THERMO_AIRWATER_PH(i1, i1, i1, z1, p, h, T, dqldqt)
        CALL THERMO_AIRWATER_PH2(i1, i1, i1, z1, p, h, T)
        CALL THERMO_POLYNOMIAL_PSAT(i1, i1, i1, T, qsat)
        qsat = C_1_R/(MRATIO*p/qsat-C_1_R)*WGHT_INV(2)/WGHT_INV(1)
        qsat = qsat/(C_1_R+qsat)
        CALL THERMO_THERMAL_DENSITY(i1, i1, i1, z1, p, T, rho)
        CALL THERMO_CALORIC_ENERGY(i1, i1, i1, z1, T, e)

     ENDIF
     WRITE(21,*) qt, z1(2), qt-z1(2), qsat, rho, T, p, e, h

     qt = qt+qt_del
  ENDDO

  CLOSE(21)

  CALL DNS_END(0)

  CALL DNS_STOP

  STOP
END PROGRAM SMOOTH
