!----- LGPL --------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2018.                                
!                                                                               
!  This library is free software; you can redistribute it and/or                
!  modify it under the terms of the GNU Lesser General Public                   
!  License as published by the Free Software Foundation version 2.1.                 
!                                                                               
!  This library is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
!  Lesser General Public License for more details.                              
!                                                                               
!  You should have received a copy of the GNU Lesser General Public             
!  License along with this library; if not, see <http://www.gnu.org/licenses/>. 
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

! $Id: meshdata.F90 59855 2018-08-16 14:05:22Z carniato $
! $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/utils_lgpl/io_netcdf/packages/io_netcdf/src/meshdata.F90 $

!> Module for grid operations.

module meshdata

use iso_c_binding


implicit none

integer, parameter :: ug_strLenMeta      = 100
integer, parameter :: ug_idsLen          = 40
integer, parameter :: ug_idsLongNamesLen = 80

!> Structure for storing an entire mesh geometry (topology and coordinates and more).
!> This is general data structures shared also by gridgeom
type t_ug_meshgeom
! TODO: AvD: extend this to 3D (volumes)
   character(len=256) :: meshname                !< Name of this mesh ! TODO: AvD: should this be in this data type?
   integer            :: dim             = -1    !< Dimensionality of the mesh (1/2/3)
   integer            :: numnode         = -1    !< Number of mesh nodes.
   integer            :: numedge         = -1    !< Number of mesh edges (size of kn)
   integer            :: numface         = -1    !< Number of mesh faces.
   integer            :: maxnumfacenodes = -1    !< Maximum of number of face nodes.
   integer            :: numlayer        = -1    !< Number of mesh layers (num interfaces == numlayer + 1), numlayer = 0 means "no layers".
   integer            :: layertype       = -1    !< Type of vertical layer definition (only if numlayer >= 1), one of LAYERTYPE_* parameters.
   integer            :: nnodes          = -1    !< Number of branches
   integer            :: nbranches       = -1    !< Number of branches
   integer            :: ngeometry       = -1    !< Number of geometrical points
   integer            :: start_index     = -1    !< The base index of the arrays
   integer            :: epsg            = -1    !< epsg code that uniquely identifies the coordinate reference system 

   integer, pointer :: edge_nodes(:,:) => null() !< Edge-to-node mapping array.
   integer, pointer :: face_nodes(:,:) => null() !< Face-to-node mapping array.
   integer, pointer :: edge_faces(:,:) => null() !< Edge-to-face mapping array (optional, can be null()).
   integer, pointer :: face_edges(:,:) => null() !< Face-to-edge mapping array (optional, can be null()).
   integer, pointer :: face_links(:,:) => null() !< Face-to-face mapping array (optional, can be null()).
   
   !Network1d variables
   double precision,                  pointer :: nnodex(:) => null()                 !< x-coordinates of the network points.
   double precision,                  pointer :: nnodey(:) => null()                 !< y-coordinates of the network points.
   character(len=ug_idsLen),          pointer :: nnodeids(:) => null()               !< network nodes ids description 
   character(len=ug_idsLongNamesLen), pointer :: nnodelongnames(:) => null()         !< network nodes nnodelongnames description 

   integer,                           pointer :: nedge_nodes(:,:) => null()          !< Start-end node of each branch
   character(len=ug_idsLen),          pointer :: nbranchids(:) => null()             !< Branch nodes ids 
   character(len=ug_idsLongNamesLen), pointer :: nbranchlongnames(:) => null()       !< Branch long names
   double precision,                  pointer :: nbranchlengths(:) => null()         !< Branch lenghts
   integer,                           pointer :: nbranchgeometrynodes(:) => null()   !< Number of geometry points in each branch
   double precision,                  pointer :: ngeopointx(:) => null()             !< x-coordinates of geometry points.
   double precision,                  pointer :: ngeopointy(:) => null()             !< y-coordinates of geometry points.
   integer,                           pointer :: nbranchorder(:) => null()           !< the branch order
   
   !Mesh1d variables
   integer,                           pointer :: branchidx(:) => null()              !< The branch index of each 1d mesh point
   double precision,                  pointer :: branchoffsets(:)=> null()           !< The branch offset of each 1d mesh point

   double precision, pointer :: nodex(:)=> null()       !< x-coordinates of the mesh nodes.
   double precision, pointer :: nodey(:)=> null()       !< y-coordinates of the mesh nodes.
   double precision, pointer :: nodez(:)=> null()       !< z-coordinates of the mesh nodes.
   double precision, pointer :: edgex(:)=> null()       !< x-coordinates of the mesh edges.
   double precision, pointer :: edgey(:)=> null()       !< y-coordinates of the mesh edges.
   double precision, pointer :: edgez(:)=> null()       !< z-coordinates of the mesh edges.
   double precision, pointer :: facex(:)=> null()       !< x-coordinates of the mesh faces.
   double precision, pointer :: facey(:)=> null()       !< y-coordinates of the mesh faces.
   double precision, pointer :: facez(:)=> null()       !< z-coordinates of the mesh faces.
   
   double precision, pointer :: layer_zs(:) => null()    !< Vertical coordinates of the mesh layers' center (either z or sigma).
   double precision, pointer :: interface_zs(:)=> null() !< Vertical coordinates of the mesh layers' interface (either z or sigma).

