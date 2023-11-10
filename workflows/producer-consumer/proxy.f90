program test_proxy
   use cloud_0mq
   implicit none
   write(*,*) "Calling run_proxy at 3445 and 3446..."
   call zeromq_run_proxy('tcp://127.0.0.1:3445', 'tcp://127.0.0.1:3446')
   write(*,*) "... done with run_proxy"
end program
