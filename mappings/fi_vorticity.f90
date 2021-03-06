#include "types.h"

!########################################################################
!# HISTORY
!#
!# 2007/09/11 - J.P. Mellado
!#              Created
!#
!########################################################################
!# DESCRIPTION
!#
!# Calculate the magnitude of the vorticity as given by w_i w_i:
!# (v,x-u,y)^2 + (u,z-w,x)^2 + (w,y-v,z)^2
!# and terms in its evolution equation.
!#
!########################################################################

!########################################################################
! Calculate the magnitude of the vorticity
!########################################################################
SUBROUTINE FI_VORTICITY(imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc, &
     dx,dy,dz, u,v,w, result, tmp1,tmp2, wrk1d,wrk2d,wrk3d)

  IMPLICIT NONE

#include "integers.h"

  TINTEGER imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc
  TREAL, DIMENSION(*),        INTENT(IN)    :: dx,dy,dz
  TREAL, DIMENSION(nx*ny*nz), INTENT(IN)    :: u,v,w
  TREAL, DIMENSION(nx*ny*nz), INTENT(OUT)   :: result
  TREAL, DIMENSION(nx*ny*nz), INTENT(INOUT) :: tmp1,tmp2
  TREAL, DIMENSION(*),        INTENT(INOUT) :: wrk1d,wrk2d,wrk3d

! ###################################################################
! v,x-u,y
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, v, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, u, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = ( tmp1-tmp2 ) *( tmp1-tmp2 )

! u,z-w,x
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, u, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, w, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result +( tmp1-tmp2 ) *( tmp1-tmp2 ) 

! w,y-v,z
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, w, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, v, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result +( tmp1-tmp2 ) *( tmp1-tmp2 ) 

  RETURN
END SUBROUTINE FI_VORTICITY

!########################################################################
! Calculate the vorticity production term as given by w_i w_j s_ij
!########################################################################
SUBROUTINE FI_VORTICITY_PRODUCTION(imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc, &
     dx,dy,dz, u,v,w, result, vort_x,vort_y,vort_z, tmp1,tmp2, wrk1d,wrk2d,wrk3d)

  IMPLICIT NONE

#include "integers.h"

  TINTEGER imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc
  TREAL, DIMENSION(*),        INTENT(IN)    :: dx,dy,dz
  TREAL, DIMENSION(nx*ny*nz), INTENT(IN)    :: u,v,w
  TREAL, DIMENSION(nx*ny*nz), INTENT(OUT)   :: result
  TREAL, DIMENSION(nx*ny*nz), INTENT(INOUT) :: vort_x,vort_y,vort_z
  TREAL, DIMENSION(nx*ny*nz), INTENT(INOUT) :: tmp1,tmp2
  TREAL, DIMENSION(*),        INTENT(INOUT) :: wrk1d,wrk2d,wrk3d

! ###################################################################
! Vorticity vector
! ###################################################################
! Uy, Vx
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, v, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, u, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort_z = tmp1 -tmp2

! Uz, Wx
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, u, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, w, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort_y = tmp1 -tmp2

! Vz, Wy
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, w, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, v, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort_x = tmp1 -tmp2

! ###################################################################
! Production term
! ###################################################################
! Ux, Vy, Wz
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, u, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, v, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = tmp1 *vort_x*vort_x +tmp2 *vort_y*vort_y

  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, w, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result + tmp2 *vort_z*vort_z

! Uy, Vx
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, v, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, u, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result + ( tmp1 +tmp2 ) *vort_x *vort_y

! Uz, Wx
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, w, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, u, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result + ( tmp1 +tmp2 ) *vort_x *vort_z

! Vz, Wy
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, w, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, v, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  result = result + ( tmp1 +tmp2 ) *vort_y *vort_z

  RETURN
END SUBROUTINE FI_VORTICITY_PRODUCTION

!########################################################################
! Calculate the vorticity diffusion term as given by w_i lap w_i
! The kinematic viscosity \nu is not multiplied here.
!########################################################################
SUBROUTINE FI_VORTICITY_DIFFUSION(iunifx,iunify,iunifz, imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc, &
     dx,dy,dz, u,v,w, result, vort, tmp1,tmp2,tmp3,tmp4, wrk1d,wrk2d,wrk3d)

  IMPLICIT NONE

#include "integers.h"

  TINTEGER iunifx,iunify,iunifz, imode_fdm, nx,ny,nz, i1bc,j1bc,k1bc
  TREAL, DIMENSION(*),        INTENT(IN)    :: dx,dy,dz
  TREAL, DIMENSION(nx*ny*nz), INTENT(IN)    :: u,v,w
  TREAL, DIMENSION(nx*ny*nz), INTENT(OUT)   :: result
  TREAL, DIMENSION(nx*ny*nz), INTENT(INOUT) :: vort
  TREAL, DIMENSION(nx*ny*nz), INTENT(INOUT) :: tmp1,tmp2,tmp3,tmp4
  TREAL, DIMENSION(*),        INTENT(INOUT) :: wrk1d,wrk2d,wrk3d

! ###################################################################
! -------------------------------------------------------------------
! W_z = V,x - U,y
! -------------------------------------------------------------------
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, v, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, u, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort = tmp1 -tmp2

  CALL PARTIAL_ZZ(i0, iunifz, imode_fdm, nx,ny,nz, k1bc, dz, vort, tmp3, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_YY(i0, iunify, imode_fdm, nx,ny,nz, j1bc, dy, vort, tmp2, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_XX(i0, iunifx, imode_fdm, nx,ny,nz, i1bc, dx, vort, tmp1, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  result = vort *( tmp1 +tmp2 +tmp3 )

! -------------------------------------------------------------------
! W_y = U,z - W,x
! -------------------------------------------------------------------
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, u, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_X(imode_fdm, nx,ny,nz, i1bc, dx, w, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort = tmp1 -tmp2

  CALL PARTIAL_ZZ(i0, iunifz, imode_fdm, nx,ny,nz, k1bc, dz, vort, tmp3, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_YY(i0, iunify, imode_fdm, nx,ny,nz, j1bc, dy, vort, tmp2, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_XX(i0, iunifx, imode_fdm, nx,ny,nz, i1bc, dx, vort, tmp1, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  result = result + vort *( tmp1 +tmp2 +tmp3 )

! -------------------------------------------------------------------
! W_z = W,y - V,z
! -------------------------------------------------------------------
  CALL PARTIAL_Y(imode_fdm, nx,ny,nz, j1bc, dy, w, tmp1, i0,i0, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_Z(imode_fdm, nx,ny,nz, k1bc, dz, v, tmp2, i0,i0, wrk1d,wrk2d,wrk3d)
  vort = tmp1 -tmp2

  CALL PARTIAL_ZZ(i0, iunifz, imode_fdm, nx,ny,nz, k1bc, dz, vort, tmp3, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_YY(i0, iunify, imode_fdm, nx,ny,nz, j1bc, dy, vort, tmp2, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  CALL PARTIAL_XX(i0, iunifx, imode_fdm, nx,ny,nz, i1bc, dx, vort, tmp1, i0,i0, i0,i0, tmp4, wrk1d,wrk2d,wrk3d)
  result = result + vort *( tmp1 +tmp2 +tmp3 )

  RETURN
END SUBROUTINE FI_VORTICITY_DIFFUSION