end type t_ug_meshgeom

type, bind(C) :: c_t_ug_meshgeomdim

   type(c_ptr)              :: meshname           !< Name of this mesh ! TODO: AvD: should this be in this data type?
   integer(kind=c_int)      :: dim                !< Dimensionality of the mesh (1/2/3)
   integer(kind=c_int)      :: numnode            !< Number of mesh nodes.
   integer(kind=c_int)      :: numedge            !< Number of mesh edges.
   integer(kind=c_int)      :: numface            !< Number of mesh faces.
   integer(kind=c_int)      :: maxnumfacenodes    !< Maximum of number of face nodes.
   integer(kind=c_int)      :: numlayer           !< Number of mesh layers (num interfaces == numlayer + 1), numlayer = 0 means "no layers".
   integer(kind=c_int)      :: layertype          !< Type of vertical layer definition (only if numlayer >= 1), one of LAYERTYPE_* parameters.
   integer(kind=c_int)      :: nnodes
   integer(kind=c_int)      :: nbranches          !< Number of branches
   integer(kind=c_int)      :: ngeometry          !< Number of geometry points
   integer(kind=c_int)      :: epsg               !< epsg code that uniquely identifies the coordinate reference system 
   
end type c_t_ug_meshgeomdim

type, bind(C) :: c_t_ug_meshgeom

   type(c_ptr) :: edge_nodes              !< Edge-to-node mapping array.
   type(c_ptr) :: face_nodes              !< Face-to-node mapping array.
   type(c_ptr) :: edge_faces              !< Edge-to-face mapping array (optional, can be null()).
   type(c_ptr) :: face_edges              !< Face-to-edge mapping array (optional, can be null()).
   type(c_ptr) :: face_links              !< Face-to-face mapping array (optional, can be null()).
   
   !Mesh 1d variables
   type(c_ptr)  :: nnodex                 !< x-coordinates of the network points.  
   type(c_ptr)  :: nnodey                 !< y-coordinates of the network points.
   type(c_ptr)  :: nedge_nodes            !< Start-end node of each branch                
   type(c_ptr)  :: nbranchlengths         !< The branch lenghts  
   type(c_ptr)  :: nbranchgeometrynodes   !< Number of geometry points in each branch
   type(c_ptr)  :: ngeopointx             !< x-coordinates of geometry points.
   type(c_ptr)  :: ngeopointy             !< y-coordinates of geometry points.
   type(c_ptr)  :: nbranchorder           !< the branch order
   
   type(c_ptr)  :: branchidx              !< The branch index of each 1d mesh point
   type(c_ptr)  :: branchoffsets          !< The branch offset of each 1d mesh point
   
   type(c_ptr) :: nodex                   !< x-coordinates of the mesh nodes.
   type(c_ptr) :: nodey                   !< y-coordinates of the mesh nodes.
   type(c_ptr) :: nodez                   !< z-coordinates of the mesh nodes.
   type(c_ptr) :: edgex                   !< x-coordinates of the mesh edges.
   type(c_ptr) :: edgey                   !< y-coordinates of the mesh edges.
   type(c_ptr) :: edgez                   !< z-coordinates of the mesh edges.
   type(c_ptr) :: facex                   !< x-coordinates of the mesh faces.
   type(c_ptr) :: facey                   !< y-coordinates of the mesh faces.
   type(c_ptr) :: facez                   !< z-coordinates of the mesh faces.
   
   type(c_ptr)  :: layer_zs               !< Vertical coordinates of the mesh layers' center (either z or sigma).
   type(c_ptr)  :: interface_zs           !< Vertical coordinates of the mesh layers' interface (either z or sigma).

