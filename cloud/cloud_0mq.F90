module cloud_0mq
   use zmq
!   use kinds, only: dp
   use iso_c_binding, only: c_double
   implicit none

   type :: zeromq_ctx
      type(c_ptr) :: ctx !context
      type(c_ptr) :: socket, socket2!socket
      integer(kind=c_int) :: ret
      logical :: send_empty_frame = .false.
      logical :: recv_empty_frame = .false.
   end type

   !write like interface
   type :: zeromq_packet
      character(kind=c_char), pointer :: data(:) => NULL()
      integer :: data_size = 0
      integer :: allocated_size = 0
      integer :: read_position = 0
      integer :: sent = 0
   end type

#include "module_procedures.fh"


contains
   !write like interface

#include "contains_sub.fh"

   subroutine zeromq_packet_free(z)
      type(zeromq_packet), intent(inout) :: z

      if (z%allocated_size>0) then
          deallocate(z%data)
      end if
      nullify(z%data)
      z%allocated_size=0
      z%data_size = 0
      z%read_position = 0
      z%sent = 0
   end subroutine

   subroutine zeromq_packet_realloc(z, requested_size)
      type(zeromq_packet), intent(inout) :: z
      integer,intent(in) :: requested_size
      character(kind=c_char), target, allocatable :: tmp(:)
      if (.not. associated(z%data)) then
         allocate(z%data(requested_size))
         z%allocated_size = requested_size
         z%data_size=0
         z%read_position=1
      else
         if (z%allocated_size < requested_size) then
            if (z%data_size>0) then
                allocate(tmp(z%allocated_size))
                tmp(1:z%data_size)=z%data(1:z%data_size)
            endif
            deallocate(z%data)
            allocate(z%data(requested_size))
            z%allocated_size=requested_size
            if (z%data_size>0) then
                z%data(1:z%data_size)=tmp(1:z%data_size)
                deallocate(tmp)
            endif
         endif
      endif
   end subroutine

   subroutine zeromq_packet_reset(z)
      type(zeromq_packet), intent(inout) :: z
      z%data_size=0
      z%read_position=1
   end subroutine

   subroutine zeromq_packet_append_char(z, wdata, data_size_)
      type(zeromq_packet), intent(inout) :: z
      character(kind=c_char), intent(in) :: wdata(:)
      integer,intent(in) :: data_size_
      !!
      integer :: data_size, offset
      character(kind=c_char) :: c


      data_size = data_size_+c_sizeof(data_size_)
      offset = 0

      if (data_size + z%data_size > z%allocated_size) &
          call zeromq_packet_realloc(z,(data_size + z%data_size)*3/2) ! alloc some extra space
      !write data size
      offset = 1+z%data_size
      z%data(offset:offset+c_sizeof(data_size)-1)=transfer(data_size_,c,c_sizeof(data_size_))
      !write data
      offset = offset + c_sizeof(data_size_)
      z%data(offset:offset+data_size_-1)=wdata(1:data_size_)
      z%data_size=z%data_size+data_size
   end subroutine

   subroutine zeromq_packet_read_char(z, rdata, data_size)
      type(zeromq_packet), intent(inout) :: z
      integer, intent(in) :: data_size
      character(kind=c_char), intent(inout) :: rdata(:)
      !!
      integer :: readed_data_size, last_pos
      last_pos = z%read_position + data_size + c_sizeof(readed_data_size) - 1
      if (last_pos <= z%data_size ) then
         if (data_size > 0) then
            readed_data_size = transfer(&
                     z%data(z%read_position:z%read_position+c_sizeof(readed_data_size)-1),&
                     readed_data_size)
            if (.not. (readed_data_size == data_size) ) then
                write (*,*) 'ERROR: readed data size (', readed_data_size, 'bytes ) is different from ',&
                       data_size 
            endif
            WRITE (*,*) 'data size is', readed_data_size
            z%read_position = z%read_position + c_sizeof(readed_data_size)
            rdata(1:data_size) =&
                    z%data(z%read_position:z%read_position+data_size-1)
            z%read_position=z%read_position+data_size
         else
            write (*,*) 'ERROR: requested read of ', data_size, 'bytes'
         endif
      else
         write (*,*) 'ERROR: cannot read past the end of the data packet ', z%data_size, last_pos
      endif
   end subroutine

   subroutine zeromq_packet_send(packet,z)
      use iso_c_binding, only : c_null_funptr, c_null_ptr
      type(zeromq_ctx), intent(inout) :: z
      type(zeromq_packet), intent(inout) :: packet
      type(zmq_msg_t) :: msg
      INTEGER(KIND=C_SIZE_T) :: SIZE_, s_
      character(kind=c_char) :: d
      integer :: rc

      size_ = c_sizeof(d)*packet%data_size
      s_ = 0
      !zeromq take ownership of data array
      rc = zmq_msg_init_data(msg, c_loc(packet%data), size_,c_null_funptr,c_null_ptr)
      if (rc /= 0) then
         write (*,*) 'ERROR: zmq_msg_init_data returned ', rc, ' size was ', size_
      else
         if (z%send_empty_frame) then
            z%ret = zmq_send(z%socket, c_loc(packet%data), s_, zmq_sndmore)
         endif
         z%ret = zmq_msg_send(msg, z%socket, 0)
         if (z%ret /= size_ ) then
             write (*,*) 'ERROR: zmq_msg_send returned ', z%ret, ' size was ', size_
         else
             packet%sent = z%ret
             nullify(packet%data)
             packet%allocated_size=0
             call zeromq_packet_reset(packet)
         endif
      endif

   end subroutine

   subroutine zeromq_packet_recv(packet, z)
      type(zeromq_ctx), intent(inout) :: z
      type(zeromq_packet), intent(inout) :: packet
      INTEGER(KIND=C_SIZE_T) ::  s_
      character(kind=c_char) :: d
      type(zmq_msg_t) :: msg
      integer :: rc
      character(kind=c_char), pointer :: data_p (:)

      s_ = 0
      rc = zmq_msg_init(msg)
      if ( rc /= 0) then
         write (*,*) 'ERROR: zmq_msg_init returned ', rc
      else
         if (z%recv_empty_frame) then
            write (*, *) 'waiting for first recv (empty message)'
            z%ret = zmq_recv(z%socket, c_loc(packet%data), s_, 0)
         endif
         write (*, *) 'waiting for recv'
         z%ret = zmq_msg_recv(msg, z%socket,  0)
         if (z%ret >= 0) then
             write (*, *) 'recv ', z%ret, ' bytes of data: copying it'
             call zeromq_packet_reset(packet)
             call zeromq_packet_realloc(packet, z%ret)
             call c_f_pointer(zmq_msg_data(msg), data_p, [z%ret] )
             packet%data(1:z%ret) = data_p(1:z%ret)
             packet%data_size = z%ret
             rc = zmq_msg_close(msg) 
         else
             write (*,*) 'ERROR: zmq_msg_recv returned ', z%ret
         endif
      endif
   end subroutine
   subroutine zeromq_packet_try_to_recv(packet, z, recv)
      type(zeromq_ctx), intent(inout) :: z
      type(zeromq_packet), intent(inout) :: packet
      integer, intent(out) :: recv
      integer(kind=c_int) :: nitems, res
      integer(kind=c_long) :: timeout
      type(zmq_pollitem_t), dimension(1) :: poll
      nitems = 1
      timeout = 0
      recv = 0
      poll(1)%socket = z%socket
      poll(1)%events = zmq_pollin
      res = zmq_poll(poll, nitems, timeout)
      write (*, *) 'poll:', res
      write (*, *) 'poll:', poll(1)%revents
      if (iand(poll(1)%revents, int(zmq_pollin,C_SHORT)) /= 0) then ! there is a new message, read it!
         call zeromq_packet_recv(packet, z)
         recv = 1
      end if
   end subroutine

   !initialization routines for generic, dealer and reply sockets
   subroutine zeromq_ctx_init_type(z, address, socket_type)
      type(zeromq_ctx), intent(inout) :: z
      character(*), intent(in) :: address
      integer(kind=c_int), intent(in) :: socket_type
      z%ctx = zmq_ctx_new()
      z%socket = zmq_socket(z%ctx, socket_type)
   end subroutine
   subroutine zeromq_ctx_init_rep(z, address)
      type(zeromq_ctx), intent(inout) :: z
      character(*), intent(in) :: address
      call zeromq_ctx_init_type(z, address, zmq_rep)
      z%ret = zmq_connect(z%socket, address)
      z%send_empty_frame = .false.
      z%recv_empty_frame = .false.
   end subroutine
   subroutine zeromq_ctx_init_dealer(z, address)
      type(zeromq_ctx), intent(inout) :: z
      character(*), intent(in) :: address
      call zeromq_ctx_init_type(z, address, zmq_dealer)
      z%ret = zmq_connect(z%socket, address)
      z%send_empty_frame = .true.
      z%recv_empty_frame = .true.
   end subroutine
   subroutine zeromq_run_proxy(address_router, address_dealer)
      use iso_c_binding
      type(zeromq_ctx) :: z
      character(*), intent(in) :: address_router, address_dealer
      z%ctx = zmq_ctx_new()
      z%socket = zmq_socket(z%ctx, zmq_router)
      z%socket2 = zmq_socket(z%ctx, zmq_dealer)
      z%ret = zmq_bind(z%socket, address_router)
      if (z%ret /= 0) write (*, *) 'ERROR in binding', address_router
      z%ret = zmq_bind(z%socket2, address_dealer)
      if (z%ret /= 0) write (*, *) 'ERROR in binding', address_dealer
      z%ret = zmq_proxy(z%socket, z%socket2, c_null_ptr)
   end subroutine

   !routine to send an array over zmq
   subroutine zeromq_ctx_send(z, data, tag)
      type(zeromq_ctx), intent(inout) :: z
      real(kind=c_double), intent(in) :: data(:, :)
      real(kind=c_double) :: d
      integer(kind=c_int), intent(in) :: tag
      INTEGER(KIND=C_INT) :: NBYTES
      INTEGER(KIND=C_SIZE_T) :: SIZE_, s_
      CHARACTER(KIND=C_CHAR, LEN=:), TARGET, ALLOCATABLE :: BUFFER
      CHARACTER(KIND=C_CHAR, LEN=:), POINTER :: RANGE_

      size_ = c_sizeof(d)*size(data) + c_sizeof(tag)
      ALLOCATE (CHARACTER(KIND=C_CHAR, LEN=SIZE_) :: BUFFER)
      RANGE_ => BUFFER(1:c_sizeof(tag))
      RANGE_ = TRANSFER(tag, RANGE_)
      RANGE_ => BUFFER(c_sizeof(tag):size_)
      RANGE_ = TRANSFER(data, RANGE_)
      s_ = 0
      if (z%send_empty_frame) &
         z%ret = zmq_send(z%socket, c_loc(buffer), s_, zmq_sndmore)
      z%ret = zmq_send(z%socket, c_loc(buffer), size_, 0)
      deallocate (buffer)
   end subroutine

   !routine to recv an array over zmq
   subroutine zeromq_ctx_recv(z, data, tag)
      type(zeromq_ctx), intent(inout) :: z
      real(kind=c_double), intent(inout), target :: data(:, :)
      real(kind=c_double) :: d
      integer, intent(out) :: tag
      INTEGER(KIND=C_INT) :: NBYTES
      INTEGER(KIND=C_SIZE_T) :: SIZE_, s_
      CHARACTER(KIND=C_CHAR, LEN=:), TARGET, ALLOCATABLE :: BUFFER
      CHARACTER(KIND=C_CHAR, LEN=:), POINTER :: RANGE
      real(kind=c_double), pointer :: d_(:)
      integer :: i, s_data(2)
      s_ = 0
      size_ = c_sizeof(d)*size(data) + c_sizeof(tag)
      ALLOCATE (CHARACTER(KIND=C_CHAR, LEN=SIZE_) :: BUFFER)
      if (z%recv_empty_frame) then
         write (*, *) 'waiting for first recv (empty message)'
         z%ret = zmq_recv(z%socket, c_loc(buffer), s_, 0)
      endif
      write (*, *) 'waiting for recv'
      z%ret = zmq_recv(z%socket, c_loc(buffer), size_, 0)
      write (*, *) 'recv data: copying it'
      range => buffer(1:c_sizeof(tag))
      tag = transfer(range, tag)
      range => buffer(c_sizeof(tag):size_)
      !d_ => data
      !d_ => transfer(range, d_)
      s_data=shape(data)
      do i=1, s_data(2)
         data(:,i) = transfer(range((i-1)*s_data(1)*c_sizeof(d)+1:i*s_data(1)*c_sizeof(d)),data(:,i))
      enddo

      deallocate (buffer)
   end subroutine

   subroutine zeromq_ctx_try_to_recv(z, data, tag, recv)
      type(zeromq_ctx), intent(inout) :: z
      real(kind=c_double), intent(inout), target :: data(:, :)
      integer, intent(out) :: tag
      integer, intent(out) :: recv
      integer(kind=c_int) :: nitems, res
      integer(kind=c_long) :: timeout
      type(zmq_pollitem_t), dimension(1) :: poll
      nitems = 1
      timeout = 0
      tag = 0
      recv = 0
      poll(1)%socket = z%socket
      poll(1)%events = zmq_pollin
      res = zmq_poll(poll, nitems, timeout)
      write (*, *) 'poll:', res
      write (*, *) 'poll:', poll(1)%revents
      if (iand(poll(1)%revents, int(zmq_pollin,C_SHORT)) /= 0) then ! there is a new message, read it!
         call zeromq_ctx_recv(z, data, tag)
         recv = 1
      end if
   end subroutine

