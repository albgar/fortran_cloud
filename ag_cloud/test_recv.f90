program test_revc
   use cloud_0mq
   use iso_c_binding

   implicit none

   type(zeromq_ctx) :: ctx
   REAL(kind=c_double), allocatable :: data(:, :), data2(:, :)
   integer(kind=c_int) :: key
   integer :: i, j, tag, tag2

   character(len=30) :: name

   call get_command_argument(1,name)
   open(unit=1, file="wk-"//trim(name), form="formatted", status="replace")

   allocate (data(3, 17))
   allocate (data2(3, 17))

   call zeromq_ctx_init_rep(ctx, 'tcp://127.0.0.1:3446')
   do
      write(1,*) "worker: Receiving packet... ", trim(name)
      call zeromq_ctx_recv(ctx, data, tag)
      write(1, *) '===== worker: got tag:', tag, " ", trim(name)
      call flush(1)

      data = data + 1.0
      call sleep(2)
      write (1, *) '===== worker: done work on tag: ', tag, " ", trim(name)
      call flush(1)
      
      call zeromq_ctx_send(ctx, data, tag)
      write (1, *) '===== worker: sent results packet for tag:', tag, " ", trim(name)
      call flush(1)
   enddo

end program