end type c_t_ug_meshgeom

   contains 
   
function convert_meshgeom_to_cptr(meshgeom, c_meshgeom, c_meshgeomdim) result(ierr)

   type(t_ug_meshgeom), intent(in)         :: meshgeom
   type(c_t_ug_meshgeom), intent(inout)    :: c_meshgeom
   type(c_t_ug_meshgeomdim), intent(inout) :: c_meshgeomdim
   integer                                 :: ierr
   !support variables
   integer,          pointer  :: edge_nodes(:,:) => null()!< Edge-to-node mapping array.
   integer,          pointer  :: face_nodes(:,:) => null()!< Face-to-node mapping array.
   integer,          pointer  :: edge_faces(:,:) => null()!< Edge-to-face mapping array (optional, can be null()).
   integer,          pointer  :: face_edges(:,:) => null()!< Face-to-edge mapping array (optional, can be null()).
   integer,          pointer  :: face_links(:,:) => null()!< Face-to-face mapping array (optional, can be null()).
   
   !Network1d variables
   double precision, pointer :: nnodex(:) => null() 
   double precision, pointer :: nnodey(:) => null() 
   integer,          pointer :: nedge_nodes(:,:) => null()        
   double precision, pointer :: nbranchlengths(:) => null() 
   integer,          pointer :: nbranchgeometrynodes(:)=> null()  
   double precision, pointer :: ngeopointx(:) => null() 
   double precision, pointer :: ngeopointy(:)   => null() 
   integer,          pointer :: nbranchorder(:) => null()   
   !Mesh1d variables
   integer,          pointer :: branchidx(:) => null()    !< Branch id of each mesh node 
   double precision, pointer :: branchoffsets(:)=> null() !< Branch offset of each mesh node
   
   double precision, pointer :: nodex(:) => null()       !< x-coordinates of the mesh nodes.
   double precision, pointer :: nodey(:) => null()      !< y-coordinates of the mesh nodes.
   double precision, pointer :: nodez(:) => null()      !< z-coordinates of the mesh nodes.
   double precision, pointer :: edgex(:) => null()      !< x-coordinates of the mesh edges.
   double precision, pointer :: edgey(:) => null()      !< y-coordinates of the mesh edges.
   double precision, pointer :: edgez(:) => null()      !< z-coordinates of the mesh edges.
   double precision, pointer :: facex(:) => null()      !< x-coordinates of the mesh faces.
   double precision, pointer :: facey(:) => null()      !< y-coordinates of the mesh faces.
   double precision, pointer :: facez(:) => null()      !< z-coordinates of the mesh faces.

   double precision, pointer :: layer_zs(:) => null()     !< Vertical coordinates of the mesh layers' center (either z or sigma).
   double precision, pointer :: interface_zs(:) => null() !< Vertical coordinates of the mesh layers' interface (either z or sigma).
   
   ierr = 0
   !dimension variables
   c_meshgeomdim%dim = meshgeom%dim                
   c_meshgeomdim%numnode = meshgeom%numnode          
   c_meshgeomdim%numedge = meshgeom%numedge           
   c_meshgeomdim%numface = meshgeom%numface          
   c_meshgeomdim%maxnumfacenodes = meshgeom%maxnumfacenodes   
   c_meshgeomdim%numlayer = meshgeom%numlayer          
   c_meshgeomdim%layertype = meshgeom%layertype  
   
   c_meshgeomdim%nnodes = meshgeom%nnodes  
   c_meshgeomdim%nbranches = meshgeom%nbranches       
   c_meshgeomdim%ngeometry = meshgeom%ngeometry
   c_meshgeomdim%epsg = meshgeom%epsg
   
   !! array variables
   if (associated(meshgeom%edge_nodes)) then
      call c_f_pointer(c_meshgeom%edge_nodes, edge_nodes, shape(meshgeom%edge_nodes))
      edge_nodes = meshgeom%edge_nodes
   endif
   
   if (associated(meshgeom%face_nodes)) then
      call c_f_pointer(c_meshgeom%face_nodes, face_nodes, shape(meshgeom%face_nodes))
      face_nodes= meshgeom%face_nodes
   endif
   
   if (associated(meshgeom%edge_faces)) then
      call c_f_pointer(c_meshgeom%edge_faces, edge_faces, shape(meshgeom%edge_faces))
      edge_faces= meshgeom%edge_faces
   endif
   
   if (associated(meshgeom%face_edges)) then
      call c_f_pointer(c_meshgeom%face_edges, face_edges, shape(meshgeom%face_edges))
      face_edges= meshgeom%face_edges
   endif
   
   if (associated(meshgeom%face_links)) then
      call c_f_pointer(c_meshgeom%face_links, face_links, shape(face_links))
      face_links= meshgeom%face_links
   endif
   
   !Network1d variables
   if (associated(meshgeom%nnodex)) then
      call c_f_pointer(c_meshgeom%nnodex, nnodex, shape(meshgeom%nnodex))
      nnodex = meshgeom%nnodex
   endif
   
   if (associated(meshgeom%nnodey)) then
      call c_f_pointer(c_meshgeom%nnodey, nnodey,shape(meshgeom%nnodey))
      nnodey = meshgeom%nnodey
   endif
   
   if (associated(meshgeom%nedge_nodes)) then
      call c_f_pointer(c_meshgeom%nedge_nodes,nedge_nodes , shape(meshgeom%nedge_nodes))
      nedge_nodes= meshgeom%nedge_nodes
   endif
   
   if (associated(meshgeom%nbranchlengths)) then
      call c_f_pointer(c_meshgeom%nbranchlengths, nbranchlengths, shape(meshgeom%nbranchlengths))
      nbranchlengths= meshgeom%nbranchlengths
   endif
   
   if (associated(meshgeom%nbranchgeometrynodes)) then
      call c_f_pointer(c_meshgeom%nbranchgeometrynodes, nbranchgeometrynodes , shape(meshgeom%nbranchgeometrynodes))
      nbranchgeometrynodes = meshgeom%nbranchgeometrynodes
   endif
   
   if (associated(meshgeom%ngeopointx)) then
      call c_f_pointer(c_meshgeom%ngeopointx, ngeopointx , shape(meshgeom%ngeopointx))
      ngeopointx = meshgeom%ngeopointx
   endif
   
   if (associated(meshgeom%ngeopointy)) then
      call c_f_pointer(c_meshgeom%ngeopointy, ngeopointy , shape(meshgeom%ngeopointy))
      ngeopointy = meshgeom%ngeopointy
   endif
   
   if (associated(meshgeom%nbranchorder)) then
      call c_f_pointer(c_meshgeom%nbranchorder, nbranchorder, shape(meshgeom%nbranchorder))
      nbranchorder = meshgeom%nbranchorder
   endif
   
   !Mesh1d
   if (associated(meshgeom%branchidx)) then
      call c_f_pointer(c_meshgeom%branchidx, branchidx, shape(meshgeom%branchidx))
      branchidx = meshgeom%branchidx
   endif
      
   if (associated(meshgeom%branchoffsets)) then
      call c_f_pointer(c_meshgeom%branchoffsets, branchoffsets, shape(meshgeom%branchoffsets))
      branchoffsets = meshgeom%branchoffsets
   endif
               
   !mesh nodes
   if (associated(meshgeom%nodex)) then
      call c_f_pointer(c_meshgeom%nodex, nodex, shape(meshgeom%nodex))
      nodex = meshgeom%nodex
   endif

   if (associated(meshgeom%nodey)) then
      call c_f_pointer(c_meshgeom%nodey, nodey, shape(meshgeom%nodey))
      nodey = meshgeom%nodey
   endif
   
   if (associated(meshgeom%nodez)) then
      call c_f_pointer(c_meshgeom%nodez, nodez, shape(meshgeom%nodez))
      nodez = meshgeom%nodez
   endif

   !mesh edges
   if (associated(meshgeom%edgex)) then
      call c_f_pointer(c_meshgeom%edgex, edgex, shape(meshgeom%edgex))
      edgex= meshgeom%edgex
   endif
   if (associated(meshgeom%edgey)) then
      call c_f_pointer(c_meshgeom%edgey, edgey, shape(meshgeom%edgey))
      edgey= meshgeom%edgey
   endif
   if (associated(meshgeom%edgez)) then
      call c_f_pointer(c_meshgeom%edgez, edgez, shape(meshgeom%edgez))
      edgez= meshgeom%edgez
   endif   
   
   !mesh faces
   if (associated(meshgeom%facex)) then
      call c_f_pointer(c_meshgeom%facex, facex, shape(meshgeom%facex))
      facex= meshgeom%facex
   endif
   if (associated(meshgeom%facey)) then
      call c_f_pointer(c_meshgeom%facey, facey, shape(meshgeom%facey))
      facey= meshgeom%facey
   endif
   if (associated(meshgeom%facez)) then
      call c_f_pointer(c_meshgeom%facez, facez, shape(meshgeom%facez))
      facez= meshgeom%facez
   endif
   
   !layer
   if (associated(meshgeom%layer_zs)) then
      call c_f_pointer(c_meshgeom%layer_zs, layer_zs, shape(meshgeom%layer_zs))
      layer_zs= meshgeom%layer_zs
   endif

   !interface
   if (associated(meshgeom%interface_zs)) then
      call c_f_pointer(c_meshgeom%interface_zs, interface_zs, shape(meshgeom%interface_zs))
      interface_zs= meshgeom%interface_zs
   endif
   