!
! Extra routines for debugging support
!
!> Introspect packet contents without modifying read position
   subroutine zeromq_packet_introspect(packet)
      type(zeromq_packet), intent(in) :: packet
      integer :: pos, item_count, item_size, i
      integer :: original_read_pos
      
      if (.not. associated(packet%data) .or. packet%data_size == 0) then
         write(*,*) 'Packet is empty'
         return
      endif
      
      write(*,*) '=== Packet Introspection ==='
      write(*,*) 'Total packet size:', packet%data_size, 'bytes'
      write(*,*) 'Allocated size:', packet%allocated_size, 'bytes'
      write(*,*) 'Current read position:', packet%read_position
      write(*,*) ''
      
      pos = 1
      item_count = 0
      
      do while (pos + c_sizeof(item_size) - 1 <= packet%data_size)
         ! Read the size header
         item_size = transfer(packet%data(pos:pos+c_sizeof(item_size)-1), item_size)
         
         item_count = item_count + 1
         write(*,*) 'Item', item_count, ':'
         write(*,*) '  Position:', pos
         write(*,*) '  Header size:', c_sizeof(item_size), 'bytes'
         write(*,*) '  Data size:', item_size, 'bytes'
         write(*,*) '  Total item size:', item_size + c_sizeof(item_size), 'bytes'
         
         ! Move to next item
         pos = pos + c_sizeof(item_size) + item_size
         
         ! Safety check
         if (pos > packet%data_size + 1) then
            write(*,*) '  ERROR: Item extends beyond packet boundary!'
            exit
         endif
      end do
      
      write(*,*) ''
      write(*,*) 'Total items found:', item_count
      write(*,*) 'Bytes accounted for:', pos - 1
      
      if (pos - 1 /= packet%data_size) then
         write(*,*) 'WARNING: Size mismatch! Expected:', packet%data_size, 'Got:', pos - 1
      endif
      
      write(*,*) '=========================='
   end subroutine

   !> Get summary statistics about packet contents
   subroutine zeromq_packet_summary(packet, num_items, total_data_bytes, total_header_bytes)
      type(zeromq_packet), intent(in) :: packet
      integer, intent(out) :: num_items, total_data_bytes, total_header_bytes
      integer :: pos, item_size
      
      num_items = 0
      total_data_bytes = 0
      total_header_bytes = 0
      
      if (.not. associated(packet%data) .or. packet%data_size == 0) then
         return
      endif
      
      pos = 1
      do while (pos + c_sizeof(item_size) - 1 <= packet%data_size)
         ! Read the size header
         item_size = transfer(packet%data(pos:pos+c_sizeof(item_size)-1), item_size)
         
         num_items = num_items + 1
         total_header_bytes = total_header_bytes + c_sizeof(item_size)
         total_data_bytes = total_data_bytes + item_size
         
         ! Move to next item
         pos = pos + c_sizeof(item_size) + item_size
         
         ! Safety check
         if (pos > packet%data_size + 1) then
            exit
         endif
      end do
   end subroutine

   !> Validate packet structure
   logical function zeromq_packet_validate(packet)
      type(zeromq_packet), intent(in) :: packet
      integer :: pos, item_size, item_count
      
      zeromq_packet_validate = .false.
      
      if (.not. associated(packet%data)) then
         if (packet%data_size == 0) then
            zeromq_packet_validate = .true.  ! Empty packet is valid
         endif
         return
      endif
      
      if (packet%data_size < 0 .or. packet%data_size > packet%allocated_size) then
         return
      endif
      
      if (packet%read_position < 1) then
         return
      endif
      
      pos = 1
      item_count = 0
      
      do while (pos <= packet%data_size)
         ! Check if we have enough space for a size header
         if (pos + c_sizeof(item_size) - 1 > packet%data_size) then
            return  ! Incomplete header
         endif
         
         ! Read the size header
         item_size = transfer(packet%data(pos:pos+c_sizeof(item_size)-1), item_size)
         
         ! Check for reasonable size
         if (item_size < 0 .or. item_size > packet%data_size) then
            return  ! Invalid size
         endif
         
         item_count = item_count + 1
         
         ! Check if we have enough space for the data
         if (pos + c_sizeof(item_size) + item_size - 1 > packet%data_size) then
            return  ! Incomplete data
         endif
         
         ! Move to next item
         pos = pos + c_sizeof(item_size) + item_size
      end do
      
      ! Should end exactly at the end of the packet
      zeromq_packet_validate = (pos - 1 == packet%data_size)
   end function

   !> Print packet contents in hex dump style (for debugging)
   subroutine zeromq_packet_hexdump(packet, max_bytes)
      type(zeromq_packet), intent(in) :: packet
      integer, intent(in), optional :: max_bytes
      integer :: limit, i, j, start_pos
      character(len=2) :: hex_byte
      character(len=16) :: ascii_line
      
      if (.not. associated(packet%data) .or. packet%data_size == 0) then
         write(*,*) 'Packet is empty'
         return
      endif
      
      limit = packet%data_size
      if (present(max_bytes)) then
         limit = min(limit, max_bytes)
      endif
      
      write(*,*) '=== Packet Hex Dump (first', limit, 'bytes) ==='
      
      do i = 1, limit, 16
         write(*,'(A,I6.6,A)', advance='no') 'Offset ', i-1, ': '
         
         ! Print hex bytes
         ascii_line = ''
         do j = 0, 15
            if (i + j <= limit) then
               write(hex_byte, '(Z2.2)') ichar(packet%data(i + j))
               write(*,'(A,A)', advance='no') hex_byte, ' '
               
               ! Build ASCII representation
               if (ichar(packet%data(i + j)) >= 32 .and. ichar(packet%data(i + j)) <= 126) then
                  ascii_line(j+1:j+1) = packet%data(i + j)
               else
                  ascii_line(j+1:j+1) = '.'
               endif
            else
               write(*,'(A)', advance='no') '   '
            endif
         end do
         
         write(*,'(A,A)') ' | ', trim(ascii_line)
      end do
      
      write(*,*) '===================='
   end subroutine
end module
