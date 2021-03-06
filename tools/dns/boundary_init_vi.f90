!########################################################################
!# Tool/Library DNS
!#
!########################################################################
!# HISTORY
!#
!# 1999/01/01 - C. Pantano
!#              Created
!# 2007/03/25 - J.P. Mellado
!#              Adding possible dependence perpendicular to boundary
!#
!########################################################################
!# DESCRIPTION
!#
!# Setting buffer zone in output boundary. It only makes sense in
!# spatially evolving cases.
!#
!########################################################################
!# ARGUMENTS 
!#
!########################################################################
#include "types.h"
#include "dns_const.h"
#include "dns_error.h"

SUBROUTINE BOUNDARY_INIT_VI(dz, q,s, txc, buffer_vi)

  USE DNS_GLOBAL, ONLY : imax, jmax, kmax
  USE DNS_GLOBAL, ONLY : imode_eqns, icalc_scal, inb_scal, inb_flow, inb_vars, scalez
  USE DNS_LOCAL

  IMPLICIT NONE

#include "integers.h"

  TREAL, DIMENSION(*)                         :: dz
  TREAL, DIMENSION(imax*jmax*kmax,*)          :: q, s, txc
  TREAL, DIMENSION(buff_nps_imin,jmax,kmax,*) :: buffer_vi

  TARGET txc, q

! -------------------------------------------------------------------
  TREAL AVG1V1D, COV2V1D
  TREAL dbuff(inb_vars)
  TINTEGER i, j, iq, is

  TREAL, DIMENSION(:), POINTER :: r_loc, e_loc

! ###################################################################
  IF      ( imode_eqns .EQ. DNS_EQNS_TOTAL    ) THEN; e_loc => txc(:,2); r_loc => q(:,5)
  ELSE IF ( imode_eqns .EQ. DNS_EQNS_INTERNAL ) THEN; e_loc => q(:,4);   r_loc => q(:,5);
  ELSE;                                                                  r_loc => txc(:,1); ENDIF

! ###################################################################
! Shear layer and jet profile
! ###################################################################
  DO iq = 1,3
  DO j = 1,jmax; DO i = 1,buff_nps_imin
     dbuff(iq) = COV2V1D(imax,jmax,kmax, i,j, r_loc,q(1,iq))
     buffer_vi(i,j,:,iq) = dbuff(iq)
  ENDDO; ENDDO
  ENDDO

! if compressible
  IF ( imode_eqns .EQ. DNS_EQNS_TOTAL .OR. imode_eqns .EQ. DNS_EQNS_INTERNAL ) THEN
  DO j = 1,jmax; DO i = 1,buff_nps_imin
     dbuff(4) = COV2V1D(imax,jmax,kmax, i,j, r_loc,e_loc)
     buffer_vi(i,j,:,4) = dbuff(4)
     dbuff(5) = AVG1V1D(imax,jmax,kmax, i,j, i1, r_loc)
     buffer_vi(i,j,:,5) = dbuff(5)
  ENDDO; ENDDO
  ENDIF

  IF ( icalc_scal .EQ. 1 ) THEN
  DO is = 1,inb_scal
  DO j = 1,jmax; DO i = 1,buff_nps_imin
     dbuff(is) = COV2V1D(imax,jmax,kmax, i,j, r_loc,s(1,is))
     buffer_vi(i,j,:,inb_flow+is) = dbuff(is)
  ENDDO; ENDDO
  ENDDO
  ENDIF

  RETURN
END SUBROUTINE BOUNDARY_INIT_VI

