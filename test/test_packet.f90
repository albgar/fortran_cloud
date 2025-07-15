program test_packet_bugs
   use cloud_0mq
   use iso_c_binding
   implicit none

   type(zeromq_packet) :: packet
   real(kind=4) :: original_array(3) = [1.5, 2.5, 3.5]
   real(kind=4) :: read_array(3)
   real(kind=4) :: second_array(2) = [10.0, 20.0]
   real(kind=4) :: read_second(2)
   real(kind=4) :: large_array(100)
   real(kind=4) :: read_large(100)
   
   integer :: i
   integer :: error_count = 0
   
   write(*,*) 'Testing packet write/read with real array'
   write(*,*) 'Original array:', original_array
   
   ! Initialize packet
   call zeromq_packet_reset(packet)
   
   ! Write the array to packet
   write(*,*) 'Writing array to packet...'
   call zeromq_packet_write(packet, original_array)
   
   write(*,*) 'Packet data_size after write:', packet%data_size
   write(*,*) 'Expected size should be:', size(original_array) * c_sizeof(original_array(1)) + c_sizeof(original_array(1))
   
   ! Try to read it back
   write(*,*) 'Reading array from packet...'
   call zeromq_packet_read(packet, read_array)
   
   write(*,*) 'Read array:', read_array
   
   ! Check if arrays match
   write(*,*) 'Checking results...'
   do i = 1, 3
      if (abs(original_array(i) - read_array(i)) > 1e-6) then
         write(*,*) 'ERROR: Mismatch at position', i
         write(*,*) '  Original:', original_array(i)
         write(*,*) '  Read back:', read_array(i)
      else
         write(*,*) 'Position', i, 'OK'
      endif
   end do
   
   ! Test multiple writes to same packet
   write(*,*) ''
   write(*,*) 'Testing multiple writes to same packet...'
   
   
   ! Write second array to same packet
   call zeromq_packet_write(packet, second_array)
   write(*,*) 'Packet data_size after second write:', packet%data_size
   
   ! Reset read position and read both arrays
   packet%read_position = 1
   call zeromq_packet_read(packet, read_array)
   call zeromq_packet_read(packet, read_second)
   
   write(*,*) 'First array read back:', read_array
   write(*,*) 'Second array read back:', read_second
   write(*,*) 'Original second array:', second_array
   
   ! Test with larger array that might cause reallocation
   write(*,*) ''
   write(*,*) 'Testing with larger array...'
   
   ! Fill large array with test data
   do i = 1, 100
      large_array(i) = real(i) * 0.1
   end do
   
   call zeromq_packet_reset(packet)
   call zeromq_packet_write(packet, large_array)
   call zeromq_packet_read(packet, read_large)
   
   write(*,*) 'Large array test:'
   write(*,*) '  First 5 original:', large_array(1:5)
   write(*,*) '  First 5 read back:', read_large(1:5)
   write(*,*) '  Last 5 original:', large_array(96:100)
   write(*,*) '  Last 5 read back:', read_large(96:100)
   
   ! Check for any mismatches in large array
   do i = 1, 100
      if (abs(large_array(i) - read_large(i)) > 1e-6) then
         error_count = error_count + 1
         if (error_count <= 5) then  ! Only print first 5 errors
            write(*,*) 'ERROR at position', i, ':', large_array(i), 'vs', read_large(i)
         endif
      endif
   end do
   
   if (error_count == 0) then
      write(*,*) 'Large array test PASSED'
   else
      write(*,*) 'Large array test FAILED with', error_count, 'errors'
   endif
   
   ! Clean up
   call zeromq_packet_free(packet)
   
   write(*,*) 'Test completed.'

end program test_packet_bugs
