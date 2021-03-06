#include "types.h"

PROGRAM VINTEGRAL

  USE DNS_GLOBAL, ONLY : imax_total

  IMPLICIT NONE
  
#include "integers.h"
  
  TINTEGER imode_fdm, imax, jmax, kmax, i, i1bc, iunif, ibc, itype
  PARAMETER(imax=1024)
  TREAL scalex, x_0
  TREAL x(imax), dx(imax,2+4*3+4*3+5)
  TREAL u(imax), du1_a(imax), du2_a(imax), w_n(imax), dw1_n(imax), v(imax), dv1_a(imax), f(imax)
  TREAL wrk1d(imax,5+2+5), wrk2d(imax), wrk3d(imax)
  TREAL sol, error, wk, lambda, dummy
  TINTEGER imin_loc, imax_loc

! ###################################################################
  itype = 0

  scalex = C_1_R
  jmax  = 1
  kmax  = 1
  imax_total = imax
  imode_fdm = 6
  iunif = 1
  i1bc  = 1

  WRITE(*,*) 'Wavenumber ?'
  READ(*,*) wk

  WRITE(*,*) 'Eigenvalue ?'
  READ(*,*) lambda

  DO i = 1,imax
     x(i) = M_REAL(i-1)/M_REAL(imax-1)*scalex
  ENDDO
!   OPEN(21,file='grid.dat')
!   DO i = 1,imax
!      READ(21,*) x(i)
!   ENDDO
!   scalex=x(imax)-x(1)
!   CLOSE(21)

  CALL DNS_INITIALIZE
  CALL FDM_INITIALIZE(iunif, imode_fdm, imax, i1bc, scalex, x, dx, wrk1d)
  x_0 = C_075_R

! ###################################################################
! Define the function f
  DO i = 1,imax
! single-mode
    u(i)     = SIN(C_2_R*C_PI_R/scalex*wk*x(i)+C_PI_R/C_4_R)
    du1_a(i) = (C_2_R*C_PI_R/scalex*wk)&
              *COS(C_2_R*C_PI_R/scalex*wk*x(i)+C_PI_R/C_4_R)
!     u(i)     =              COS(C_2_R*C_PI_R*x(i))
!     du1_a(i) =-C_PI_R*C_2_R*SIN(C_2_R*C_PI_R*x(i))
! Gaussian
    ! u(i)     = EXP(-(x(i)-x_0*scalex)**2/(C_2_R*(scalex/wk)**2))
    ! du1_a(i) =-(x(i)-x_0*scalex)/(scalex/wk)**2*u(i)
    ! v(i)     = EXP(-(x(i)-x_0*C_05_R*scalex)**2/(C_2_R*(scalex/wk)**2))
    ! dv1_a(i) =-(x(i)-x_0*C_05_R*scalex)/(scalex/wk)**2*v(i)
! exponential
     ! u(i) = EXP(-x(i)*lambda)
     ! du1_a(i) = -lambda*u(i)
     ! du2_a(i) =  lambda*lambda*u(i)
!     v(i) = EXP(x(i)*x_0/scalex)
!     dv1_a(i) = x_0/scalex*v(i)
! step
!     u(i) = MAX(C_0_R,(x(i)-x(imax/2))*x_0)
!     du1_a(i) = (C_1_R+SIGN(C_1_R,x(i)-x(imax/2)))*C_05_R*x_0
! tanh
!     u(i) = x_0 * LOG( C_1_R + EXP( (x(i)-x(imax/2))/x_0 ) )
!     du1_a(i) = C_05_R*( C_1_R + TANH( C_05_R*(x(i)-x(imax/2))/x_0 ) )
! polynomial
!     u(i)     =         x(i)** lambda
!     du1_a(i) = lambda*(x(i)**(lambda-C_1_R))
! zero
!     u(i) = C_0_R
!     du1_a(i) = C_0_R
  ENDDO

!   OPEN(21,file='field.dat')
!   DO i = 1,imax
!      READ(21,*) dw1_n(i)
!   ENDDO
!   CLOSE(21)

! ###################################################################
! Integral
! ###################################################################
  IF ( itype .EQ. 0 ) THEN

     CALL PARTIAL_X(imode_fdm, imax,jmax,kmax, i1bc, dx, u, f, i0,i0, wrk1d,wrk2d,wrk3d)
!     f = du1_a

     ibc = 1
  
     CALL INT_C1N6_LHS(imax,    ibc,     wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5))
     CALL INT_C1N6_RHS(imax,i1, ibc, dx, f,w_n)

     IF      ( ibc .EQ. 1 ) THEN ! at the bottom
        CALL PENTADFS(imax-1,    wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5))
        CALL PENTADSS(imax-1,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), w_n(2))
        w_n(1) = C_0_R; w_n   = w_n + u(1)    ! BCs

     ELSE IF ( ibc .EQ. 2 ) THEN ! at the top
        CALL PENTADFS(imax-1,    wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5))
        CALL PENTADSS(imax-1,i1, wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5), w_n(1))
        w_n(imax) = C_0_R; w_n   = w_n + u(imax) ! BCs

     ENDIF

! ###################################################################
! First order equation
! ###################################################################
  ELSE IF ( itype .EQ. 1 ) THEN

! -------------------------------------------------------------------
  f = du1_a + lambda*u

