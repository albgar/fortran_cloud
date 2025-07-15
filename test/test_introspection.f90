program test_introspection
   use cloud_0mq
   implicit none
   
   type(zeromq_packet) :: packet
   real(kind=4) :: array1(3) = [1.0, 2.0, 3.0]
   integer(kind=4) :: number = 42
   real(kind=4) :: array2(2) = [10.0, 20.0]
   integer :: num_items, data_bytes, header_bytes
   
   ! Build a packet with multiple items
   call zeromq_packet_write(packet, array1)
   call zeromq_packet_write(packet, number)
   call zeromq_packet_write(packet, array2)
   
   ! Analyze the packet
   call zeromq_packet_introspect(packet)
   
   call zeromq_packet_summary(packet, num_items, data_bytes, header_bytes)
   write(*,*) 'Summary: ', num_items, 'items,', data_bytes, 'data bytes,', header_bytes, 'header bytes'
   
   if (zeromq_packet_validate(packet)) then
      write(*,*) 'Packet structure is valid'
   else
      write(*,*) 'ERROR: Packet structure is invalid!'
   endif
   
   ! Show raw data (first 64 bytes)
   call zeromq_packet_hexdump(packet, 64)
end program
