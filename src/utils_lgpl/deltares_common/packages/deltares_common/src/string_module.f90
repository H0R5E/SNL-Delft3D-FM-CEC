module string_module
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
!  $Id: string_module.f90 7992 2018-01-09 10:27:35Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/SANDIA/fm_tidal/src/utils_lgpl/deltares_common/packages/deltares_common/src/string_module.f90 $
!!--description-----------------------------------------------------------------
!
!    Function: - Various string processing routines
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------

   implicit none

   private

   !
   ! functions and subroutines
   !
   public :: string_module_info
   public :: str_token
   public :: str_lower
   public :: str_upper
   public :: strcmpi
   public :: remove_leading_spaces
   public :: remove_all_spaces
   public :: find_first_word
   public :: find_first_letter
   public :: find_first_char
   public :: count_words
   public :: remove_substr
   public :: replace_char
   public :: splitstr
   public :: strsplit

   contains

      ! ------------------------------------------------------------------------------
      !   Subroutine: string_module_info
      !   Purpose:    Add info about this string module to the messages stack
      !   Summary:    Add id string and URL
      !   Arguments:
      !   messages    Stack of messages to add the info to
      ! ------------------------------------------------------------------------------
      subroutine string_module_info(messages)
          use message_module
          !
          ! Call variables
          !
          type(message_stack), pointer :: messages
          !
          !! executable statements ---------------------------------------------------
          !
          call addmessage(messages,'$Id: string_module.f90 7992 2018-01-09 10:27:35Z mourits $')
          call addmessage(messages,'$URL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/SANDIA/fm_tidal/src/utils_lgpl/deltares_common/packages/deltares_common/src/string_module.f90 $')
      end subroutine string_module_info



      ! ------------------------------------------------------------------------------
      !   Subroutine: str_token
      !   Purpose:    Obtain first token from string
      !   Summary:    Scan string for non-delimiter (e.g. non-space) characters and
      !               return first set found.
      !   Arguments:
      !   string      on input : String to be scanned
      !               on output: Remainder of string
      !   token       on output: String containing token
      !   quote       on input : Optional quote character
      !   delims      on input : Optional string with delimiter characters.
      !                          Default: space, tab, LF, CR: 32, 9, 10, 13.
      ! ------------------------------------------------------------------------------
      subroutine str_token(string, token, quote, delims)
          !
          ! Call variables
          !
          character(*)          , intent(inout) :: string
          character(*)          , intent(out)   :: token
          character(1), optional, intent(in)    :: quote
          character(*), optional, intent(in)    :: delims !< String where each character will be used as a delimiter (replacing the default whitespace delimiters)
          !
          ! Local variables
          !
          integer :: i
          integer :: i1
          integer :: i2
          integer :: j
          integer :: strlen
          logical :: quoted
          integer :: ndelim
          integer, allocatable :: idelims(:) !< Integer character codes for one or more delimiters
          !
          !! executable statements ---------------------------------------------------
          !
          if (present(delims)) then
             ndelim = len(delims)
             allocate(idelims(ndelim))
             do i=1,ndelim
                idelims(i) = ichar(delims(i:i))
             end do
          else
             ndelim = 4
             allocate(idelims(ndelim))
             idelims = (/ 32, 9, 10, 13 /)
          end if

          i1     = -1
          i2     = -1
          quoted = .false.
          strlen = len_trim(string)
          ! find start of token
          do i = 1, strlen
             j = ichar(string(i:i))
             if (any(idelims == j)) then
                ! a delimiter (e.g. space)
                if (i1>0 .and. .not.quoted) then
                   ! token ends here
                   i2 = i-1
                   exit
                endif
             else
                ! not a delimiter
                if (i1<0) then
                   ! token starts here and may continue till the end of the string
                   if (present(quote)) then
                      if (string(i:i) == quote) then
                         quoted = .true.
                      endif
                   endif
                   i1 = i
                   i2 = strlen
                elseif (quoted) then
                   if (string(i:i) == quote) then
                      quoted = .false.
                   endif
                endif
             endif
          enddo
          !
          if (i1<0) then
             ! empty string: no token found
             token = ' '
          else
             ! token found
             token  = string(i1:i2)
             if (present(quote)) then
                ! remove quotes
                if (string(i1:i1)==quote .and. string(i2:i2)==quote) then
                   token = string(i1+1:i2-1)
                endif
             endif
             string = string(i2+1:strlen)
          endif
          
          if (allocated(idelims)) then
             deallocate(idelims)
          end if
      end subroutine str_token



      ! ------------------------------------------------------------------------------
      !   Subroutine: str_lower
      !   Purpose:    Convert upper case characters to lower case
      !   Summary:    Scan string for upper case characters and
      !               convert them.
      !   Arguments:
      !   string      String to be converted
      !   lenstr      Optional length of string to be converted
      ! ------------------------------------------------------------------------------
      subroutine str_lower(string, lenstr)
          !
          ! Call variables
          !
          integer     , optional, intent(in) :: lenstr
          character(*)                       :: string
          !
          ! Local variables
          !
          integer :: i
          integer :: j
          integer :: newlen
          !
          !! executable statements ---------------------------------------------------
          !
          if (present(lenstr)) then
             newlen = min(lenstr, len_trim(string))
          else
             newlen = len_trim(string)
          endif
          do i = 1, newlen
             j = ichar(string(i:i))
             if ((j>64) .and. (j<91)) then
                j = j + 32
                string(i:i) = char(j)
             endif
          enddo
      end subroutine str_lower



      ! ------------------------------------------------------------------------------
      !   Subroutine: str_upper
      !   Purpose:    Convert lower case characters to upper case
      !   Summary:    Scan string for lower case characters and
      !               convert them.
      !   Arguments:
      !   string      String to be converted
      !   lenstr      Optional length of string to be converted
      ! ------------------------------------------------------------------------------
      subroutine str_upper(string, lenstr)
          !
          ! Call variables
          !
          integer     , optional, intent(in) :: lenstr
          character(*)                       :: string
          !
          ! Local variables
          !
          integer :: i
          integer :: j
          integer :: newlen
          !
          !! executable statements ---------------------------------------------------
          !
          if (present(lenstr)) then
             newlen = min(lenstr, len_trim(string))
          else
             newlen = len_trim(string)
          endif
          do i = 1, newlen
             j = ichar(string(i:i))
             if ((j>96) .and. (j<123)) then
                j = j - 32
                string(i:i) = char(j)
             endif
          enddo
      end subroutine str_upper



      ! ------------------------------------------------------------------------------
      !   Subroutine: remove_all_spaces
      !   Purpose:    Remove all spaces from a string
      !   Summary:    Scan string for space characters and if one exists, move the
      !               following characters forward.
      !   Arguments:
      !   string      String to be converted
      !   lenstr      Optional trimmed length of string after removal of spaces
      ! ------------------------------------------------------------------------------
      subroutine remove_all_spaces(string, lenstr)
          !
          ! Call variables
          !
          character(*)                       :: string
          integer     , optional, intent(out):: lenstr
          !
          ! Local variables
          !
          integer :: i
          integer :: newlen
          !
          !! executable statements ---------------------------------------------------
          !
          newlen = len_trim(string)
          !
          ! loop over all characters in string
          !    if it is a space character, move remainder of string forward
          !
          i = 1
          do while (i<newlen)
             if (string(i:i)==' ') then
                string(i:newlen) = string(i+1:newlen) // ' '
                newlen = newlen-1
             else
                i = i+1
             endif
          enddo
          !
          if (present(lenstr)) then
             lenstr = newlen
          endif
      end subroutine remove_all_spaces



      ! ------------------------------------------------------------------------------
      !   Subroutine: remove_leading_spaces
      !   Purpose:    Remove leading spaces from a string
      !   Summary:    Scan string for space characters at beginning of string and
      !               if they exist, move the actual string forward.
      !   Arguments:
      !   string      String to be converted
      !   lenstr      Optional trimmed length of string after removal of spaces
      ! ------------------------------------------------------------------------------
      subroutine remove_leading_spaces(string, lenstr)
          !
          ! Call variables
          !
          character(*)                       :: string
          integer     , optional, intent(out):: lenstr
          !
          ! Local variables
          !
          integer :: i
          integer :: newlen
          !
          !! executable statements ---------------------------------------------------
          !
          newlen = len_trim(string)
          !
          ! find first non-space character
          !
          i = 1
          do while (i<newlen)
             if (string(i:i)==' ') then
                i = i+1
             else
                exit
             endif
          enddo
          !
          ! remove leading spaces
          !
          string = string(i:newlen)
          !
          if (present(lenstr)) then
             lenstr = len_trim(string)
          endif
      end subroutine remove_leading_spaces



      ! ------------------------------------------------------------------------------
      !   Function:   strcmpi
      !   Purpose:    Case-insensitive comparison of strings (upto certain length)
      !   Summary:    Change strings to lower case and compare (sub)strings.
      !   Arguments:
      !   string1     First string to be compared
      !   string2     Second string to be compared
      !   lencmp      Optional length over which to compare strings
      ! ------------------------------------------------------------------------------
      function strcmpi(string1, string2, lenreq) result(retval)
          !
          ! Call variables
          !
          character(*)                   , intent(in) :: string1
          character(*)                   , intent(in) :: string2
          integer              , optional, intent(in) :: lenreq
          logical                                     :: retVal  ! .true.  if strings are equal
                                                                 ! .false. if strings are not equal or len1 /= len2
          !
          ! Local variables
          !
          integer                                     :: len1    ! length of string1, without trailing blanks
          integer                                     :: len2    ! length of string2, without trailing blanks
          integer                                     :: lencmp  ! length of strings to be compared
          character(999) , dimension(:) , allocatable :: locstr  ! copy of strings, to convert to lowercase
          !
          !! executable statements ---------------------------------------------------
          !
          retval = .false.
          len1   = len_trim(string1)
          len2   = len_trim(string2)
          !
          ! determine comparison length
          !
          if (present(lenreq)) then
             lencmp = lenreq
          else
             lencmp = max(len1,len2)
          endif
          !
          ! do a quick check on string length
          !
          if (len1<lencmp .or. len2<lencmp) then
             !
             ! at least one string is shorter than the comparison length
             ! they can only be equal if their length is equal
             !
             if (len1 /= len2) then
                retval = .false.
                return
             else
                !
                ! strings have equal length, but are shorter than comparison length
                ! we only have to check the strings for their actual length
                !
                lencmp = len1
             endif
          endif
          !
          ! local copy of the strings needed to switch case without changing the
          ! original version.
          !
          allocate (locstr(2))
          !
          ! strings will be compared upto lencmp
          !
          locstr(1) = string1(1:lencmp)
          call str_lower(locstr(1), lencmp)
          !
          locstr(2) = string2(1:lencmp)
          call str_lower(locstr(2), lencmp)
          !
          if (locstr(1)(1:lencmp) == locstr(2)(1:lencmp)) then
             !
             ! strings are equal upto lencmp
             !
             retval = .true.
          else
             !
             ! strings are not equal
             !
             retval = .false.
          endif
          deallocate (locstr)
      end function strcmpi

      !> Determine the index of the first non-whitespace character in a string.
      !! Failure is indicated by: idx = 0
      function find_first_char(string) result(idx)
          implicit none
          integer                      :: idx    !< index of the first non-whitespace character in string.
          character(len=*), intent(in) :: string !< string to inspect

          integer                        :: i
          !
          do i = 1, len(string)
             if (.not. is_whitespace(string(i:i))) then
                idx = i
                return
             endif
          enddo
          idx = 0
      end function find_first_char

      !> Determine the indices of the first letter (not number) and last character of the first word in a string.
      !! Failure is indicated by: i1 = 0; i2 = 0
      subroutine find_first_word(string, i1, i2)
         character(len=*), intent(in)  :: string !< string to inspect
         integer,          intent(out) :: i1     !< string index of the first letter of the first word
         integer,          intent(out) :: i2     !< string index of the last character of the first word
         !
         integer :: i !< loop counter
         integer :: L !< length of string, excluding trailing whitespace
         !
         L = len_trim(string)
         i1 = find_first_letter(string(1:L))
         i2 = 0
         i = 0
         !
         if (i1 > 0) then
            i2 = L
            do i=i1+1, L
               if (is_whitespace(string(i:i))) then
                  i2 = i-1
                  exit
               end if
            end do
         end if
      end subroutine find_first_word
      
      !> Determine the index of the first letter in a string.
      !! Failure is indicated by: index = 0
      function find_first_letter(string) result(idx)
         integer                      :: idx  !< index of first letter
         character(len=*), intent(in) :: string !< string to inspect
         !
         integer :: i  !< loop index
         integer :: i1 !< helper variable
         integer :: i2 !< helper variable
         integer :: i3 !< helper variable
         !
         idx = 0
         do i=1, len_trim(string)
            i1 = index('qwertyuiopasdfghjklzxcvbnm', string(i:i))
            i2 = index('QWERTYUIOPASDFGHJKLZXCVBNM', string(i:i))
            i3 = max(i1, i2)
            if (i3 /= 0) then
               idx = i
               exit
            endif
         enddo
      end function find_first_letter
      
      !> Count the number of whitespace separated character groups.
      function count_words(string) result(number)
         integer                      :: number !< number of words
         character(len=*), intent(in) :: string !< string to inspect
         !
         integer :: i !< loop counter
         logical :: was_whitespace !< helper variable
         !
         number = 0
         was_whitespace = .true.
         !
         do i=1, len(string)
            if (is_whitespace(string(i:i))) then
               if (.not. was_whitespace) then
                  ! word has ended
                  was_whitespace = .true.
               end if
            else
               if (was_whitespace) then
                  ! word has started
                  number = number + 1
                  was_whitespace = .false.
               end if
            end if
         end do
      end function count_words
      
      !> Checks whether the character is whitespace.
      function is_whitespace(letter)
         logical                      :: is_whitespace !< 
         character(len=1), intent(in) :: letter        !< 
         !
         is_whitespace = .false.
         !
         if (letter == ' ') then ! space
            is_whitespace = .true.
         else if (letter == char(9)) then ! tab
            is_whitespace = .true.
         end if
      end function is_whitespace

      !> Replace character with code ichar1 by code ichar2
      subroutine replace_char(r,ichar1,ichar2) 
         character(len=*), intent(inout) :: r
         integer         , intent(in)    :: ichar1
         integer         , intent(in)    :: ichar2
         !
         integer :: ch
         integer :: i
         !
         do i=1,len_trim(r)
            ch = ichar(r(i:i))
            if (ch==ichar1) then
               r(i:i) = achar(ichar2)
            endif
         enddo
      end subroutine replace_char      
        
      !> Remove substring substr from r
      subroutine remove_substr(r,substr)
         character(len=*), intent(inout) :: r
         character(len=*), intent(in)    :: substr
         !
         integer :: first
         !
         first = index(r,substr)
         do while ((first>0) .and. (first<=len(trim(r))))
            r = r(1:first-1)//r(first+1:len_trim(r))
            first = index(r,substr)
         enddo 
      end subroutine remove_substr
      
      !> Split String at Separator
      function splitstr(string, strlen, separator) result(split)

         character(len=*), intent(inout)   :: string
         character(len=1), intent(in)      :: separator
         integer, intent(in)               :: strlen
         character(len=strlen)             :: split
      
         integer islash
      
         islash = index(string, separator)
         
         if (islash > 1) then
            split  = string(1:islash-1)
            string = string(islash+1:)
         else
            split = string
         endif
         
      end function splitstr

      subroutine get_substr_ndx(tgt,ndx0,ndx)
         implicit none
         character(len=*), intent(in)   ::  tgt
         integer, intent(inout)         ::  ndx0
         integer, intent(inout)         ::  ndx
         integer           :: ltrim
         logical           :: single_quoted
         logical           :: double_quoted
         single_quoted = .false.
         double_quoted = .false.
         ltrim = len_trim(tgt)
         do while(is_whitespace(tgt(ndx0:ndx0)) .and. (ndx0<=ltrim))
            ndx0 = ndx0 + 1
         enddo
         ndx = ndx0
         do while(ndx<=ltrim)
            if (.not.(single_quoted .or. double_quoted)) then
               if (is_whitespace(tgt(ndx:ndx))) exit
            endif
            if (tgt(ndx:ndx)=='"') double_quoted = .not.double_quoted
            if (tgt(ndx:ndx)=="'") single_quoted = .not.single_quoted
           ndx = ndx + 1
         enddo
      end subroutine get_substr_ndx

      !> Fill allocatable string array with elements of a space-delimited string
      !> The incoming string array must be unallocated
      recursive subroutine strsplit(tgt, ndx0, pcs, npc)
         implicit none
         integer,          intent(in)                                 ::  npc
         character(len=*), intent(inout)                              ::  tgt
         integer, intent(in)                                          ::  ndx0
         character(len=*), intent(inout), dimension(:), allocatable   ::  pcs
         integer                          ::  ndx, ndx1
         ndx1 = ndx0
         call get_substr_ndx(tgt,ndx1,ndx)
         if (ndx<=len_trim(tgt)) then
            call strsplit(tgt, ndx, pcs, npc+1)
         else
            allocate(pcs(npc))
         endif
         if (tgt(ndx1:ndx1)=='"' .or. tgt(ndx1:ndx1)=="'") ndx1 = ndx1 + 1
         if (tgt(ndx-1:ndx-1)=='"' .or. tgt(ndx:ndx)=="'") ndx = ndx - 1
         pcs(npc) = tgt(ndx1:ndx-1)
      end subroutine strsplit

end module string_module