! conservation of u*v
!  CALL PARTIAL_X(imode_fdm, imax,jmax,kmax, i1bc, dx, u, du1_a, i0,i0, wrk1d,wrk2d,wrk3d)
!  CALL PARTIAL_X(imode_fdm, imax,jmax,kmax, i1bc, dx, v, dv1_a, i0,i0, wrk1d,wrk2d,wrk3d)
!  f = du1_a*v + dv1_a*u

! solve for w_n
  ibc = 1 !; u(1)=C_0_R

!  CALL INT_C1N6_LHS  (imax,    ibc,             wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5))
  CALL INT_C1N6_LHS_E(imax,    ibc, dx, lambda, wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5), wrk1d(1,6))
  CALL INT_C1N6_RHS  (imax,i1, ibc, dx,         f,w_n)

  IF      ( ibc .EQ. 1 ) THEN
     CALL PENTADFS(imax-1,    wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5))
     CALL PENTADSS(imax-1,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), w_n(2))
     CALL PENTADSS(imax-1,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), wrk1d(2,6))
     dummy = w_n(1); w_n(1) = C_0_R
!     w_n   = w_n + u(1)                 ! BCs
     w_n   = w_n + u(1)*wrk1d(1:imax,6) ! BCs
     dummy =(dummy+ wrk1d(1,3)*w_n(1)+ wrk1d(1,4)*w_n(2)+ wrk1d(1,5)*w_n(3))/dx(1,1)

  ELSE IF ( ibc .EQ. 2 ) THEN
     CALL PENTADFS(imax-1,    wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5))
     CALL PENTADSS(imax-1,i1, wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5), w_n(1))
     CALL PENTADSS(imax-1,i1, wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5), wrk1d(1,6))
     dummy = w_n(imax); w_n(imax) = C_0_R
!     w_n   = w_n + u(imax)                 ! BCs
     w_n   = w_n + u(imax)*wrk1d(1:imax,6) ! BCs
     dummy =(dummy+ wrk1d(imax,1)*w_n(imax-2)+ wrk1d(imax,2)*w_n(imax-1)+ wrk1d(imax,3)*w_n(imax))/dx(imax,1)
  ENDIF

! check
!  CALL PARTIAL_X(imode_fdm, imax,jmax,kmax, i1bc, dx, w_n, dw1_n, i0,i0, wrk1d,wrk2d,wrk3d)
!  w_n = dw1_n !+ lambda*w_n

  IF ( ibc .EQ. 1 ) THEN; print*, dummy, dw1_n(1   )
  ELSE;                   print*, dummy, dw1_n(imax); ENDIF
  f = u

! conservation of u*v
!  f = u*v; dummy = f(1); f = f - dummy

! ###################################################################
! Second order equation
! ###################################################################
  ELSE IF ( itype .EQ. 2 ) THEN
     wrk1d = 0

     CALL PARTIAL_XX(i1,iunif,imode_fdm, imax,jmax,kmax, i1bc, dx, u, f, i0,i0, i0,i0, v, wrk1d,wrk2d,wrk3d)
     dummy = lambda*lambda
!     f = du2_a - dummy*u
     f = f - dummy*u

     CALL INT_C2N6_LHS_E(imax,    dx, dummy, wrk1d(1,1),wrk1d(1,2),wrk1d(1,3),wrk1d(1,4),wrk1d(1,5), wrk1d(1,6),wrk1d(1,7))
     CALL PENTADFS(imax-2,    wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5))

     CALL PENTADSS(imax-2,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), wrk1d(2,6))
     CALL PENTADSS(imax-2,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), wrk1d(2,7))

     CALL INT_C2N6_RHS  (imax,i1, dx,         f,w_n)
     CALL PENTADSS(imax-2,i1, wrk1d(2,1),wrk1d(2,2),wrk1d(2,3),wrk1d(2,4),wrk1d(2,5), w_n(2))

     w_n(:) = w_n(:) + u(1)*wrk1d(:,6) + u(imax)*wrk1d(:,7)

  ENDIF

! ###################################################################
  OPEN(20,file='integral.dat')
  error = C_0_R
  sol   = C_0_R
  imin_loc = 1; imax_loc = imax
!  IF      ( ibc .EQ. 1 ) THEN; imin_loc = 2
!  ELSE IF ( ibc .EQ. 2 ) THEN; imax_loc = imax-1; ENDIF
  DO i = imin_loc,imax_loc
     WRITE(20,1000) x(i), u(i), w_n(i), u(i)-w_n(i), wrk1d(i,6), wrk1d(i,7)
     w_n(i)= ABS(u(i)-w_n(i))
     error = error + w_n(i)*w_n(i)
     sol   = sol   + u(i)*u(i)
!     WRITE(20,1000) x(i), u(i), v(i), w(i), w_n(i), w(i)-w_n(i)
!     error = error + (w(i)-w_n(i))*(w(i)-w_n(i))
!     sol   = sol   + w(i)*w(i)
  ENDDO
  CLOSE(20)

  WRITE(*,*) 'Solution L2-norm ......:', sqrt(dx(1,1)*sol)
  WRITE(*,*) 'Error L2-norm .........:', sqrt(dx(1,1)*error)
  WRITE(*,*) 'Error Linf-norm .......:', MAXVAL(w_n(1:imax))
  WRITE(*,*) 'Relative error ........:', sqrt(error)/sqrt(sol)
  WRITE(*,*) 'Derivative overshoot ..:', MINVAL(dw1_n(1:imax))

  STOP

1000 FORMAT(6(1x,e17.10e3)) 

END PROGRAM VINTEGRAL
