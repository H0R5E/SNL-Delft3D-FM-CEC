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

! $Id: unstruc_netcdf_incremental.f90 61785 2018-09-10 13:35:06Z spee $
! $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/unstruc_netcdf_incremental.f90 $
module unstruc_netcdf_map_class
use precision, only : hp
use precision_basics, only : comparereal
use m_flow, only : s1, hs
use m_flowtimes, only : map_classes_s1, map_classes_hs, ti_classmape, ti_classmaps, ti_classmap, refdat
use m_flowgeom, only : ndx, ndxi
use m_cell_geometry, only : ndx2d
use unstruc_model, only : md_classmap_file
use unstruc_files
use unstruc_netcdf, only : check_error, t_unc_mapids, unc_create, ug_meta_fm, unc_def_var_nonspatial, &
       UNC_LOC_S, unc_def_var_map, unc_write_flowgeom_filepointer_ugrid, unc_put_var_map_byte, unc_put_var_map_byte_timebuffer
use io_ugrid, only : ug_addglobalatts
use netcdf
use MessageHandling, only : mess, LEVEL_ERROR, LEVEL_INFO, LEVEL_FATAL
use m_flowparameters, only : eps10

implicit none

private

public :: write_map_classes_ugrid
type(t_unc_mapids), public :: m_incids

integer, parameter :: int8 = 1     ! also local storage compact in 1 byte

integer, parameter :: type_very_compact       = 1  ! store -1, 0, -1 for whole grid
integer, parameter :: type_new_class          = 2  ! store new class for whole grid
integer, parameter :: output_type             = type_new_class

integer, parameter :: mapclass_time_buffer_size =   10
integer, parameter :: mapclass_deflate          =    5
integer, parameter :: mapclass_chunksize_ndx    = 2000
integer, parameter :: mapclass_chunksize_time   =  100

integer :: id_nodeId = -1
integer :: id_jumps_s1, id_jumps_hs
integer :: id_class_dim_s1, id_class_dim_hs
integer :: time_index = 0

integer,          parameter :: open_mode = NF90_HDF5
character(len=*), parameter :: nc_file_type = 'NetCDF-4'
character(len=256)          :: filnam
integer                     :: maxTimes, chunkSizeTime

integer(kind=int8), pointer, save :: previous_s1(:) => null()
integer(kind=int8), pointer, save :: previous_hs(:) => null()
integer(kind=int8), pointer :: current_s1(:), current_hs(:)
integer(kind=int8), allocatable :: buffer_s1(:,:), buffer_hs(:,:)

   contains

