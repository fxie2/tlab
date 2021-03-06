#include "types.h"
#include "dns_const.h"

SUBROUTINE VELOCITY_MEAN(rho, u,v,w, wrk1d,wrk3d)

  USE DNS_GLOBAL, ONLY : g
  USE DNS_GLOBAL, ONLY : imode_flow, imode_sim, imax,jmax,kmax
  USE DNS_GLOBAL, ONLY : iprof_u, mean_u, delta_u, thick_u, ycoor_u, prof_u, diam_u, jet_u
  USE DNS_GLOBAL, ONLY : mean_v, mean_w
  USE DNS_GLOBAL, ONLY : coriolis

  IMPLICIT NONE

#include "integers.h"

  TREAL, DIMENSION(imax,jmax,kmax), INTENT(IN)    :: rho
  TREAL, DIMENSION(imax,jmax,kmax), INTENT(OUT)   :: u, v, w
  TREAL, DIMENSION(jmax,*),         INTENT(INOUT) :: wrk1d, wrk3d

! -------------------------------------------------------------------
  TINTEGER j, k, iprof_loc
  TREAL FLOW_SHEAR_TEMPORAL, FLOW_JET_TEMPORAL, ycenter, calpha, salpha, fsign 
  EXTERNAL FLOW_SHEAR_TEMPORAL, FLOW_JET_TEMPORAL

! ###################################################################
! Isotropic case
! ###################################################################
  IF      ( imode_flow .EQ. DNS_FLOW_ISOTROPIC   ) THEN
     u = u + mean_u
     v = v + mean_v
     IF ( g(3)%size .GT. 1 ) THEN; w = w + mean_w
     ELSE;                         w = C_0_R     ; ENDIF

! ###################################################################
! Shear layer case
! ###################################################################
  ELSE IF ( imode_flow .EQ. DNS_FLOW_SHEAR       ) THEN
! -------------------------------------------------------------------
! Temporal
! -------------------------------------------------------------------
     IF ( imode_sim .EQ. DNS_MODE_TEMPORAL ) THEN

! Construct reference profiles into array wrk1d
        iprof_loc = PROFILE_EKMAN_V           ! Needed for Ekman case
        calpha = COS(coriolis%parameters(1)); salpha = SIN(coriolis%parameters(1))
        fsign  = SIGN(C_1_R,coriolis%vector(2))
        ycenter = g(2)%nodes(1) + g(2)%scale*ycoor_u
        DO j = 1,jmax
           wrk1d(j,1) =  FLOW_SHEAR_TEMPORAL&
                (iprof_u,   thick_u, delta_u, mean_u, ycenter, prof_u, g(2)%nodes(j))
           wrk1d(j,2) =  FLOW_SHEAR_TEMPORAL& ! Needed for Ekman case
                (iprof_loc, thick_u, delta_u, mean_u, ycenter, prof_u, g(2)%nodes(j))
        ENDDO

! Construct velocity field
        wrk1d(:,2) = fsign*wrk1d(:,2) ! right angular velocity vector (Garratt, 1992, p.42)
        IF ( iprof_u .EQ. PROFILE_EKMAN_U  .OR. iprof_u .EQ. PROFILE_EKMAN_U_P ) THEN
           DO j = 1,jmax
              u(:,j,:) = u(:,j,:) + wrk1d(j,1)*calpha + wrk1d(j,2)*salpha 
           ENDDO
        ELSE
           DO j = 1,jmax
              u(:,j,:) = u(:,j,:) + wrk1d(j,1)
           ENDDO
        ENDIF

        v = v + mean_v

        IF ( g(3)%size .GT. 1 ) THEN
           IF ( iprof_u .EQ. PROFILE_EKMAN_U  .OR. iprof_u .EQ. PROFILE_EKMAN_U_P ) THEN
              DO j = 1,jmax
                 w(:,j,:) = w(:,j,:) - wrk1d(j,1)*salpha + wrk1d(j,2)*calpha
              ENDDO
           ELSE
              w = w + mean_w
           ENDIF

        ELSE
           w = C_0_R ! Spanwise velocity set to zero

        ENDIF

! -------------------------------------------------------------------
! Spatial
! -------------------------------------------------------------------
     ELSE IF ( imode_sim .EQ. DNS_MODE_SPATIAL ) THEN
     ENDIF
     
! ###################################################################
! Jet case
! ###################################################################
  ELSE IF ( imode_flow .EQ. DNS_FLOW_JET ) THEN
! -------------------------------------------------------------------
! Temporal
! -------------------------------------------------------------------
     IF ( imode_sim .EQ. DNS_MODE_TEMPORAL ) THEN

! Construct reference profile into array wrk1d
! pilot to be added: ijet_pilot, rjet_pilot_thickness, rjet_pilot_velocity
        ycenter = g(2)%nodes(1) + g(2)%scale*ycoor_u
        DO j = 1,jmax
           wrk1d(j,1) =  FLOW_JET_TEMPORAL&
                (iprof_u, thick_u, delta_u, mean_u, diam_u, ycenter, prof_u, g(2)%nodes(j))
        ENDDO
        
! Construct velocity field
        DO j = 1,jmax
           u(:,j,:) = u(:,j,:) + wrk1d(j,1)
        ENDDO

        v = v + mean_v

        IF ( g(3)%size .GT. 1 ) THEN; w = w + mean_w
        ELSE;                         w = C_0_R     ; ENDIF
        
! -------------------------------------------------------------------
! Spatial
! -------------------------------------------------------------------
     ELSE IF ( imode_sim .EQ. DNS_MODE_SPATIAL ) THEN
#define rho_vi(j) wrk1d(j,1)
#define u_vi(j)   wrk1d(j,2)
#define aux(j)    wrk1d(j,3)
        DO j = 1,jmax
           rho_vi(j) = rho(1,j,1)
           u_vi(j)   = u(1,j,1)
        ENDDO
        ycenter = g(2)%nodes(1) + g(2)%scale *ycoor_u
        CALL FLOW_JET_SPATIAL_VELOCITY&
             (imax, jmax, iprof_u, thick_u, delta_u, mean_u, diam_u, ycenter,&
             jet_u(1), jet_u(2), jet_u(3), &
             g(1)%nodes, g(2)%nodes, rho_vi(1), u_vi(1), rho, u, v, aux(1), wrk3d)
        IF ( kmax .GT. 1 ) THEN
           DO k = 2,kmax
              u(:,:,k) = u(:,:,1)
              v(:,:,k) = v(:,:,1)
           ENDDO
        ENDIF
#undef rho_vi
#undef u_vi
#undef aux
        
        IF ( g(3)%size .GT. 1 ) THEN; w = w + mean_w
        ELSE;                         w = C_0_R     ; ENDIF

     ENDIF

  ENDIF

  RETURN
END SUBROUTINE VELOCITY_MEAN
