module m_1d_networkreader
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
!  $Id: 1d_networkreader.f90 59779 2018-08-08 14:09:51Z noort $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/utils_gpl/flow1d/packages/flow1d_io/src/1d_networkreader.f90 $
!-------------------------------------------------------------------------------
   
   use MessageHandling
   use modelGlobalData
   use properties
   use m_hash_search
   use m_hash_list
   use m_network
   
   implicit none

   private
   
   public NetworkReader
   public NetworkUgridReader
   public read_1d_ugrid
   public read_network_cache
   public write_network_cache

   contains
    
   subroutine NetworkReader(network, networkFile)
   
      use m_hash_search
      
      implicit none
   
      type(t_network), target, intent(inout) :: network
      character(len=*), intent(in) :: networkFile
      
      type(tree_data), pointer  :: md_ptr
      integer :: istat
      integer :: numstr
      integer :: i

      call tree_create(trim(networkFile), md_ptr, maxlenpar)
      call prop_file('ini',trim(networkFile), md_ptr, istat)

      numstr = 0
      if (associated(md_ptr%child_nodes)) then
         numstr = size(md_ptr%child_nodes)
      end if

      ! Get the Nodes First
      do i = 1, numstr
         
         if (tree_get_name(md_ptr%child_nodes(i)%node_ptr) .eq. 'node') then
           call readNode(network%nds, md_ptr%child_nodes(i)%node_ptr)
         endif

      enddo
      call fill_hashtable(network%nds)
      
      ! Get the Branches
      do i = 1, numstr
         
         if (tree_get_name(md_ptr%child_nodes(i)%node_ptr) .eq. 'branch') then
           call readBranch(network%brs, network%nds, md_ptr%child_nodes(i)%node_ptr)
         endif

      enddo
      
      call adminBranchOrders(network%brs)
      call fill_hashtable(network%brs)
      
      call tree_destroy(md_ptr)
      
   end subroutine NetworkReader
   
   subroutine NetworkUgridReader(network, networkUgridFile)
   
      use io_netcdf
      use io_ugrid
      use m_hash_search
      use gridgeom
      use meshdata
      
      implicit none
   
      type(t_network), target, intent(inout) :: network
      character(len=*), intent(in)           :: networkUgridFile
      
      integer                   :: ierr
      integer                   :: ioncid
      
      ! Open UGRID-File
      ierr = ionc_open(networkUgridFile, NF90_NOWRITE, ioncid)
      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Error Opening UGRID-File: '''//trim(networkUgridFile)//'''')
      endif

      ! Do the actual read
      call read_1d_ugrid(network, ioncid)
      
      ! Close UGRID-File
      ierr = ionc_close(ioncid)
      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Error Closing UGRID-File: '''//trim(networkUgridFile)//'''')
      endif
       
   end subroutine NetworkUgridReader  
   
   subroutine read_1d_ugrid(network, ioncid, dflowfm)
   
      use io_netcdf
      use io_ugrid
      use m_hash_search
      use gridgeom
      use meshdata
      
      implicit none
   
      type(t_network), target, intent(inout) :: network
      integer, intent(in)                    :: ioncid
      logical, optional, intent(inout)       :: dflowfm
      
      integer                   :: ibran
      integer                   :: igridpoint
      
      integer                   :: ierr, i, j
      integer                   :: istat 
      integer                   :: numMesh
      integer                   :: meshIndex
      integer                   :: networkIndex
      integer                   :: gridPointsCount
      integer                   :: startIndex
      type(t_node), dimension(:), pointer :: pnodes

      integer, allocatable, dimension(:)               :: gpFirst
      integer, allocatable, dimension(:)               :: gpLast
      
      double precision, allocatable, dimension(:)      :: gpsX
      double precision, allocatable, dimension(:)      :: gpsY
      
      !character variables
      character(len=IdLen), allocatable, dimension(:)                  :: gpsID 
      character(len=ug_idsLongNamesLen), allocatable, dimension(:)     :: gpsIDLongnames
      character(len=ug_idsLen), allocatable, dimension(:)              :: nodeids
      character(len=ug_idsLongNamesLen), allocatable, dimension(:)     :: nodelongnames
      character(len=ug_idsLen), allocatable, dimension(:)              :: branchids
      character(len=ug_idsLongNamesLen), allocatable, dimension(:)     :: branchlongnames
      character(len=ug_idsLongNamesLen)                                :: network1dname, mesh1dname
      
      !< Structure where all mesh is stored. Internal arrays are all pointers
      type(t_ug_meshgeom) :: meshgeom
      
      ! Make indexes 1-based
      startIndex = 1
      
      
      ierr = ionc_get_mesh_count(ioncid, numMesh)
      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Reading Number of Meshes')
      endif
      if (numMesh < 1) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Data Missing')
      endif

      ! Get Index of 1D-Mesh
      ierr = ionc_get_1d_mesh_id_ugrid(ioncid, meshIndex)
      if (ierr .ne. 0 .or. meshIndex <= 0) then
         if (present(dflowfm)) then  
            call SetMessage(LEVEL_INFO, 'Network UGRID-File: No 1D-Mesh Present, Skipped 1D')
            network%loaded = .false.           
            return
         else
            call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Reading Mesh ID')
         endif
      endif
      
      ! Get Index of 1D-Network
      ierr = ionc_get_1d_network_id_ugrid(ioncid, networkIndex)
      if (ierr .ne. 0 .or. networkIndex <= 0) then
         if (present(dflowfm)) then  
            call SetMessage(LEVEL_INFO, 'Network UGRID-File: No 1D-Network Present, Skipped 1D')
            network%loaded = .false.
            return
         else
            call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Reading Mesh ID')
         endif
      endif
      
      ! Get all data in one call: mesh and network
      ierr =  ionc_get_meshgeom(ioncid, meshIndex, networkIndex, meshgeom, startIndex, .true., &             
                                branchids, branchlongnames, nodeids, nodelongnames, & !1d network character variables
                                gpsID, gpsIDLongnames, network1dname, mesh1dname)     !1d grid character variables

      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in ionc_get_meshgeom')
      endif
      
      ! check data are present and correct
      if (meshgeom%numnode .eq. -1) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%numnode')
      endif
      if (meshgeom%nbranches .eq. -1) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nbranches')
      endif
      if (.not.associated(meshgeom%nodex)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nodex')
      endif
      if (.not.associated(meshgeom%nodey)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nodey')
      endif      
      if (.not.allocated(nodeids)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in nodeids')
      endif
      if (.not.allocated(nodelongnames)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in nodelongnames')
      endif
      
      
      if (.not.allocated(branchids)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nbranchids')
      endif
      if (.not.associated(meshgeom%nedge_nodes)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nedge_nodes')
      endif
      if (.not.associated(meshgeom%nbranchorder)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nbranchorder')
      endif
      if (.not.associated(meshgeom%nodex)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nodex')
      endif
      if (.not.associated(meshgeom%nodey)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%nodey')
      endif
      if (.not.associated(meshgeom%branchoffsets)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in meshgeom%branchoffsets')
      endif
      if (.not.allocated(gpsID)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in gpsID')
      endif 
      if (.not.allocated(gpsIDLongnames)) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error in gpsIDLongnames')
      endif
    
      ! Store Node Data into Data Structures      
      call storeNodes(network%nds, meshgeom%nnodes, meshgeom%nnodex, meshgeom%nnodey, nodeids, nodelongnames)
   
      ! Calculate xy coordinates from UGrid index based notation
      allocate(gpsX(meshgeom%numnode), stat = istat)
      if (istat == 0) allocate(gpsY(meshgeom%numnode), stat = istat)
      if (istat .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Allocating Memory for Grid Point Coordinates')
      endif

      ierr = ggeo_get_xy_coordinates(meshgeom%branchidx, meshgeom%branchoffsets, meshgeom%ngeopointx, meshgeom%ngeopointy, &
                                     meshgeom%nbranchgeometrynodes, meshgeom%nbranchlengths, 0, gpsX, gpsY)
      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Getting Mesh Coordinates From UGrid Data')
      endif
      
      ! Get the starting and endig indexes of the grid points 
      ibran = 0
      allocate(gpFirst(meshgeom%nbranches), stat = istat)
      if (istat == 0) allocate(gpLast(meshgeom%nbranches), stat = istat)
      if (istat .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Allocating Memory for Branches')
      endif
   
      ierr = ggeo_get_start_end_nodes_of_branches(meshgeom%branchidx, gpFirst, gpLast)
      if (ierr .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Network UGRID-File: Error Getting first and last nodes of the network branches')
      endif 
      
      ! Store Branches
      do ibran = 1, meshgeom%nbranches
      
         gridPointsCount = gpLast(ibran) - gpFirst(ibran) + 1
         
         call storeBranch(network%brs, network%nds, branchids(ibran), &
                          nodeids(meshgeom%nedge_nodes(1,ibran)), nodeids(meshgeom%nedge_nodes(2,ibran)), &
                          meshgeom%nbranchorder(ibran), gridPointsCount, gpsX(gpFirst(ibran):gpLast(ibran)), &
                          gpsY(gpFirst(ibran):gpLast(ibran)), meshgeom%branchoffsets(gpFirst(ibran):gpLast(ibran)), &
                          gpsID(gpFirst(ibran):gpLast(ibran)))       
      enddo

      call adminBranchOrders(network%brs)
      call fill_hashtable(network%brs)
      pnodes => network%nds%node  
      do i = 1, network%nds%count
         do j = i+1, network%nds%count
            if (abs(pnodes(i)%x-pnodes(j)%x) + abs(pnodes(i)%y-pnodes(j)%y) < 1d0) then
               pnodes(j)%x = pnodes(i)%x+0.5d0
               pnodes(j)%y = pnodes(i)%y+0.5d0
            endif
         enddo
      enddo
      
      network%loaded = .true.
      
      
      !free memory
      ierr = t_ug_meshgeom_destructor(meshgeom)
      deallocate(nodeids)
      deallocate(nodelongnames)
      deallocate(branchids)
      deallocate(gpsID)
      deallocate(gpsX)
      deallocate(gpsY)
      deallocate(gpsIDLongnames)
 
   end subroutine read_1d_ugrid 
   
   
   subroutine adminBranchOrders(brs)
      type (t_branchset), intent(inout) :: brs
      
      integer i, ibr, j
      type(t_branch), pointer :: pbr, pbr2
      
      do ibr = 1, brs%count
         pbr => brs%branch(ibr)
         if (pbr%orderNumber > 0) then
            do j = 1, 2
               if (pbr%nextBranch(j) < 0) then
                  ! find neighbouring branch
                  do i = ibr+1, brs%count
                     pbr2 => brs%branch(i)
                     if (pbr%ordernumber == pbr2%ordernumber) then
                        if (pbr%nodeIndex(j) == pbr2%nodeIndex(1)) then
                           ! found one
                           pbr%nextBranch(j) = i
                           pbr2%nextBranch(1)= ibr
                           ! finished
                           cycle
                        elseif (pbr%nodeIndex(j) == pbr2%nodeIndex(2)) then
                           ! found one
                           pbr%nextBranch(j) = i
                           pbr2%nextBranch(2)= ibr
                           ! finished
                           cycle
                        endif
                     endif
                  enddo
               endif
            enddo
         endif
      enddo
      
   end subroutine adminBranchOrders

   subroutine readNode(nds, md_ptr)
   
      implicit none
   
      type(t_nodeSet), target, intent(inout) :: nds
      type(tree_data), pointer, intent(in)   :: md_ptr    

      character(len=IdLen)                   :: nodeId
      character(len=IdLen)                   :: nodeName
      double precision                       :: x
      double precision                       :: y
      logical                                :: success
      
      call  prop_get_string(md_ptr, 'node', 'id', nodeId, success)
      if (.not. success) then
         call SetMessage(LEVEL_FATAL, 'Error Reading Node ID')
      endif
      
      call prop_get_string(md_ptr, 'node', 'name', nodeName, success)

      call prop_get_double(md_ptr, 'node', 'x', x, success)
      if (success) call prop_get_double(md_ptr, 'node', 'y', y, success)
      
      if (.not. success) then
         call SetMessage(LEVEL_FATAL, 'Error Reading Node '''//trim(nodeId)//'''')
      endif

      nds%Count = nds%Count+1
      if (nds%Count > nds%Size) then
         call realloc(nds)
      endif
      
      nds%node(nds%Count)%id       = nodeId
      nds%node(nds%Count)%name     = nodeName
      nds%node(nds%Count)%index    = nds%count
      nds%node(nds%Count)%nodetype = nt_NotSet
      nds%node(nds%Count)%numberOfConnections = 0
      nds%node(nds%Count)%x = x
      nds%node(nds%Count)%y = y
      
   end subroutine readNode
   
   subroutine storeNodes(nds, nNodes, nodesX, nodesY, nodeids, nodelongnames)
   
      implicit none
   
      type(t_nodeSet), target, intent(inout)             :: nds
      integer, intent(in)                                :: nNodes
      double precision, dimension(nNodes), intent(in)    :: nodesX 
      double precision, dimension(nNodes), intent(in)    :: nodesY
      character(len=*), dimension(nNodes), intent(in)    :: nodeids
      character(len=*), dimension(nNodes) , intent(in)   :: nodelongnames
      
      integer                                :: iNode
      
      
      do iNode = 1, nNodes
      
         nds%Count = nds%Count + 1
         if (nds%Count > nds%Size) then
            call realloc(nds)
         endif
      
         nds%node(nds%Count)%id                  = nodeids(iNode)
         nds%node(nds%Count)%name                = nodelongnames(iNode)(1:40)
         nds%node(nds%Count)%index               = nds%count
         nds%node(nds%Count)%nodetype            = nt_NotSet
         nds%node(nds%Count)%numberOfConnections = 0
         nds%node(nds%Count)%x                   = nodesX(iNode)
         nds%node(nds%Count)%y                   = nodesY(iNode)
         
      enddo
      
      call fill_hashtable(nds)
      
   end subroutine storeNodes
   
   subroutine readBranch(brs, nds, md_ptr)
   
      use m_branch
      
      implicit none

      type(t_branchSet), target, intent(inout) :: brs
      type(t_nodeSet), target, intent(inout)   :: nds
      type(tree_data), pointer, intent(in)     :: md_ptr
      
      ! Local Variables
      integer                                  :: ibr
      type(t_branch), pointer                  :: pbr
      type(t_node), pointer                    :: node
      logical                                  :: success
      integer                                  :: istat
      integer                                  :: ibegNode
      integer                                  :: iendNode
      integer                                  :: orderNumber
      integer                                  :: gridPointsCount
      integer                                  :: uPointsCount
      integer                                  :: igr
      integer                                  :: gridIndex
      integer                                  :: j
      integer                                  :: ip1
      integer                                  :: ip2
      character(len=IdLen)                     :: branchId
      character(len=IdLen)                     :: begNodeId
      character(len=IdLen)                     :: endNodeId
      character(len=IdLen)                     :: Chainage
      
      double precision, allocatable, dimension(:)     :: gpX
      double precision, allocatable, dimension(:)     :: gpY
      double precision, allocatable, dimension(:)     :: gpOffsets
      character(len=IdLen), allocatable, dimension(:) :: gpID
      
      brs%Count = brs%Count + 1
      ibr = brs%Count
      if (brs%Count > brs%Size) then
         call realloc(brs)
      endif
      
      pbr =>brs%branch(brs%Count)
      
      call  prop_get_string(md_ptr, 'branch', 'id', branchId, success)
      if (.not. success) then
         call SetMessage(LEVEL_FATAL, 'Error Reading Branch ID')
      endif

      call  prop_get_string(md_ptr, 'branch', 'fromnode', begNodeId, success)
      if (success) call  prop_get_string(md_ptr, 'branch', 'tonode', endNodeId, success)
      if (success) call  prop_get_integer(md_ptr, 'branch', 'order', ordernumber, success)
      if (success) call  prop_get_integer(md_ptr, 'branch', 'gridpointscount', gridPointsCount, success)

      if (.not. success) then
         call SetMessage(LEVEL_FATAL, 'Error Reading Branch '''//trim(branchId)//'''')
      endif
      
      ibegNode = hashsearch(nds%hashlist, begNodeId)
      if (ibegNode <= 0) then
         write(msgbuf, '(4a)') trim(branchId), ': fromNode ''', trim(begNodeId), ''' does not exist'
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif
      
      iendNode = hashsearch(nds%hashlist, endNodeId)
      if (iendNode <= 0) then
         write(msgbuf ,'(4a)') trim(branchId), ': toNode ''', trim(endNodeId), ''' does not exist'
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif

      if (ibegNode == iendNode) then
         write(msgbuf, '(5a)') trim(branchId), ': fromNode ''', trim(begNodeId) , ''' is identical to toNode ''', trim(endNodeId)//''''
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif
      
      pbr%id                           = branchID
      pbr%index                        = ibr
      pbr%FromNode                     => nds%node(ibegNode)
      pbr%FromNode%numberOfConnections = pbr%FromNode%numberOfConnections + 1
      pbr%ToNode                       => nds%node(iendNode)
      pbr%ToNode%numberOfConnections   = pbr%toNode%numberOfConnections + 1
      pbr%orderNumber                  = orderNumber
      pbr%brType                       = BR_ISOLATED
      pbr%nextBranch                   = -1
      pbr%nodeIndex(1)                 = ibegNode
      pbr%nodeIndex(2)                 = iendNode
      ! The Gridpoints
      call realloc(gpX, gridPointsCount, stat=istat)
      if (istat == 0) call realloc(gpY, gridPointsCount, stat=istat)
      if (istat == 0) call realloc(gpOffsets, gridPointsCount, stat=istat)
      if (istat .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Reading Branch: Error allocating Gridpoint Arrays')
      endif
      
      call prop_get_doubles(md_ptr, 'branch', 'gridPointX', gpX, gridPointsCount, success)
      if (success) call prop_get_doubles(md_ptr, 'branch', 'gridPointY', gpY, gridPointsCount, success)
      if (success) call prop_get_doubles(md_ptr, 'branch', 'gridPointOffsets', gpOffsets, gridPointsCount, success)
      if (.not. success) then
         call SetMessage(LEVEL_FATAL, 'Error Reading Grid Data from Branch '''//trim(branchId)//'''')
      endif
      
      ! Check offsets of Grid Points
      do igr = 1, gridPointsCount - 1
         if (gpOffsets(igr) + minSectionLength > gpOffsets(igr + 1)) then
            ! Two adjacent gridpoints too close
            write (msgbuf, '(a, a, a, g11.4, a, g11.4)' ) 'Two grid points on branch ''', trim(branchid), ''' are too close at offset ',               &
                                    gpOffsets(igr), ' and ', gpOffsets(igr + 1)
            call SetMessage(LEVEL_WARN, msgbuf)
         endif 
      enddo

      pbr%gridPointsCount = gridPointsCount
      uPointsCount        = pbr%gridPointsCount - 1
      pbr%uPointsCount    = uPointsCount
      
      call realloc(pbr%gridPointsOffsets, pbr%gridPointsCount)
      call realloc(pbr%uPointsOffsets, pbr%uPointsCount)
      call realloc(pbr%dx, pbr%uPointsCount)
      call realloc(pbr%Xs, pbr%gridPointsCount)
      call realloc(pbr%Ys, pbr%gridPointsCount)
      call realloc(pbr%Xu, pbr%uPointsCount)
      call realloc(pbr%Yu, pbr%uPointsCount)
      
      ip1 = brs%gridPointsCount + 1
      brs%gridPointsCount = brs%gridPointsCount + gridPointsCount
      ip2 = brs%gridPointsCount
      pbr%Points(1)         = ip1
      pbr%Points(2)         = ip2
      pbr%upoints(1)        = ip1
      pbr%upoints(2)        = ip2 - 1
      pbr%gridPointsOffsets = gpOffsets
      pbr%uPointsOffsets    = (pbr%gridPointsOffsets(1:uPointsCount) + pbr%gridPointsOffsets(2:uPointsCount+1) ) / 2.0d0
      pbr%dx                = pbr%gridPointsOffsets(2:uPointsCount+1) - pbr%gridPointsOffsets(1:uPointsCount)
      pbr%length            = gpOffsets(gridPointsCount)
      pbr%Xs                = gpX
      pbr%Ys                = gpY
      pbr%fromNode%x        = gpX(1)
      pbr%fromNode%y        = gpY(1)
      pbr%toNode%x          = gpX(gridPointsCount)
      pbr%toNode%y          = gpY(gridPointsCount)
      pbr%iTrench           = 0
      pbr%brtype            = BR_ISOLATED
         
      do j = 1, gridPointsCount-1
         pbr%Xu(j) = 0.5d0 * (pbr%Xs(j) + pbr%Xs(j + 1))
         pbr%Yu(j) = 0.5d0 * (pbr%Ys(j) + pbr%Ys(j + 1))
      enddo
         
      do j = 1, 2
         if (j==1) then
            node => pbr%fromNode
            gridIndex = ip1
         else
            node => pbr%toNode
            gridIndex = ip2
         endif
         if (node%nodeType == nt_NotSet) then
            ! probably end node (until proved otherwise
            node%nodeType = nt_endNode
            node%gridNumber = gridIndex
         elseif (node%nodeType == nt_endNode) then
            ! Already one branch connected, so not an endNode
            node%nodeType = nt_LinkNode
            node%gridNumber = 0
         endif
         if (node%numberOfConnections > nds%maxNumberOfConnections) then
            nds%maxNumberOfConnections = node%numberOfConnections
         endif
      enddo
      
      ! Get and Set grid point IDs
      call realloc(gpID, gridPointsCount, stat=istat)
      if (istat .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Reading Branch: Error allocating Gridpoint Array for IDs')
      endif
      gpID = ' '

      call prop_get_strings(md_ptr, 'branch', 'gridPointIds', gridPointsCount, gpID, success)
      call realloc(pbr%gridPointIDs, gridPointsCount)

      if (success) then
         pbr%gridPointIDs = gpID
      else
         ! Create grid point IDs
         pbr%gridPointIDs = ' '
         do igr = 1, gridPointsCount
            write(Chainage, '(F35.3)') pbr%gridPointsOffsets(igr)
            pbr%gridPointIDs(igr) = trim(pbr%id)//'_'//trim(adjustl(Chainage))
         enddo
         
      endif
      
      ! Clear Grid Point Arrays
      if (allocated(gpX)) deallocate(gpX, stat=istat)
      if (istat == 0 .and. allocated(gpY)) deallocate(gpY, stat=istat)
      if (istat == 0 .and. allocated(gpOffsets)) deallocate(gpOffsets, stat=istat)
      if (istat == 0 .and. allocated(gpID)) deallocate(gpID, stat=istat)
      if (istat .ne. 0) then
         call SetMessage(LEVEL_FATAL, 'Reading Branch: Error Deallocating Gridpoint Arrays')
      endif
      
   end subroutine readBranch

   subroutine storeBranch(brs, nds, branchId, begNodeId, endNodeId, ordernumber, gridPointsCount, gpX, gpY, gpOffsets, gpID)
   
      use m_branch
      
      implicit none

      type(t_branchSet), target, intent(inout)       :: brs
      type(t_nodeSet), target, intent(inout)         :: nds
      character(len=IdLen), intent(in)               :: branchId
      character(len=IdLen), intent(in)               :: begNodeId
      character(len=IdLen), intent(in)               :: endNodeId
      integer, intent(in)                            :: orderNumber
      
      integer, intent(in)                                          :: gridPointsCount
      double precision, dimension(gridPointsCount), intent(in)     :: gpX
      double precision, dimension(gridPointsCount), intent(in)     :: gpY
      double precision, dimension(gridPointsCount), intent(in)     :: gpOffsets
      character(len=IdLen), dimension(gridPointsCount), intent(in) :: gpID
      
      ! Local Variables
      integer                                  :: ibr
      type(t_branch), pointer                  :: pbr
      type(t_node), pointer                    :: node
      integer                                  :: ibegNode
      integer                                  :: iendNode
      integer                                  :: uPointsCount
      integer                                  :: igr
      integer                                  :: gridIndex
      integer                                  :: j
      integer                                  :: ip1
      integer                                  :: ip2
      character(len=IdLen)                     :: Chainage
      
      brs%Count = brs%Count + 1
      ibr = brs%Count
      if (brs%Count > brs%Size) then
         call realloc(brs)
      endif
      
      pbr =>brs%branch(brs%Count)
      
      ibegNode = hashsearch(nds%hashlist, begNodeId)
      if (ibegNode <= 0) then
         write(msgbuf, '(4a)') trim(branchId), ': fromNode ''', trim(begNodeId), ''' does not exist'
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif
      
      iendNode = hashsearch(nds%hashlist, endNodeId)
      if (iendNode <= 0) then
         write(msgbuf ,'(4a)') trim(branchId), ': toNode ''', trim(endNodeId), ''' does not exist'
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif

      if (ibegNode == iendNode) then
         write(msgbuf, '(5a)') trim(branchId), ': fromNode ''', trim(begNodeId) , ''' is identical to toNode ''', trim(endNodeId)//''''
         call SetMessage(LEVEL_FATAL, msgbuf)
      endif
      
      pbr%id                           = branchID
      pbr%index                        = ibr
      pbr%FromNode                     => nds%node(ibegNode)
      pbr%FromNode%numberOfConnections = pbr%FromNode%numberOfConnections + 1
      pbr%ToNode                       => nds%node(iendNode)
      pbr%ToNode%numberOfConnections   = pbr%toNode%numberOfConnections + 1
      pbr%orderNumber                  = orderNumber
      pbr%brType                       = BR_ISOLATED
      pbr%nextBranch                   = -1
      pbr%nodeIndex(1)                 = ibegNode
      pbr%nodeIndex(2)                 = iendNode

      ! The Gridpoints

      ! Check offsets of Grid Points
      do igr = 1, gridPointsCount - 1
         if (gpOffsets(igr) + minSectionLength > gpOffsets(igr + 1)) then
            ! Two adjacent gridpoints too close
            write (msgbuf, '(a, a, a, g11.4, a, g11.4)' ) 'Two grid points on branch ''', trim(branchid), ''' are too close at offset ',               &
                                    gpOffsets(igr), ' and ', gpOffsets(igr + 1)
            call SetMessage(LEVEL_WARN, msgbuf)
         endif 
      enddo

      pbr%gridPointsCount = gridPointsCount
      uPointsCount        = pbr%gridPointsCount - 1
      pbr%uPointsCount    = uPointsCount
      
      call realloc(pbr%gridPointsOffsets, pbr%gridPointsCount)
      call realloc(pbr%uPointsOffsets, pbr%uPointsCount)
      call realloc(pbr%dx, pbr%uPointsCount)
      call realloc(pbr%Xs, pbr%gridPointsCount)
      call realloc(pbr%Ys, pbr%gridPointsCount)
      call realloc(pbr%Xu, pbr%uPointsCount)
      call realloc(pbr%Yu, pbr%uPointsCount)
      
      ip1 = brs%gridPointsCount + 1
      brs%gridPointsCount = brs%gridPointsCount + gridPointsCount
      ip2 = brs%gridPointsCount
      pbr%Points(1)         = ip1
      pbr%Points(2)         = ip2
      pbr%upoints(1)        = ip1
      pbr%upoints(2)        = ip2 - 1
      pbr%gridPointsOffsets = gpOffsets
      pbr%uPointsOffsets    = (pbr%gridPointsOffsets(1:uPointsCount) + pbr%gridPointsOffsets(2:uPointsCount+1) ) / 2.0d0
      pbr%dx                = pbr%gridPointsOffsets(2:uPointsCount+1) - pbr%gridPointsOffsets(1:uPointsCount)
      pbr%length            = gpOffsets(gridPointsCount)
      pbr%Xs                = gpX
      pbr%Ys                = gpY
      pbr%fromNode%x        = gpX(1)
      pbr%fromNode%y        = gpY(1)
      pbr%toNode%x          = gpX(gridPointsCount)
      pbr%toNode%y          = gpY(gridPointsCount)
      pbr%iTrench           = 0
      pbr%brtype            = BR_ISOLATED
         
      do j = 1, gridPointsCount-1
         pbr%Xu(j) = 0.5d0 * (pbr%Xs(j) + pbr%Xs(j + 1))
         pbr%Yu(j) = 0.5d0 * (pbr%Ys(j) + pbr%Ys(j + 1))
      enddo
         
      do j = 1, 2
         if (j==1) then
            node => pbr%fromNode
            gridIndex = ip1
         else
            node => pbr%toNode
            gridIndex = ip2
         endif
         if (node%nodeType == nt_NotSet) then
            ! probably end node (until proved otherwise
            node%nodeType = nt_endNode
            node%gridNumber = gridIndex
         elseif (node%nodeType == nt_endNode) then
            ! Already one branch connected, so not an endNode
            node%nodeType = nt_LinkNode
            node%gridNumber = 0
         endif
         if (node%numberOfConnections > nds%maxNumberOfConnections) then
            nds%maxNumberOfConnections = node%numberOfConnections
         endif
      enddo
      
      ! Set grid point IDs
      call realloc(pbr%gridPointIDs, gridPointsCount)

      do igr = 1, gridPointsCount
      
         if (gpID(igr) .eq. ' ') then
            write(Chainage, '(F35.3)') pbr%gridPointsOffsets(igr)
            pbr%gridPointIDs(igr) = trim(pbr%id)//'_'//trim(adjustl(Chainage))
         else
            pbr%gridPointIDs(igr) = gpID(igr)
         endif
         
      enddo
      
   end subroutine storeBranch

   subroutine read_network_cache(ibin, network)
   
      type(t_network), intent(inout)  :: network
      integer, intent(in)             :: ibin

      call read_node_cache(ibin, network)
      
      call read_branch_cache(ibin, network)
   
   end subroutine read_network_cache
   
   subroutine write_network_cache(ibin, network)
   
      type(t_network), intent(in)     :: network
      integer, intent(in)             :: ibin

      call write_node_cache(ibin, network%nds)
      
      call write_branch_cache(ibin, network%brs)
   
   end subroutine write_network_cache
   
   subroutine read_node_cache(ibin, network)
   
      type(t_network), intent(inout)    :: network
      integer, intent(in)               :: ibin
      
      type(t_node), pointer             :: pnod
      integer                           :: i

      read(ibin) network%nds%count
      
      network%nds%growsby = network%nds%count + 2
      call realloc(network%nds)

      read(ibin) network%nds%maxNumberOfConnections
      
      network%nds%LevelBoundaryCount = 0
      network%nds%DisBoundaryCount   = 0
      network%nds%bndCount           = 0

      do i = 1, network%nds%Count
      
         pnod => network%nds%node(i)
         
         read(ibin) pnod%id
         read(ibin) pnod%name
         read(ibin) pnod%index
         read(ibin) pnod%nodeType

         read(ibin) pnod%x
         read(ibin) pnod%y
         read(ibin) pnod%gridNumber
         
         read(ibin) pnod%numberOfConnections
      
      enddo
 
      call read_hash_list_cache(ibin, network%nds%hashlist)

   end subroutine read_node_cache
   
   subroutine write_node_cache(ibin, nds)
   
      type(t_nodeSet), intent(in)     :: nds
      integer, intent(in)             :: ibin

      type(t_node), pointer           :: pnod
      integer                         :: i

      write(ibin) nds%Count
      
      write(ibin) nds%maxNumberOfConnections

      do i = 1, nds%Count
      
         pnod => nds%node(i)
         
         write(ibin) pnod%id
         write(ibin) pnod%name
         write(ibin) pnod%index
         write(ibin) pnod%nodeType

         write(ibin) pnod%x
         write(ibin) pnod%y
         write(ibin) pnod%gridNumber
         
         write(ibin) pnod%numberOfConnections
      
      enddo
 
      call write_hash_list_cache(ibin, nds%hashlist)
      
   end subroutine write_node_cache
   
   subroutine read_branch_cache(ibin, network)
   
      type(t_network), intent(inout)   :: network
      integer, intent(in)              :: ibin
   
      type(t_branch), pointer          :: pbrn
      integer                          :: i
      integer                          :: j

      read(ibin) network%brs%Count
      
      network%brs%growsby = network%brs%count + 2
      call realloc(network%brs)

      read(ibin) network%brs%gridpointsCount

      do i = 1, network%brs%Count
      
         pbrn => network%brs%branch(i)
         
         read(ibin) pbrn%id
         read(ibin) pbrn%index
         read(ibin) pbrn%name
         read(ibin) pbrn%length
         read(ibin) pbrn%orderNumber
         
         read(ibin) pbrn%brType
         read(ibin) pbrn%iTrench

         read(ibin) (pbrn%nextBranch(j), j = 1, 2)
         
         read(ibin) (pbrn%nodeIndex(j), j = 1, 2)
         pbrn%FromNode => network%nds%node(pbrn%nodeIndex(1))
         pbrn%ToNode => network%nds%node(pbrn%nodeIndex(2))

         read(ibin) pbrn%gridPointsCount
         
         allocate(pbrn%gridPointsOffsets(pbrn%gridPointsCount))
         allocate(pbrn%gridPointIDs(pbrn%gridPointsCount))
         allocate(pbrn%Xs(pbrn%gridPointsCount))
         allocate(pbrn%Ys(pbrn%gridPointsCount))
         
         read(ibin) (pbrn%gridPointsOffsets(j), j = 1, pbrn%gridPointsCount)   
         read(ibin) (pbrn%gridPointIDs(j), j = 1, pbrn%gridPointsCount)   
         read(ibin) (pbrn%Xs(j), j = 1, pbrn%gridPointsCount)   
         read(ibin) (pbrn%Ys(j), j = 1, pbrn%gridPointsCount)   
      
         read(ibin) pbrn%uPointsCount
         
         allocate(pbrn%uPointsOffsets(pbrn%uPointsCount))
         allocate(pbrn%Xu(pbrn%uPointsCount))
         allocate(pbrn%Yu(pbrn%uPointsCount))
         allocate(pbrn%dx(pbrn%uPointsCount))
         
         read(ibin) (pbrn%uPointsOffsets(j), j = 1, pbrn%uPointsCount)   
         read(ibin) (pbrn%Xu(j), j = 1, pbrn%uPointsCount)   
         read(ibin) (pbrn%Yu(j), j = 1, pbrn%uPointsCount)   
         read(ibin) (pbrn%dx(j), j = 1, pbrn%uPointsCount)   
      
         read(ibin) (pbrn%Points(j), j = 1, 2)
         read(ibin) (pbrn%uPoints(j), j = 1, 2)

      enddo
 
      call read_hash_list_cache(ibin, network%brs%hashlist)

   end subroutine read_branch_cache
   
   subroutine write_branch_cache(ibin, brs)
   
      type(t_branchSet), intent(in)   :: brs
      integer, intent(in)             :: ibin

      type(t_branch), pointer         :: pbrn
      integer                         :: i
      integer                         :: j

      write(ibin) brs%Count
      
      write(ibin) brs%gridpointsCount

      do i = 1, brs%Count
      
         pbrn => brs%branch(i)
         
         write(ibin) pbrn%id
         write(ibin) pbrn%index
         write(ibin) pbrn%name
         write(ibin) pbrn%length
         write(ibin) pbrn%orderNumber
         
         write(ibin) pbrn%brType
         write(ibin) pbrn%iTrench

         write(ibin) (pbrn%nextBranch(j), j = 1, 2)
         write(ibin) (pbrn%nodeIndex(j), j = 1, 2)

         write(ibin) pbrn%gridPointsCount
         write(ibin) (pbrn%gridPointsOffsets(j), j = 1, pbrn%gridPointsCount)   
         write(ibin) (pbrn%gridPointIDs(j), j = 1, pbrn%gridPointsCount)   
         write(ibin) (pbrn%Xs(j), j = 1, pbrn%gridPointsCount)   
         write(ibin) (pbrn%Ys(j), j = 1, pbrn%gridPointsCount)   
      
         write(ibin) pbrn%uPointsCount
         write(ibin) (pbrn%uPointsOffsets(j), j = 1, pbrn%uPointsCount)   
         write(ibin) (pbrn%Xu(j), j = 1, pbrn%uPointsCount)   
         write(ibin) (pbrn%Yu(j), j = 1, pbrn%uPointsCount)   
         write(ibin) (pbrn%dx(j), j = 1, pbrn%uPointsCount)   
      
         write(ibin) (pbrn%Points(j), j = 1, 2)
         write(ibin) (pbrn%uPoints(j), j = 1, 2)

      enddo
 
      call write_hash_list_cache(ibin, brs%hashlist)

   end subroutine write_branch_cache
   
   
end module m_1d_networkreader
