add_executable(test_packet test_packet.f90)
add_executable(test_introspection test_introspection.f90)

target_link_libraries(test_packet fortran_cloud)
target_link_libraries(test_introspection fortran_cloud)

install(
  TARGETS
  test_packet
  test_introspection
  DESTINATION
  "${CMAKE_INSTALL_BINDIR}"
)

