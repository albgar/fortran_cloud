program test_revc
   use cloud_0mq
   use iso_c_binding

   implicit none

   type(zeromq_ctx) :: ctx
   type(zeromq_packet) :: packet
   REAL(kind=c_double), allocatable :: data(:, :), data2(:, :)
   integer(kind=c_int) :: key
   integer :: i, j, tag, tag2

   character(len=30) :: name
   
   call get_command_argument(1,name)
   open(unit=1, file="wk-"//trim(name), form="formatted", status="replace")
   
   allocate (data(3, 17))
   allocate (data2(3, 17))

   write(1,*) "worker: Setting up rep at 3446...", trim(name)
   call zeromq_ctx_init_rep(ctx, 'tcp://127.0.0.1:3446')
   write(1,*) "worker: ... done" , trim(name)
   call flush(1)
   do
      write(1,*) "worker: Receiving packet...", trim(name)
      call zeromq_packet_recv(packet, ctx)
      call zeromq_packet_read(packet, tag)
      call zeromq_packet_read(packet, data)
      write(1, *) '===== worker: got tag:', tag, " ", trim(name)
      write(1, *) '===== worker: Performing work on tag: ', tag, " ", trim(name)
      call flush(1)
      do i = 1, 17
         do j = 1, 3
            data(j, i) = data(j, i) + 1.0
         enddo
       !!  write(1, *) data(:, i)
      enddo
      call sleep(5)
      write (1, *) '===== worker: done work on tag: ', tag, " ", trim(name)
      call flush(1)
      call zeromq_packet_reset(packet)
      call zeromq_packet_write(packet, tag)
      call zeromq_packet_write(packet, data)
      call zeromq_packet_send(packet,ctx)
      write (1, *) '===== worker: sent results packet for tag:', tag, " ", trim(name)
      call flush(1)
   enddo

   close(1)
   
end program
