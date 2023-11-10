add_executable(proxy proxy.f90)
add_executable(producer producer.f90)
add_executable(consumer consumer.f90)

target_link_libraries(proxy fortran_cloud)
target_link_libraries(producer fortran_cloud)
target_link_libraries(consumer fortran_cloud)

install(
  TARGETS
  proxy producer consumer
  DESTINATION
  "${CMAKE_INSTALL_BINDIR}"
)
