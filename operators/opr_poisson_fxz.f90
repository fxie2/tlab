#include "types.h"
#include "dns_error.h"
#include "dns_const_mpi.h"

!########################################################################
!# DESCRIPTION
!#
!# Solve Lap p = a using Fourier in xOz planes, to rewritte the problem
!# as 
!#     \hat{p}''-\lambda \hat{p} = \hat{a}
!#
!# where \lambda = kx^2+kz^2
!#
!# The reference value of p at the lower boundary is set to zero
!#
!########################################################################
!# ARGUMENTS 
!#
!# ibc     In    BCs at j1/jmax: 0, for Dirichlet & Dirichlet
!#                               1, for Neumann   & Dirichlet 
!#                               2, for Dirichlet & Neumann   
!#                               3, for Neumann   & Neumann
!#
!# The global variable isize_txc_field defines the size of array txc equal
!# to (imax+2)*(jmax+2)*kmax, or larger if PARALLEL mode
!#
!########################################################################
SUBROUTINE OPR_POISSON_FXZ(imode_fdm,iflag,ibc, nx,ny,nz, g,&
     a,dpdy, tmp1,tmp2, bcs_hb,bcs_ht, aux, wrk1d,wrk3d)

  USE DNS_TYPES,  ONLY : grid_structure
  USE DNS_GLOBAL, ONLY : isize_txc_dimz, inb_grid_1
#ifdef USE_MPI
  USE DNS_MPI, ONLY : ims_offset_i, ims_offset_k
#endif

  IMPLICIT NONE

#include "integers.h"

  TINTEGER ibc, iflag, imode_fdm, nx,ny,nz
  TYPE(grid_structure),                     INTENT(IN)    :: g(3)
  TREAL,    DIMENSION(nx,ny,nz),            INTENT(INOUT) :: a    ! Forcing term, ans solution field p
  TREAL,    DIMENSION(nx,ny,nz),            INTENT(INOUT) :: dpdy ! Derivative, if iflag = 2
  TREAL,    DIMENSION(nx,nz),               INTENT(IN)    :: bcs_hb, bcs_ht   ! Boundary-condition fields
  TCOMPLEX, DIMENSION(isize_txc_dimz/2,nz), INTENT(INOUT) :: tmp1,tmp2, wrk3d
  TCOMPLEX, DIMENSION(ny,2),                INTENT(INOUT) :: aux
  TCOMPLEX, DIMENSION(ny,6),                INTENT(INOUT) :: wrk1d

! -----------------------------------------------------------------------
  TINTEGER i, j, k, iglobal, kglobal, ip, isize_line
  TREAL lambda, norm
  TCOMPLEX bcs(3)

! #######################################################################
  norm = C_1_R /M_REAL( g(1)%size *g(3)%size )

  isize_line = nx/2+1

! #######################################################################
! Fourier transform of forcing term; output of this section in array tmp1
! #######################################################################
  IF ( g(3)%size .GT. 1 ) THEN
     CALL OPR_FOURIER_F_X_EXEC(nx,ny,nz, a,bcs_hb,bcs_ht,tmp2, tmp1,wrk3d) 
     CALL OPR_FOURIER_F_Z_EXEC(tmp2,tmp1) ! tmp2 might be overwritten
  ELSE  
     CALL OPR_FOURIER_F_X_EXEC(nx,ny,nz, a,bcs_hb,bcs_ht,tmp1, tmp2,wrk3d)
  ENDIF 

! ###################################################################
! Solve FDE \hat{p}''-\lambda \hat{p} = \hat{a}
! ###################################################################
  DO k = 1,nz
#ifdef USE_MPI
  kglobal = k+ ims_offset_k
#else
  kglobal = k
#endif

  DO i = 1,isize_line
#ifdef USE_MPI
  iglobal = i + ims_offset_i/2
#else
  iglobal = i
#endif

! Define \lambda based on modified wavenumbers (real)
     ip = inb_grid_1 + 5 ! pointer to position in arrays dx, dz
     IF ( g(3)%size .GT. 1 ) THEN; lambda = g(1)%aux(iglobal,ip) + g(3)%aux(kglobal,ip)
     ELSE;                         lambda = g(1)%aux(iglobal,ip); ENDIF

