
make_directory("${CMAKE_BINARY_DIR}/include/bits")
make_directory("${CMAKE_BINARY_DIR}/include/internal")

add_custom_command(
  OUTPUT "${CMAKE_BINARY_DIR}/include/bits/alltypes.h"
  COMMAND sh ARGS -c "sed -f tools/mkalltypes.sed arch/${MUSL_ARCH}/bits/alltypes.h.in include/alltypes.h.in > '${CMAKE_BINARY_DIR}/include/bits/alltypes.h'"
  DEPENDS "${CMAKE_SOURCE_DIR}/VERSION" "${CMAKE_SOURCE_DIR}/.git"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  VERBATIM
)

add_custom_command(
  OUTPUT "${CMAKE_BINARY_DIR}/include/bits/syscall.h"
  COMMAND sh ARGS -c "cp \"arch/${MUSL_ARCH}/bits/syscall.h.in\" \"${CMAKE_BINARY_DIR}/include/bits/syscall.h\"; sed -n -e s/__NR_/SYS_/p < \"arch/${MUSL_ARCH}/bits/syscall.h.in\" >> \"${CMAKE_BINARY_DIR}/include/bits/syscall.h\""
  DEPENDS "arch/${MUSL_ARCH}/bits/syscall.h.in"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  VERBATIM
)

add_custom_command(
  OUTPUT "${CMAKE_BINARY_DIR}/include/internal/version.h"
  COMMAND sh ARGS -c "sh tools/version.sh > \"${CMAKE_BINARY_DIR}/include/internal/version.h\""
  DEPENDS "${CMAKE_SOURCE_DIR}/VERSION" "${CMAKE_SOURCE_DIR}/.git"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  VERBATIM
)

add_custom_target(${PREFIX}generated-files
  DEPENDS
    "${CMAKE_BINARY_DIR}/include/bits/alltypes.h"
    "${CMAKE_BINARY_DIR}/include/bits/syscall.h"
    "${CMAKE_BINARY_DIR}/include/internal/version.h"
)
