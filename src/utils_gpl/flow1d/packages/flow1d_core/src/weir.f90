module m_Weir
!----- AGPL --------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2017-2018.                                
!                                                                               
!  This program is free software: you can redistribute it and/or modify              
!  it under the terms of the GNU Affero General Public License as               
!  published by the Free Software Foundation version 3.                         
!                                                                               
!  This program is distributed in the hope that it will be useful,                  
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU Affero General Public License for more details.                          
!                                                                               
!  You should have received a copy of the GNU Affero General Public License     
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.             
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D" and "Deltares"
!  are registered trademarks of Stichting Deltares, and remain the property of
!  Stichting Deltares. All rights reserved.
!                                                                               
!-------------------------------------------------------------------------------
!  $Id: weir.f90 59644 2018-07-26 12:07:20Z zeekant $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/utils_gpl/flow1d/packages/flow1d_core/src/weir.f90 $
!-------------------------------------------------------------------------------

    use m_GlobalParameters
    use m_struc_helper

   implicit none

   private

   public ComputeWeir

   type, public :: t_weir
      double precision       :: crestlevel
      double precision       :: crestwidth
      double precision       :: dischargecoeff
      double precision       :: latdiscoeff
      double precision       :: cmu
      integer                :: allowedflowdir
      !> possible flow direction (relative to branch direction)
      !! 0 : flow in both directions
      !! 1 : flow from begin node to end node (positive)
      !! 2 : flow from end node to begin node (negative)
      !! 3 : no flow
   end type

contains

   subroutine ComputeWeir(weir, fum, rum, aum, dadsm, kfum, s1m1, s1m2, &
                          qm, q0m, u1m, u0m, dxm, dt, state)
   !!--copyright-------------------------------------------------------------------
   ! Copyright (c) 2003, Deltares. All rights reserved.
   !!--disclaimer------------------------------------------------------------------
   ! This code is part of the Delft3D software system. Deltares has
   ! developed c.q. manufactured this code to its best ability and according to the
   ! state of the art. Nevertheless, there is no express or implied warranty as to
   ! this software whether tangible or intangible. In particular, there is no
   ! express or implied warranty as to the fitness for a particular purpose of this
   ! software, whether tangible or intangible. The intellectual property rights
   ! related to this software code remain with Deltares at all times.
   ! For details on the licensing agreement, we refer to the Delft3D software
   ! license and any modifications to this license, if applicable. These documents
   ! are available upon request.
   !!--version information---------------------------------------------------------
   ! $Author$
   ! $Date$
   ! $Revision$
   !!--description-----------------------------------------------------------------
   ! NONE
   !!--pseudo code and references--------------------------------------------------
   ! NONE
   !!--declarations----------------------------------------------------------------
       !=======================================================================
       !                       Deltares
       !                One-Two Dimensional Modelling System
       !                           S O B E K
       !
       ! Subsystem:          Flow Module
       !
       ! Programmer:         G. Stelling
       !
       ! Module:             weir (WEIR)
       !
       ! Module description: coefficients for momentum equation in wet weir point
       !
       !
       !     update information
       !     person                    date
       !
       !
       !
       !     Include Pluvius data space
       !

       implicit none
   !
   ! Global variables
   !
       type(t_weir), pointer, intent(in)  :: weir
       integer, intent(out)               :: kfum
       double precision, intent(out)      :: aum
       double precision, intent(out)      :: dadsm
       double precision, intent(out)      :: fum
       double precision, intent(inout)    :: q0m
       double precision, intent(out)      :: qm
       double precision, intent(out)      :: rum
       double precision, intent(in)       :: u0m
       double precision, intent(inout)    :: u1m
       double precision, intent(in)       :: s1m2
       double precision, intent(in)       :: s1m1
       double precision, intent(in)       :: dxm
       double precision, intent(in)       :: dt
       integer, intent(inout)             :: state
   !
   !
   ! Local variables
   !
       integer                        :: allowedflowdir
       double precision               :: cu
       double precision               :: dble
       double precision               :: dsqrt
       double precision               :: fr
       double precision               :: rhsc
       double precision               :: scr
       double precision               :: smax
       double precision               :: smin
       double precision               :: swi
       double precision               :: uweir
       double precision               :: dxdt
   !
   !
   !! executable statements -------------------------------------------------------
   !
       !
       !
       scr            = -1.0*dble(weir%crestlevel)
       swi            = dble(weir%crestwidth)
       allowedflowdir = weir%allowedflowdir

       smax = max(s1m1, s1m2)
       smin = min(s1m1, s1m2)

       if ((allowedflowdir == 3) .or.                              &
           (s1m1 - s1m2 >= 0.0 .and. allowedflowdir == 2) .or.     &
           (s1m1 - s1m2 <= 0.0 .and. allowedflowdir == 1)) then
          kfum = 0
       !           ARS 9698 .lt. is change to .le.
       ! ARS 11039
       elseif (smax + scr <= 0d0) then
          kfum = 0
       else
          kfum = 1
       endif
       
       if (kfum==0) then
          fum = 0.0
          rum = 0.0
          u1m = 0.0
          qm = 0.0
          q0m = 0.0
          return
       endif

       if (smax + scr<=1.5d0*(smin + scr)) then
          !       submerged flow
          state = 2
          cu    = 2*gravity/(StructureDynamicsFactor*dxm)
          !       ARS 4681 improved wetted area computation
          aum   = max(smax - u0m**2/(2d0*gravity) + scr, 2.0d0/3.0d0*(smax + scr))*swi
          uweir = dsqrt(gravity*2d0*(smax - smin))
          rhsc  = 0.0
       else
          !       free flow
          state = 1
          cu    = gravity/(1.5*(StructureDynamicsFactor*dxm))
          aum   = 2./3.*(smax + scr)*swi
          uweir = dsqrt(2./3.*gravity*(smax + scr))

          if (s1m2>s1m1) then
             rhsc = -cu*(s1m1 + scr)
          else
             rhsc =  cu*(s1m2 + scr)
          endif

       endif
       aum   = aum*weir%cmu  ! cmu out of the lines above, just as factor on au, jira 19171
       dadsm = swi
       fr    = uweir/(StructureDynamicsFactor*dxm)
       dxdt = 1.0/dt

       call furu_iter(fum, rum, s1m2, s1m1, u1m, u0m, q0m, aum, fr, cu, rhsc, dxdt)

   end subroutine ComputeWeir
 
end module m_Weir
