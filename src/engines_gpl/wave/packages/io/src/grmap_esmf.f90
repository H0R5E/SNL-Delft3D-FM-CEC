subroutine grmap_esmf(i1, f1, n1, f2, mmax, nmax, f2s, f2g, adaptCovered)
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
!  $Id: grmap_esmf.f90 61657 2018-09-10 22:40:14Z j.reyns $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/engines_gpl/wave/packages/io/src/grmap_esmf.f90 $
!!--description-----------------------------------------------------------------
!
! http://www.earthsystemmodeling.org/esmf_releases/last_built/ESMF_refdoc/node3.html
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use swan_flow_grid_maps
    use mathconsts
    !
    implicit none
!
! Global variables
!
    integer                   , intent(in)  :: i1
    integer                   , intent(in)  :: n1
    integer                   , intent(in)  :: mmax
    integer                   , intent(in)  :: nmax
    real   , dimension(n1)    , intent(in)  :: f1
    real   , dimension(mmax,nmax)           :: f2
    type(grid_map)            , intent(in)  :: f2s
    type(grid)                              :: f2g  ! f2 grid
    logical                   , optional    :: adaptCovered
!
! Local variables
!
    integer :: i
    integer :: j
    integer :: n
    integer :: n2
    logical :: adaptCovered_
!
!! executable statements -------------------------------------------------------
!
    if (.not.f2s%grids_linked) return
    n2 = mmax * nmax
    !if (present(adaptCovered)) then
    !    adaptCovered_ = adaptCovered
    !else
    !    adaptCovered_ = .false.
    !endif
    !!
    !if (adaptCovered_) then
    !   if (f2s%sferic) then
    !      do n=1, f2s%n_s
    !         i       = floor(real(f2s%row(n)-1)/real(nmax)) + 1
    !         j       = f2s%row(n) - nmax*(i-1)
    !         if (      comparereal(abs(f1(f2s%col(n))),999.1) == -1 &
    !           & .and. comparereal(abs(f1(f2s%col(n))),998.9) ==  1) then
    !            f2g%covered(i,j) = 0
    !         endif
    !      enddo
    !   else
    !      do n=1, f2s%n_s
    !         j       = floor(real(f2s%row(n)-1)/real(mmax)) + 1
    !         i       = f2s%row(n) - mmax*(j-1)
    !         if (      comparereal(abs(f1(f2s%col(n))),999.1) == -1 &
    !           & .and. comparereal(abs(f1(f2s%col(n))),998.9) ==  1) then
    !            f2g%covered(i,j) = 0
    !         endif
    !      enddo
    !   endif
    !endif
    !
    ! f2 already contains valid data
    ! Only replace f2 values when covered by f1
    ! Start with setting f2=0 for covered points only
    !
    do i=1, mmax
       do j=1, nmax
          if (f2g%covered(i,j) == i1) then
             f2(i,j) = 0.0_sp
          endif
       enddo
    enddo
    !
    if (f2s%sferic) then
       do n=1, f2s%n_s
          i       = floor(real(f2s%row(n)-1)/real(nmax)) + 1
          j       = f2s%row(n) - nmax*(i-1)
          if (f2g%covered(i,j) == i1) then
             f2(i,j) = f2(i,j) + f2s%s(n)*f1(f2s%col(n))
          endif
          !
          ! The following method (without conversion to i,j) does not work:
          ! f2(f2s%row(n)) = f2(f2s%row(n)) + f2s%s(n)*f1(f2s%col(n))
          ! Probably because f2 is mapped different when passed through as 1D array
          !
       enddo
    else
       do n=1, f2s%n_s
          j       = floor(real(f2s%row(n)-1)/real(mmax)) + 1
          i       = f2s%row(n) - mmax*(j-1)   
          !
          if (f2g%covered(i,j)== i1) then
             f2(i,j) = f2(i,j) + f2s%s(n)*f1(f2s%col(n))    ! generate_partioning_pol_from_idomain
          endif
       enddo
       
       
       
       !! Only works with structured grids:
       !do n3d=1, f2s%n_s/4
       !   n = n3d + floor(real(n3d-1)/4.0)*4
       !   ! n3d = 5,6,7,8,13,14,15,16,21,22,23,24: contribution of points at z=1 so skip
       !   ! => use n instead of n3d
       !   ! n > n_s/2: This point is at z=1 (instead of z=0) so skip
       !   ! => stop when n > n_s/2 (n3d>n_s/4)
       !   j       = floor(real(f2s%row(n)-1)/real(mmax)) + 1
       !   i       = f2s%row(n) - mmax*(j-1)
       !   !if (f2g%covered(i,j) == 1) then
       !      f2(i,j) = f2(i,j) + f2s%s(n)*f1(f2s%col(n))
       !   !endif
       !enddo

       ! Not needed when using bilinear interpolation:
       !do n=1, f2s%n_b
       !   if (f2s%frac_b(n) /= 0.0_hp) then
       !      j       = floor(real(n-1)/real(mmax)) + 1
       !      i       = n - mmax*(j-1)
       !      !if (f2g%covered(i,j) == 1) then
       !         f2(i,j) = f2(i,j)/f2s%frac_b(n)
       !      !endif
       !   endif
       !enddo
    endif
end subroutine grmap_esmf