! forcing term
     DO j = 1,ny
        ip = (j-1)*isize_line + i; aux(j,1) = tmp1(ip,k)
     ENDDO

! BCs
     j = ny+1; ip = (j-1)*isize_line + i; bcs(1) = tmp1(ip,k) ! Dirichlet or Neumann
     j = ny+2; ip = (j-1)*isize_line + i; bcs(2) = tmp1(ip,k) ! Dirichlet or Neumann

! -----------------------------------------------------------------------
! Solve for each (kx,kz) a system of 1 complex equation as 2 independent real equations
! -----------------------------------------------------------------------
     SELECT CASE(ibc)

     CASE(3) ! Neumann   & Neumann   BCs
        IF ( kglobal .EQ. 1             .AND. (iglobal .EQ. 1 .OR. iglobal .EQ. g(1)%size/2+1) .OR.&
             kglobal .EQ. g(3)%size/2+1 .AND. (iglobal .EQ. 1 .OR. iglobal .EQ. g(1)%size/2+1)     )THEN
           CALL FDE_BVP_SINGULAR_NN(imode_fdm, ny,i2, &
                g(2)%aux, aux(1,2),aux(1,1), bcs, wrk1d(1,1), wrk1d(1,3))
        ELSE
           CALL FDE_BVP_REGULAR_NN(imode_fdm, ny,i2, lambda, &
                g(2)%aux, aux(1,2),aux(1,1), bcs, wrk1d(1,1), wrk1d(1,2))
        ENDIF

     CASE(0) ! Dirichlet & Dirichlet BCs
        IF ( kglobal .EQ. 1             .AND. (iglobal .EQ. 1 .OR. iglobal .EQ. g(1)%size/2+1) .OR.&
             kglobal .EQ. g(3)%size/2+1 .AND. (iglobal .EQ. 1 .OR. iglobal .EQ. g(1)%size/2+1)     )THEN
           CALL FDE_BVP_SINGULAR_DD(imode_fdm, ny,i2, &
                g(2)%nodes,g(2)%aux, aux(1,2),aux(1,1), bcs, wrk1d(1,1), wrk1d(1,3))
        ELSE
           CALL FDE_BVP_REGULAR_DD(imode_fdm, ny,i2, lambda, &
                           g(2)%aux, aux(1,2),aux(1,1), bcs, wrk1d(1,1), wrk1d(1,2))
        ENDIF

     END SELECT

! normalize
     DO j = 1,ny
        ip = (j-1)*isize_line + i
        tmp1(ip,k) = aux(j,2)  *norm ! solution
        tmp2(ip,k) = wrk1d(j,1)*norm ! Oy derivative
     ENDDO
        
  ENDDO
  ENDDO

! ###################################################################
! Fourier field p (based on array tmp1)
! ###################################################################
  IF ( g(3)%size .GT. 1 ) THEN
     CALL OPR_FOURIER_B_Z_EXEC(tmp1,wrk3d) 
     CALL OPR_FOURIER_B_X_EXEC(nx,ny,nz, wrk3d,a, tmp1) 
  ELSE
     CALL OPR_FOURIER_B_X_EXEC(nx,ny,nz, tmp1,a, wrk3d) 
  ENDIF
     
! ###################################################################
! Fourier derivatives (based on array tmp2)
! ###################################################################
  IF ( iflag .EQ. 2 ) THEN
     IF ( g(3)%size .GT. 1 ) THEN
        CALL OPR_FOURIER_B_Z_EXEC(tmp2,wrk3d) 
        CALL OPR_FOURIER_B_X_EXEC(nx,ny,nz, wrk3d,dpdy, tmp2) 
     ELSE
        CALL OPR_FOURIER_B_X_EXEC(nx,ny,nz, tmp2,dpdy, wrk3d) 
     ENDIF
  ENDIF

  RETURN
END SUBROUTINE OPR_POISSON_FXZ
