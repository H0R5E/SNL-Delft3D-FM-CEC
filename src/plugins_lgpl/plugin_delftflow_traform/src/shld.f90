function shld(dstar     )
!----- GPL ---------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2018.                                
!                                                                               
!  This program is free software: you can redistribute it and/or modify         
!  it under the terms of the GNU General Public License as published by         
!  the Free Software Foundation version 3.                                      
!                                                                               
!  This program is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU General Public License for more details.                                 
!                                                                               
!  You should have received a copy of the GNU General Public License            
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
!  $Id: shld.f90 7992 2018-01-09 10:27:35Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/SANDIA/fm_tidal/src/plugins_lgpl/plugin_delftflow_traform/src/shld.f90 $
!!--description-----------------------------------------------------------------
!
! determines shields parameter according
! to shields curve
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    implicit none
!
! Local constants
! Interface is in high precision
!
integer        , parameter :: hp   = kind(1.0d0)
!
! Global variables
!
    real(hp), intent(in) :: dstar ! critical dimensionless grain size parameter
    real(hp)         :: shld
!
!! executable statements -------------------------------------------------------
!
    if (dstar<=4.) then
       shld = 0.240/dstar
    elseif (dstar<=10.) then
       shld = 0.140/dstar**0.64
    elseif (dstar<=20.) then
       shld = 0.040/dstar**0.10
    elseif (dstar<=150.) then
       shld = 0.013*dstar**0.29
    else
       shld = 0.055
    endif
end function shld
