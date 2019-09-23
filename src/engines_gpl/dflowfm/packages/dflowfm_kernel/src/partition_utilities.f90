!----- AGPL --------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2017-2018.                                
!                                                                               
!  This file is part of Delft3D (D-Flow Flexible Mesh component).               
!                                                                               
!  Delft3D is free software: you can redistribute it and/or modify              
!  it under the terms of the GNU Affero General Public License as               
!  published by the Free Software Foundation version 3.                         
!                                                                               
!  Delft3D  is distributed in the hope that it will be useful,                  
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU Affero General Public License for more details.                          
!                                                                               
!  You should have received a copy of the GNU Affero General Public License     
!  along with Delft3D.  If not, see <http://www.gnu.org/licenses/>.             
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D",                  
!  "D-Flow Flexible Mesh" and "Deltares" are registered trademarks of Stichting 
!  Deltares, and remain the property of Stichting Deltares. All rights reserved.
!                                                                               
!-------------------------------------------------------------------------------
 
!> Parition of an mdu file with proper settings modified and rest copied
subroutine partition_mdu()   
   use unstruc_model, only:  md_netfile, md_Ndomains, md_jacontiguous, md_icgsolver, md_pmethod, md_mdu, md_ident, md_restartfile, md_mapfile, md_flowgeomfile, md_partitionfile
   use m_flowparameters, only: icgsolver  
   use m_partitioninfo, only: md_genpolygon, Ndomains
   implicit none
      
   integer                   :: i, L 
   integer                   :: Lrst = 0, Lmap = 0, L_merge = 0, jamergedrst = 0, Lmap1 = 0
   integer, parameter        :: numlen=4        !< number of digits in domain number string/filename
   integer, parameter        :: maxnamelen=256  !< number of digits in filename 
   character(len=numlen)     :: sdmn_loc        !< domain number string
   character(len=maxnamelen) :: filename        
   character(len=maxnamelen) :: restartfile     !< storing the name of the restart files
   character(len=maxnamelen) :: md_mapfile_base !< storing the user-defined map file
   character(len=maxnamelen) :: md_flowgeomfile_base !< storing the user-defined flowgeom file
 

      
   icgsolver = md_icgsolver
   call partition_from_commandline(md_netfile, md_Ndomains, md_jacontiguous, icgsolver, md_pmethod)
   L    = index(md_netfile, '_net')-1
   md_mdu = md_ident
   if (len_trim(md_restartfile) > 0) then ! If there is a restart file
      L_merge = index(md_restartfile, '_merged')
      if (L_merge > 0) then
         jamergedrst = 1
      else ! restart file is not a merged map file, then provide _rst or _map file of each subdomain
         restartfile = md_restartfile
         Lrst = index(restartfile, '_rst.nc')
         Lmap = index(restartfile, '_map.nc')
   endif   
   endif
          
   md_mapfile_base = md_mapfile
   md_flowgeomfile_base = md_flowgeomfile
   do i = 0,  Ndomains - 1
      write(sdmn_loc, '(I4.4)') i
      md_netfile = trim(md_netfile(1:L)//'_'//sdmn_loc//'_net.nc')
      if (md_genpolygon .eq. 1) then
         md_partitionfile = trim(md_netfile(1:L))//'_part.pol' 
      endif
      if (jamergedrst == 0) then ! restart file is not a merged map file, then provide _rst or _map file of each subdomain 
      if (Lrst > 0) then      ! If the restart file is a rst file
         md_restartfile = trim(restartfile(1:Lrst-16)//sdmn_loc//'_'//restartfile(Lrst-15: Lrst+7))
      else if (Lmap > 0) then ! If the restart file is a map file
         md_restartfile = trim(restartfile(1:Lmap)//sdmn_loc//'_map.nc')
      endif
      endif
      if (len_trim(md_mapfile_base)>0) then
         Lmap1 = index(md_mapfile_base, '_map.nc')
         if (Lmap1 == 0) then    ! Customized map-file name
            md_mapfile = md_mapfile_base(1:index(trim(md_mapfile_base)//'.','.')-1)//'_'//sdmn_loc//".nc"
         else
            md_mapfile = md_mapfile_base(1:index(trim(md_mapfile_base)//'.','_map')-1)//'_'//sdmn_loc//"_map.nc"
         endif
      endif
      if (len_trim(md_flowgeomfile_base)>0) then
         md_flowgeomfile = md_flowgeomfile_base(1:index(md_flowgeomfile_base,'.nc',back=.true.)-1)//'_'//sdmn_loc//".nc"
      endif
      call generatePartitionMDUFile(trim(md_ident)//'.mdu', trim(md_mdu)//'_'//sdmn_loc//'.mdu')
   enddo
end subroutine partition_mdu