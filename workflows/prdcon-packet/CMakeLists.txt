add_executable(proxy-pkt proxy.f90)
add_executable(producer-pkt producer.f90)
add_executable(worker-pkt worker.f90)

target_link_libraries(proxy-pkt fortran_cloud)
target_link_libraries(producer-pkt fortran_cloud)
target_link_libraries(worker-pkt fortran_cloud)

install(
  TARGETS
  proxy-pkt producer-pkt worker-pkt
  DESTINATION
  "${CMAKE_INSTALL_BINDIR}"
)
