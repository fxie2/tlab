#include "types.h"
#include "dns_const.h"
#include "avgij_map.h"
#ifdef LES
#include "les_const.h"
#include "les_avgij_map.h"
#endif

!########################################################################
!# Tool/Library
!#
!########################################################################
!# HISTORY
!#
!# 2007/01/01 - J.P. Mellado
!#              Created
!#
!########################################################################
!# DESCRIPTION
!# 
!# Defining structure of auxiliary array VAUX
!#
!########################################################################
!# ARGUMENTS 
!#
!# isize_vaux  Out  Size of the array to be allocated in memory
!#
!########################################################################
SUBROUTINE DNS_VAUX(isize_vaux)
  
  USE DNS_CONSTANTS, ONLY : MAX_AVG_TEMPORAL
  USE DNS_GLOBAL
  USE DNS_LOCAL
#ifdef LES
  USE LES_GLOBAL
#endif 

  IMPLICIT NONE
  
  TINTEGER isize_vaux

! -----------------------------------------------------------------------
  TINTEGER i
#ifdef LES
  TINTEGER n_vaux_arm_size
#ifdef USE_MPI
  TINTEGER fsize_max
#endif
#endif
  
! #######################################################################
  vsize(VA_FLT_CX) = imax_total*6 ! compact needs 6, explicit 5
  vsize(VA_FLT_CY) = jmax_total*6
  vsize(VA_FLT_CZ) = kmax_total*6

  vsize(VA_BUFF_HT) = imax*kmax*inb_vars*buff_nps_jmax
  vsize(VA_BUFF_HB) = imax*kmax*inb_vars*buff_nps_jmin
  vsize(VA_BUFF_VI) = jmax*kmax*inb_vars*buff_nps_imin
  vsize(VA_BUFF_VO) = jmax*kmax*inb_vars*buff_nps_imax

  vsize(VA_BCS_HT) = imax*kmax* inb_vars
  vsize(VA_BCS_HB) = imax*kmax* inb_vars
  vsize(VA_BCS_VI) = jmax*kmax*(inb_vars+1)
  vsize(VA_BCS_VO) = jmax*kmax* inb_vars

! -----------------------------------------------------------------------
  inb_mean_spatial = MA_MOMENTUM_SIZE+MS_SCALAR_SIZE*inb_scal
  inb_mean_temporal= MAX_AVG_TEMPORAL

! Averages
  IF      ( imode_sim .EQ. DNS_MODE_SPATIAL ) THEN 
     vsize(VA_MEAN_WRK) = nstatavg*jmax*inb_mean_spatial
  ELSE IF ( imode_sim .EQ. DNS_MODE_TEMPORAL) THEN
     vsize(VA_MEAN_WRK) = jmax*inb_mean_temporal
  ELSE
     vsize(VA_MEAN_WRK) = 1
  ENDIF

! Line data
  IF ( imode_sim .EQ. DNS_MODE_SPATIAL .AND. frunline .EQ. 1 ) THEN 
     vsize(VA_LINE_SPA_WRK) = nstatlin*kmax*inb_vars*nspa_rest
  ELSE
     vsize(VA_LINE_SPA_WRK) = 1
  ENDIF

! Times
  IF ( imode_sim .EQ. DNS_MODE_SPATIAL ) THEN 
     vsize(VA_TIMES) = 2*nspa_rest
  ELSE
     vsize(VA_TIMES) = 1
  ENDIF

! Plane data
  IF ( imode_sim .EQ. DNS_MODE_SPATIAL .AND. frunplane .EQ. 1 ) THEN 
     vsize(VA_PLANE_SPA_WRK) = jmax*kmax*nstatpln*nstatplnvars*nspa_rest
  ELSE
     vsize(VA_PLANE_SPA_WRK) = 1
  ENDIF

! #######################################################################
! LES data
! #######################################################################
#ifdef LES
  IF ( iles .EQ. 1 ) THEN
#include "les_vsizes.h"

! Adding space in averages array
     IF ( imode_sim .EQ. DNS_MODE_SPATIAL ) THEN 
        inb_mean_spatial = inb_mean_spatial &
                         + LA_MOMENTUM_SIZE + (LS_SCALAR_SIZE+LC_CHEM_SIZE)*inb_scal
        vsize(VA_MEAN_WRK) = nstatavg*jmax*inb_mean_spatial
     ENDIF

! Space for FDF table in the BS case
     IF (  iles_type_chem .NE. LES_CHEM_NONE ) THEN
        vsize(VA_LES_FDF_BS) = les_fdf_bs_maxmean + 2*les_fdf_bs_maxmean*les_fdf_bs_maxvar
     ELSE
        vsize(VA_LES_FDF_BS) = 1
     ENDIF
  ELSE
     vsize(VA_LES_FLT0X) = 1
     vsize(VA_LES_FLT0Y) = 1
     vsize(VA_LES_FLT0Z) = 1
     vsize(VA_LES_FLT1X) = 1
     vsize(VA_LES_FLT1Y) = 1
     vsize(VA_LES_FLT1Z) = 1
     vsize(VA_LES_FLT2X) = 1
     vsize(VA_LES_FLT2Y) = 1
     vsize(VA_LES_FLT2Z) = 1
     vsize(VA_LES_SGSCOEFU) = 1
     vsize(VA_LES_SGSCOEFE) = 1
     vsize(VA_LES_SGSCOEFZ) = 1
     vsize(VA_ARM_WRK)   = 1
     vsize(VA_ARM_C0)    = 1
     vsize(VA_LES_FDF_BS)= 1
  ENDIF
#endif

! #######################################################################
! Definition of pointers and sizes
! #######################################################################
  vindex(1)  = 1
  isize_vaux = vsize(1)
  DO i = 2,vindex_size
     vindex(i)  = vindex(i-1) + vsize(i-1)
     isize_vaux = isize_vaux + vsize(i)
  ENDDO

  RETURN
END SUBROUTINE DNS_VAUX