end function convert_meshgeom_to_cptr


function convert_cptr_to_meshgeom(c_meshgeom, c_meshgeomdim, meshgeom) result(ierr)

   type(c_t_ug_meshgeom), intent(in)      :: c_meshgeom
   type(c_t_ug_meshgeomdim), intent(in)   :: c_meshgeomdim
   type(t_ug_meshgeom), intent(inout)     :: meshgeom
   integer                                :: ierr
   
   ! get the dimensions
   
   meshgeom%dim = c_meshgeomdim%dim                
   meshgeom%numnode = c_meshgeomdim%numnode           
   meshgeom%numedge = c_meshgeomdim%numedge           
   meshgeom%numface = c_meshgeomdim%numface          
   meshgeom%maxnumfacenodes = c_meshgeomdim%maxnumfacenodes    
   meshgeom%numlayer = c_meshgeomdim%numlayer          
   meshgeom%layertype = c_meshgeomdim%layertype   
   
   meshgeom%nnodes = c_meshgeomdim%nnodes  
   meshgeom%nbranches = c_meshgeomdim%nbranches       
   meshgeom%ngeometry = c_meshgeomdim%ngeometry
   meshgeom%epsg = c_meshgeomdim%epsg
  
   ierr = 0
   
   if(c_associated(c_meshgeom%edge_nodes)) call c_f_pointer(c_meshgeom%edge_nodes, meshgeom%edge_nodes, (/ 2, c_meshgeomdim%numedge /)) 
   if(c_associated(c_meshgeom%face_nodes)) call c_f_pointer(c_meshgeom%face_nodes, meshgeom%face_nodes, (/ c_meshgeomdim%maxnumfacenodes, c_meshgeomdim%numface /))
   if(c_associated(c_meshgeom%edge_faces)) call c_f_pointer(c_meshgeom%edge_faces, meshgeom%edge_faces, (/ 2, c_meshgeomdim%numedge /))
   if(c_associated(c_meshgeom%face_edges)) call c_f_pointer(c_meshgeom%face_edges, meshgeom%face_edges, (/ c_meshgeomdim%maxnumfacenodes, c_meshgeomdim%numface /))
   if(c_associated(c_meshgeom%face_links)) call c_f_pointer(c_meshgeom%face_links, meshgeom%face_links, (/ c_meshgeomdim%maxnumfacenodes, c_meshgeomdim%numface /))
   
   !Network variables 
   if(c_associated(c_meshgeom%nnodex)) call c_f_pointer(c_meshgeom%nnodex, meshgeom%nnodex,(/c_meshgeomdim%nnodes/))
   if(c_associated(c_meshgeom%nnodey)) call c_f_pointer(c_meshgeom%nnodey, meshgeom%nnodey,(/c_meshgeomdim%nnodes/))
   !nodeids and nodelongnames are not communicated using meshgeom
   if(c_associated(c_meshgeom%nedge_nodes)) call c_f_pointer(c_meshgeom%nedge_nodes, meshgeom%nedge_nodes, (/ 2, c_meshgeomdim%nbranches /))   
   !branchids and branchlongnames are not communicated using meshgeom
   if(c_associated(c_meshgeom%nbranchlengths)) call c_f_pointer(c_meshgeom%nbranchlengths, meshgeom%nbranchlengths, (/ c_meshgeomdim%nbranches /))
   if(c_associated(c_meshgeom%nbranchgeometrynodes)) call c_f_pointer(c_meshgeom%nbranchgeometrynodes, meshgeom%nbranchgeometrynodes, (/ c_meshgeomdim%nbranches /))   
   if(c_associated(c_meshgeom%ngeopointx)) call c_f_pointer(c_meshgeom%ngeopointx, meshgeom%ngeopointx, (/ c_meshgeomdim%ngeometry/))
   if(c_associated(c_meshgeom%ngeopointy)) call c_f_pointer(c_meshgeom%ngeopointy, meshgeom%ngeopointy, (/ c_meshgeomdim%ngeometry/))   
   if(c_associated(c_meshgeom%nbranchorder)) call c_f_pointer(c_meshgeom%nbranchorder, meshgeom%nbranchorder, (/ c_meshgeomdim%nbranches/))   
   
   !Mesh1d variables
   if(c_associated(c_meshgeom%branchidx)) call c_f_pointer(c_meshgeom%branchidx, meshgeom%branchidx, (/ c_meshgeomdim%numnode/))
   if(c_associated(c_meshgeom%branchoffsets)) call c_f_pointer(c_meshgeom%branchoffsets, meshgeom%branchoffsets, (/ c_meshgeomdim%numnode /))   
   
   if(c_associated(c_meshgeom%nodex)) call c_f_pointer(c_meshgeom%nodex, meshgeom%nodex,(/c_meshgeomdim%numnode/))
   if(c_associated(c_meshgeom%nodey)) call c_f_pointer(c_meshgeom%nodey, meshgeom%nodey,(/c_meshgeomdim%numnode/))
   if(c_associated(c_meshgeom%nodez)) call c_f_pointer(c_meshgeom%nodez, meshgeom%nodez,(/c_meshgeomdim%numnode/))
   if(c_associated(c_meshgeom%edgex)) call c_f_pointer(c_meshgeom%edgex, meshgeom%edgex,(/c_meshgeomdim%numedge/))
   if(c_associated(c_meshgeom%edgey)) call c_f_pointer(c_meshgeom%edgey, meshgeom%edgey,(/c_meshgeomdim%numedge/))
   if(c_associated(c_meshgeom%edgez)) call c_f_pointer(c_meshgeom%edgez, meshgeom%edgez,(/c_meshgeomdim%numedge/)) 
   if(c_associated(c_meshgeom%facex)) call c_f_pointer(c_meshgeom%facex, meshgeom%facex,(/c_meshgeomdim%numface/))
   if(c_associated(c_meshgeom%facey)) call c_f_pointer(c_meshgeom%facey, meshgeom%facey,(/c_meshgeomdim%numface/))
   if(c_associated(c_meshgeom%facez)) call c_f_pointer(c_meshgeom%facez, meshgeom%facez,(/c_meshgeomdim%numface/))
   if(c_associated(c_meshgeom%layer_zs)) call c_f_pointer(c_meshgeom%layer_zs, meshgeom%layer_zs,(/c_meshgeomdim%numlayer/))
   if(c_associated(c_meshgeom%interface_zs)) call c_f_pointer(c_meshgeom%interface_zs, meshgeom%interface_zs,(/c_meshgeomdim%numlayer + 1/))
      
