program test_revc
   use cloud_0mq
   use iso_c_binding

   implicit none

   type(zeromq_ctx) :: ctx
   REAL(kind=c_double), allocatable :: data(:, :)
   integer(kind=c_int) :: key
   integer :: i, j, tag

   character(len=30) :: name

   real(C_DOUBLE), parameter :: fail_prob = 0.0    ! deactivate for now 0.1
   real(C_DOUBLE), parameter :: crash_prob = fail_prob * 0.5

   call get_command_argument(1,name)
   open(unit=1, file="wk-"//trim(name), form="formatted", status="replace")

   allocate (data(3, 17))

   call zeromq_ctx_init_rep(ctx, 'tcp://127.0.0.1:3446')
   do

      call zeromq_ctx_recv(ctx, data, tag)
      write(1, *) '===== worker: got tag:', tag, " ", trim(name)
      call flush(1)

      if (fail_with_probability(crash_prob)) then
         write(0, *) '===== worker: CRASHED ', trim(name)
         call flush(0)
         write(1, *) '===== worker: CRASHED ', trim(name)
         call flush(1)
         stop "worker crashed"
      endif

      data = data + 1.0
      call sleep(5)
      write (1, *) '===== worker: done work on tag: ', tag, " ", trim(name)
      call flush(1)
      
      if (fail_with_probability(fail_prob)) then
         ! do not send back the result, as if the computation has failed
      else
         call zeromq_ctx_send(ctx, data, tag)
         write (1, *) '===== worker: sent results packet for tag:', tag, " ", trim(name)
         call flush(1)
      endif

   enddo

CONTAINS
  function fail_with_probability(x) result(fail)
    real(C_DOUBLE), intent(in) :: x
    logical                    :: fail

    real :: y
    call random_number(y)
    fail = (y <= x)

  end function fail_with_probability

end program
