#include "types.h"
#include "dns_error.h"
#include "dns_const.h"
#ifdef USE_MPI
#include "dns_const_mpi.h"
#endif

!########################################################################
!# Tool/Library DNS
!#
!########################################################################
!# HISTORY
!#
!#
!########################################################################
!# DESCRIPTION
!#
!# Read initial particle information
!# MPI I/O is used
!# 
!########################################################################
!# ARGUMENTS 
!#
!#
!########################################################################
SUBROUTINE DNS_READ_PARTICLE(fname, l_q)

  USE DNS_GLOBAL, ONLY: isize_particle, inb_particle
  USE LAGRANGE_GLOBAL, ONLY :  particle_number
#ifdef USE_MPI
  USE DNS_MPI, ONLY : particle_vector, ims_pro, ims_npro, ims_err
#endif

  IMPLICIT NONE
#ifdef USE_MPI
#include "mpif.h"
#endif  
 
  CHARACTER(*)                                  :: fname
  CHARACTER(len=20)                             :: str
  TREAL, DIMENSION(isize_particle,inb_particle) :: l_q 
  TINTEGER i
  TLONGINTEGER particle_header
#ifdef USE_MPI
  TINTEGER j,  processor_number
  TINTEGER mpio_fh
  INTEGER (KIND=8)  mpio_disp
  TINTEGER status(MPI_STATUS_SIZE)
  TLONGINTEGER, DIMENSION(ims_npro) :: particle_vector_final
#else
  TINTEGER  particle_pos
#endif

#ifdef USE_MPI
!#######################################################################
! READ HEADER   
!#######################################################################
  IF(ims_pro .EQ. 0) THEN
    DO j=1,inb_particle  !loop for 3 directions
      WRITE(str,*) j;  str = TRIM(ADJUSTL(fname))//"."//TRIM(ADJUSTL(str)) ! adjust the name with the number for direction
      OPEN(unit=117, file=str, access='stream', form='unformatted')
      READ(117) processor_number
      READ(117, POS=SIZEOFINT+1) particle_header
      READ(117, POS=SIZEOFINT+SIZEOFLONGINT+1) particle_vector(1:ims_npro)
      CLOSE(117)
    END DO
  END IF
  CALL MPI_BARRIER(MPI_COMM_WORLD,ims_err)
!#######################################################################
! Communicate HEADER
!#######################################################################
  CALL MPI_BCAST(particle_vector,ims_npro,MPI_INTEGER,0,MPI_COMM_WORLD,ims_err)
  
  !Calculate the dispplacement !
  particle_vector_final(1)=INT(particle_vector(1),KIND=8)
  DO i=2,ims_npro
    particle_vector_final(i)=INT(particle_vector(i),KIND=8) + particle_vector_final(i-1)
  END DO

!#######################################################################
! READ PARTICLES
!#######################################################################

  DO j=1,inb_particle  !loop for 3 directions (x,y,z)
    WRITE(str,*) j;  str = TRIM(ADJUSTL(fname))//"."//TRIM(ADJUSTL(str)) ! adjust the name with the number for direction

    CALL MPI_FILE_OPEN(MPI_COMM_WORLD,str, MPI_MODE_RDONLY, MPI_INFO_NULL, mpio_fh, ims_err)

  
    mpio_disp = INT(((ims_npro+1)*SIZEOFINT)+SIZEOFLONGINT+1, KIND=8)
 
   !Displacement per processor
    IF(ims_pro .EQ. 0) THEN
      mpio_disp=mpio_disp
    ELSE
      mpio_disp=mpio_disp+(particle_vector_final(ims_pro))*INT(SIZEOFREAL, KIND=8) !yes ims_pro not ims_pro+1
    END IF
    
    !Set view
    CALL MPI_FILE_SET_VIEW(mpio_fh, mpio_disp, MPI_REAL8, MPI_REAL8, 'native', MPI_INFO_NULL, ims_err)

    !Actual read
    CALL MPI_FILE_READ_ALL(mpio_fh,l_q(1,j), particle_vector(ims_pro+1),MPI_REAL8,status,ims_err)
    
    CALL MPI_FILE_CLOSE(mpio_fh, ims_err)

  END DO


#else

!#######################################################################
! SERIAL READ
!#######################################################################
  particle_pos=9
  DO i=1,inb_particle  !loop for 3 directions
    WRITE(str,*) i;  str = TRIM(ADJUSTL(fname))//"."//TRIM(ADJUSTL(str)) ! adjust the name with the number for direction
    OPEN(UNIT=117, FILE=str, STATUS="OLD", ACCESS="STREAM") !access file as stream so no fortran header in bin file
    READ(117) particle_header   !read header which contains number of particles
    READ(117, POS=particle_pos) l_q(1:particle_number,i)
    CLOSE(117)
  END DO
#endif
  RETURN
END SUBROUTINE DNS_READ_PARTICLE

