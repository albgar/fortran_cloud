program test
   use cloud_0mq
   use iso_c_binding

   implicit none

   type(zeromq_ctx) :: ctx
   REAL(kind=c_double), allocatable :: data(:, :)
   integer(kind=c_int) :: key
   integer :: i, j, tag, recv

   open(unit=2, file="results.dat", form="formatted", status="unknown", &
        position="rewind",action="write")

   allocate (data(3, 17))
   do i = 1, 17
      do j = 1, 3
         data(j, i) = real(i + j)
      enddo
!!      write (*, *) data(:, i)
   enddo

   call zeromq_ctx_init_dealer(ctx, 'tcp://127.0.0.1:3445')

   j = 0
   ! This is the main producer loop
   do
      write (*, *) "Sending packet for tag: ", j
      call zeromq_ctx_send(ctx, data, j)
      write (*, *) " -- done"

      ! This could be done by other thread. It is meant
      ! to recover the results from the workers
      ! As it is, the check is done once per outer iteration
      ! I do not understand why we need a loop
      do
         call zeromq_ctx_try_to_recv(ctx, data, tag, recv)
         
         if (recv > 0) then
            write (*, *) '====== Received tag:', tag
            write(2,*) 'Completed worker task for tag: ', tag
            call flush(2)
         else
            write (*, *) '... still waiting for results'
            exit
         endif
      enddo
      
      call sleep(1) ! This is the implicit cost of each producer step
      j = j + 1

   enddo

   close(2)
   
end program