end function convert_cptr_to_meshgeom

!> by deallocating what is associated, no memory leaks
function t_ug_meshgeom_destructor(meshgeom) result(ierr)

   type(t_ug_meshgeom) :: meshgeom
   integer  :: ierr
   
   if(associated(meshgeom%edge_nodes)) deallocate(meshgeom%edge_nodes)
   if(associated(meshgeom%face_nodes)) deallocate(meshgeom%face_nodes)
   if(associated(meshgeom%edge_faces)) deallocate(meshgeom%edge_faces)
   if(associated(meshgeom%face_edges)) deallocate(meshgeom%face_edges)
   if(associated(meshgeom%face_links)) deallocate(meshgeom%face_links)
   
   
   if(associated(meshgeom%nnodex)) deallocate(meshgeom%nnodex)
   if(associated(meshgeom%nnodey)) deallocate(meshgeom%nnodey)
   if(associated(meshgeom%nnodeids)) deallocate(meshgeom%nnodeids)
   if(associated(meshgeom%nnodelongnames)) deallocate(meshgeom%nnodelongnames)
   if(associated(meshgeom%nedge_nodes)) deallocate(meshgeom%nedge_nodes)
   if(associated(meshgeom%nbranchids)) deallocate(meshgeom%nbranchids)
   if(associated(meshgeom%nbranchlongnames)) deallocate(meshgeom%nbranchlongnames)
   
   if(associated(meshgeom%nbranchlengths)) deallocate(meshgeom%nbranchlengths)
   if(associated(meshgeom%nbranchgeometrynodes)) deallocate(meshgeom%nbranchgeometrynodes)
   if(associated(meshgeom%ngeopointx)) deallocate(meshgeom%ngeopointx)
   if(associated(meshgeom%ngeopointy)) deallocate(meshgeom%ngeopointy)
   if(associated(meshgeom%nbranchorder)) deallocate(meshgeom%nbranchorder)
   
   if(associated(meshgeom%branchidx)) deallocate(meshgeom%branchidx)
   if(associated(meshgeom%branchoffsets)) deallocate(meshgeom%branchoffsets)
   
   if(associated(meshgeom%nodex)) deallocate(meshgeom%nodex)
   if(associated(meshgeom%nodey)) deallocate(meshgeom%nodey)
   if(associated(meshgeom%nodez)) deallocate(meshgeom%nodez)
   if(associated(meshgeom%edgex)) deallocate(meshgeom%edgex)
   if(associated(meshgeom%edgey)) deallocate(meshgeom%edgey)
   
   if(associated(meshgeom%edgez)) deallocate(meshgeom%edgez)
   if(associated(meshgeom%facex)) deallocate(meshgeom%facex)
   if(associated(meshgeom%facey)) deallocate(meshgeom%facey)
   if(associated(meshgeom%facez)) deallocate(meshgeom%facez)
   if(associated(meshgeom%layer_zs)) deallocate(meshgeom%layer_zs)
   if(associated(meshgeom%interface_zs)) deallocate(meshgeom%interface_zs)
   
   
   meshgeom%dim             = -1 
   meshgeom%numnode         = -1    
   meshgeom%numedge         = -1    
   meshgeom%numface         = -1    
   meshgeom%maxnumfacenodes = -1    
   meshgeom%numlayer        = -1    
   meshgeom%layertype       = -1    
   meshgeom%nnodes          = -1    
   meshgeom%nbranches       = -1    
   meshgeom%ngeometry       = -1    
   meshgeom%start_index     = -1 
   meshgeom%epsg            = -1 

   ierr = 0

   !nullify
   meshgeom%edge_nodes => null()
   meshgeom%face_nodes => null()
   meshgeom%edge_faces => null()
   meshgeom%face_edges => null()
   meshgeom%face_links => null()

   meshgeom%nnodex => null()
   meshgeom%nnodey => null()
   meshgeom%nnodeids => null()
   meshgeom%nnodelongnames       => null()
   meshgeom%nedge_nodes          => null()
   meshgeom%nbranchids           => null()
   meshgeom%nbranchlongnames     => null()
   
   meshgeom%nbranchlengths       => null()
   meshgeom%nbranchgeometrynodes => null()
   meshgeom%ngeopointx => null()
   meshgeom%ngeopointy => null()
   meshgeom%nbranchorder => null()
   meshgeom%branchidx => null()
   meshgeom%branchoffsets => null()
   
   meshgeom%nodex => null()
   meshgeom%nodey => null()
   meshgeom%nodez => null()
   meshgeom%edgex => null()
   meshgeom%edgey => null()
   meshgeom%edgez => null()
   meshgeom%facex => null()
   meshgeom%facey => null()
   meshgeom%facez => null()
   
   meshgeom%layer_zs     => null()
   meshgeom%interface_zs => null()
      
   end function t_ug_meshgeom_destructor

end module meshdata