!> write map class data in ugrid format to an NetCDF file
!! the first time this module is initialized
   subroutine write_map_classes_ugrid(incids, tim)
   type(t_unc_mapids), intent(inout) :: incids   !< class file and other NetCDF ids.
   real(kind=hp),      intent(in)    :: tim      !< simulation time

   integer :: ierr, ndim
   integer, parameter :: jabndnd_ = 0 !< Whether to include boundary nodes (1) or not (0). Default: no.
   integer :: id_class_s1, id_class_hs, tl, var_ids(4)
   character(len=:), allocatable :: errmsg, tmpstr
   logical :: isLast, need_flush

   ierr = nf90_noerr

   if (incids%ncid == 0) then
      ! opening NetCDF file:
      filnam = defaultFilename('clm')
      ierr = unc_create(filnam, open_mode, incids%ncid)
      call mess(LEVEL_INFO, 'opening class map file '''//trim(filnam)//''' as ' // nc_file_type // ' file.')
   endif

   ! Use nr of dimensions in netCDF file a quick check whether vardefs were written before in previous calls.
   ndim = 0
   ierr = nf90_inquire(incids%ncid, nDimensions=ndim)

   ! Only write net and flow geometry data the first time, or for a separate map file.
   if (ndim == 0) then

      ierr = ug_addglobalatts(incids%ncid, ug_meta_fm)
      call unc_write_flowgeom_filepointer_ugrid(incids, jabndnd_)

      !
      ! define dimensions:
      ierr = nf90_def_dim(incids%ncid, 'time', nf90_unlimited, incids%id_timedim)
      if (size(map_classes_s1) > 0 .and. ierr == nf90_noerr) then
         ierr = nf90_def_dim(incids%ncid, 'class_s1', size(map_classes_s1), id_class_dim_s1)
      endif
      if (size(map_classes_hs) > 0 .and. ierr == nf90_noerr) then
         ierr = nf90_def_dim(incids%ncid, 'class_hs', size(map_classes_hs), id_class_dim_hs)
      endif
      call check_error(ierr, 'definition phase dimensions of classes')

      ! define variables:
      tmpstr = 'seconds since '//refdat(1:4)//'-'//refdat(5:6)//'-'//refdat(7:8)//' 00:00:00'
      ierr = unc_def_var_nonspatial(incids%ncid, incids%id_time, nf90_double, [incids%id_timedim], 'time', 'time', ' ', tmpstr)
      maxTimes = 1 + nint( (ti_classmape - ti_classmaps) / ti_classmap)
      chunkSizeTime = min(mapclass_chunksize_time, maxTimes)
      if (ierr == nf90_noerr) ierr = nf90_def_var_chunking(incids%ncid, incids%id_time, NF90_CHUNKED, [chunkSizeTime])

      if (size(map_classes_s1) > 0 .and. ierr == nf90_noerr) then
         ierr = def_var_classmap_ugrid('s1', incids%ncid, id_class_s1, id_jumps_s1, incids)
      endif
      if (size(map_classes_hs) > 0 .and. ierr == nf90_noerr) then
         ierr = def_var_classmap_ugrid('hs', incids%ncid, id_class_hs, id_jumps_hs, incids)
      endif
      if (ierr == nf90_noerr) ierr = nf90_enddef(incids%ncid)
      call check_error(ierr, 'definition phase variables of classes')
      time_index = 1
   else
      time_index = time_index + 1
   endif

   if (size(map_classes_s1) > 0) then
      allocate(current_s1(ndx))
      call put_in_classes(map_classes_s1, s1, current_s1)
   endif
   if (size(map_classes_hs) > 0) then
      allocate(current_hs(ndx))
      call put_in_classes(map_classes_hs, hs, current_hs)
   endif

   if (ndim == 0) then
      if (mapclass_time_buffer_size > 1) then
         if (size(map_classes_s1) > 0) then
            if (allocated(buffer_s1)) deallocate(buffer_s1)
            allocate(buffer_s1(ndx, mapclass_time_buffer_size))
         endif
         if (size(map_classes_hs) > 0) then
            if (allocated(buffer_hs)) deallocate(buffer_hs)
            allocate(buffer_hs(ndx, mapclass_time_buffer_size))
         endif
      endif

      if (size(map_classes_s1) > 0) then
         if (ierr == nf90_noerr) ierr = nf90_put_var(incids%ncid, id_class_s1, map_classes_s1)
         if (ierr == nf90_noerr) ierr = write_initial_classes(incids, current_s1, buffer_s1, 's1', id_jumps_s1)
         previous_s1 => current_s1
      endif
      if (size(map_classes_hs) > 0) then
         if (ierr == nf90_noerr) ierr = nf90_put_var(incids%ncid, id_class_hs, map_classes_hs)
         if (ierr == nf90_noerr) ierr = write_initial_classes(incids, current_hs, buffer_hs, 'hs', id_jumps_hs)
         previous_hs => current_hs
      endif
   else
      if (size(map_classes_s1) > 0) then
         if (ierr == nf90_noerr) ierr = write_changed_classes_update_previous(incids, previous_s1, current_s1, buffer_s1, 's1', id_jumps_s1)
      endif
      if (size(map_classes_hs) > 0) then
         if (ierr == nf90_noerr) ierr = write_changed_classes_update_previous(incids, previous_hs, current_hs, buffer_hs, 'hs', id_jumps_hs)
      endif
   endif
   if (ierr == nf90_noerr) ierr = nf90_put_var(incids%ncid, incids%id_time, tim, start=[time_index])
   call check_error(ierr, 'actual writing of class maps')

   isLast = comparereal(tim, ti_classmape, eps10) /= -1

   ! check if buffer must be written:
   need_flush = .false.
   if (mapclass_time_buffer_size > 1) then
      tl = mod(time_index-1, mapclass_time_buffer_size)+1
      if (isLast .or. tl == mapclass_time_buffer_size) then
         if (size(map_classes_s1) > 0 .and. ierr == nf90_noerr) then
            var_ids = get_varids('s1', incids)
            ierr = unc_put_var_map_byte_timebuffer(incids, var_ids, UNC_LOC_S, buffer_s1, 1, tl)
         endif
         if (size(map_classes_hs) > 0 .and. ierr == nf90_noerr) then
            var_ids = get_varids('hs', incids)
            ierr = unc_put_var_map_byte_timebuffer(incids, var_ids, UNC_LOC_S, buffer_hs, 1, tl)
         endif
         need_flush = .true.
      endif
   else
      need_flush = .true.
   endif

   if (isLast) then
      if (ierr == nf90_noerr) ierr = nf90_close(incids%ncid)
      if (associated(previous_s1)) deallocate(previous_s1)
      if (associated(previous_hs)) deallocate(previous_hs)
      if (allocated(buffer_s1)) deallocate(buffer_s1)
      if (allocated(buffer_hs)) deallocate(buffer_hs)
   else
      if (ierr == nf90_noerr .and. need_flush) then
         ierr = nf90_sync(incids%ncid)  ! flush output to file
      endif
   endif

   if (ierr /= nf90_noerr) then
      errmsg = 'error writing to class map output file'
      call check_error(ierr, errmsg)
      call mess(LEVEL_ERROR, errmsg)
   endif
end subroutine write_map_classes_ugrid

!> helper routine to define NetCDF variables
function def_var_classmap_ugrid(name, ncid, var_id_class_bnds, var_id_jumps, incids) result(ierr)
   type(t_unc_mapids), intent(inout) :: incids             !< class file and other NetCDF ids.
   character(len=*), intent(in)      :: name               !< name of the variable
   integer,          intent(in)      :: ncid               !< the NetCDF file Id
   integer,          intent(out)     :: var_id_class_bnds  !< variable Id for the class boundaries
   integer,          intent(out)     :: var_id_jumps       !< variable Id for the jumps (only for type 1)
   integer                           :: ierr               !< function result. 0=ok

   integer :: id_class, actual_chunksize, ids(4), ndims(2), i
   double precision, pointer :: map_classes(:)

   if (name == 's1') then
      ierr = unc_def_var_map(incids, incids%id_s1, nf90_byte, UNC_LOC_S, 's1',         'sea_surface_height',                'Water level', 'm')
      id_class = id_class_dim_s1
      ids = incids%id_s1
      map_classes => map_classes_s1
   else if (name == 'hs') then
      ierr = unc_def_var_map(incids, incids%id_hs, nf90_byte, UNC_LOC_S, 'waterdepth', 'sea_floor_depth_below_sea_surface', 'Water depth at pressure points', 'm')
      id_class = id_class_dim_hs
      ids = incids%id_hs
      map_classes => map_classes_hs
   else
      call mess(LEVEL_FATAL, 'programming error in def_var_incremental_ugrid')
   endif

   if (ierr == nf90_noerr) ierr = nf90_def_var(ncid, 'classes_'//name , nf90_double, [id_class] , var_id_class_bnds)
   ndims(1) = ndxi - ndx2d
   ndims(2) = ndx2d
   do i = 1, 2
      if (ndims(i) > 0) then
         actual_chunksize = min(mapclass_chunksize_ndx, ndims(i))
         if (ierr == nf90_noerr) ierr = nf90_def_var_deflate(ncid, ids(i), 0, 1, mapclass_deflate)
         if (ierr == nf90_noerr) ierr = nf90_def_var_chunking(ncid, ids(i), NF90_CHUNKED, [actual_chunksize, chunkSizeTime])
         if (ierr == nf90_noerr .and. output_type == type_new_class) then
            ierr = put_flag_attributes(incids%ncid, ids(i), map_classes)
         endif
      endif
   enddo
   if (ierr == nf90_noerr) then
      call mess(LEVEL_INFO, 'successfully defined classes_' // name // ' with deflate_level and chunksizes =', mapclass_deflate, actual_chunksize, mapclass_chunksize_time)
   endif
   if (output_type == type_very_compact) then
      if (ierr == nf90_noerr) ierr = nf90_def_var(ncid, 'jumps_'//name , nf90_int, [incids%id_timedim] , var_id_jumps)
   endif
end function def_var_classmap_ugrid

!> helper function to put the actual data in classes
subroutine put_in_classes(incr_classes, full_field, classes)
   real(kind=hp),      intent(in)  :: incr_classes(:) !< list with class boundaries
   real(kind=hp),      intent(in)  :: full_field(:)   !< actual data in doubles
   integer(kind=int8), intent(out) :: classes(:)      !< converted data in byte with class number

   integer :: i, j, num_classes

   num_classes = size(incr_classes) + 1

   do i = 1, size(full_field)
      classes(i) = num_classes
      do j = 1, size(incr_classes)
         if (full_field(i) < incr_classes(j)) then
            classes(i)  = j
            exit
         endif
      enddo
   enddo
end subroutine put_in_classes

!> helper function to write the first class map
function write_initial_classes(incids, classes, buffer, field, varid_jumps) result(ierr)
   integer,            intent(in)    :: varid_jumps  !< variable Id for the jumps (only type 1)
   integer(kind=int8), intent(in)    :: classes(:)   !< converted data in byte with class number
   integer(kind=int8), intent(inout) :: buffer(:,:)  !< buffered data (if mapclass_time_buffer_size is set > 1)
   character(len=*),   intent(in)    :: field        !< variable name
   type(t_unc_mapids), intent(inout) :: incids       !< class file and other NetCDF ids.
   integer                           :: ierr         !< function result. 0=OK.

   integer :: var_ids(4)

   ierr = nf90_noerr

   incids%idx_curtime = 1
   if (mapclass_time_buffer_size > 1) then
      buffer(:,1) = classes
   else
      var_ids = get_varids(field, incids)
      ierr = unc_put_var_map_byte(incids, var_ids, UNC_LOC_S, classes)
   endif

   if (ierr == 0 .and. output_type == type_very_compact) then
      ierr = nf90_put_var(incids%ncid, varid_jumps, [0], [time_index])
   endif
end function write_initial_classes

!> helper function to write all but the first class map data.
!! pointers previous and current are updated.
!! it can write to NetCDF or append to the buffer array
function write_changed_classes_update_previous(incids, previous, current, buffer, field, varid_jumps) result(ierr)
   integer,                     intent(in)    :: varid_jumps  !< variable Id for the jumps (only type 1)
   integer(kind=int8), pointer, intent(inout) :: previous(:)  !< converted data in byte with class number for previous time step
   integer(kind=int8), pointer, intent(inout) :: current(:)   !< converted data in byte with class number for current time step
   integer(kind=int8),          intent(inout) :: buffer(:,:)  !< buffered data (if mapclass_time_buffer_size is set > 1)
   character(len=*),            intent(in)    :: field        !< variable name
   type(t_unc_mapids),          intent(inout) :: incids       !< class file and other NetCDF ids.
   integer                                    :: ierr         !< function result. 0=OK.

   integer :: i, cnt, dim, var_ids(4), ti
   integer(kind=int8), allocatable :: diff(:)

   dim = size(previous)
   ierr = nf90_noerr

   allocate(diff(dim))
   cnt = 0
   if (output_type == type_very_compact) then
      do i = 1, dim
         diff(i) = current(i) - previous(i)
         if (abs(diff(i)) > 1) then
            cnt = cnt + 1
            diff(i) = max(-1, min(1, diff(i)))
         endif
      enddo
   endif

   var_ids = get_varids(field, incids)
   ti = mod(time_index-1, mapclass_time_buffer_size)+1

   incids%idx_curtime = time_index
   if (output_type == type_very_compact) then
      if (mapclass_time_buffer_size > 1) then
         buffer(:,ti) = diff
      else
         ierr = unc_put_var_map_byte(incids, var_ids, UNC_LOC_S, diff)
      endif
      if (ierr == 0) ierr = nf90_put_var(incids%ncid, varid_jumps, [cnt], [time_index])
   else 
      if (mapclass_time_buffer_size > 1) then
         buffer(:,ti) = current
      else
         ierr = unc_put_var_map_byte(incids, var_ids, UNC_LOC_S, current)
      endif
   endif

   if (output_type == type_very_compact) then
      deallocate(current)
      do i = 1, dim
         previous(i) = previous(i) + diff(i)
      enddo
   else
      deallocate(previous)
      previous => current
   endif
   nullify(current)

   deallocate(diff)

end function write_changed_classes_update_previous

!> construct and write the attributes flag_values and flag_meanings to the NetCDF map class file
function put_flag_attributes(ncid, varid, class_bnds) result (ierr)
   integer,          intent(in) :: ncid          !< NetCDF file id
   integer,          intent(in) :: varid         !< variable id
   double precision, intent(in) :: class_bnds(:) !< class boundaries
   integer                      :: ierr          !< function result; 0=OK

   integer :: i, max_user_classes
   character(len=:), allocatable :: values, meanings, meaning
   character(len=3) :: value
   character(len=12) :: meaning_p, meaning_c

   ierr = nf90_noerr
   max_user_classes = size(class_bnds)

   ! construct the attributes flag_values and flag_meanings
   do i = 1, max_user_classes + 1
      write(value,'(i3)') i

      if (i <= max_user_classes) then
         write(meaning_c, '(f12.3)') class_bnds(i)
      endif

      if (i == 1) then
         values = trim(adjustl(value))
         meanings = 'below_' // trim(adjustl(meaning_c)) // 'm'
      else if (i <= max_user_classes) then
         values = values // ' ' // trim(adjustl(value))
         meaning = trim(adjustl(meaning_p)) // 'm_to_' // trim(adjustl(meaning_c)) // 'm'
         meanings = meanings // ' ' // meaning
      else
         values = values // ' ' // trim(adjustl(value))
         meanings = meanings // ' ' // 'above_' // trim(adjustl(meaning_p)) // 'm'
      endif

      meaning_p = meaning_c
   enddo

   ! write the attributes flag_values and flag_meanings
   if (ierr == nf90_noerr) ierr = nf90_put_att(ncid, varid, 'flag_values', values)
   if (ierr == nf90_noerr) ierr = nf90_put_att(ncid, varid, 'flag_meanings', meanings)
end function put_flag_attributes

!> helper function to get the variable ids based on its name
function get_varids(name, incids) result(var_ids)
   character(len=*),   intent(in) :: name        !< variable name
   type(t_unc_mapids), intent(in) :: incids      !< class file and other NetCDF ids.
   integer                        :: var_ids(4)  !< function result: the found variable ids

   if (name == 's1') then
      var_ids = incids%id_s1
   else if (name == 'hs') then
      var_ids = incids%id_hs
   else
      call mess(LEVEL_FATAL, 'programming error in get_varids')
   endif
end function get_varids

end module unstruc_netcdf_map_class
