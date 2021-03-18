cmake_minimum_required(VERSION 3.8)

project(libc)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/cmake")

###########################################################
#                       Options                           #
###########################################################

set(MUSL_TARGET_PREFIX ""       CACHE STRING "Prefix to add to target names")
set(MUSL_ARCH          "x86_64" CACHE STRING "Architecture for which to build musl")
set(MUSL_BUILD_BITCODE ON       CACHE BOOL   "Whether to compile files down to bitcode")

mark_as_advanced(MUSL_TARGET_PREFIX)

###########################################################
#            Non-option cmake configuration               #
###########################################################

set(IR_USE_BITCODE ${MUSL_BUILD_BITCODE})
include(LLVMIRUtils)

set(PREFIX ${MUSL_TARGET_PREFIX})

set(CFLAGS_ALL
  -std=c99
  -nostdinc
  -ffreestanding
  -fno-builtin
  # -fexcess-precision=standard # not supported by clang
  # -frounding-math
  -D_XOPEN_SOURCE=700
  -fcolor-diagnostics
)

if ("${MUSL_ARCH}" STREQUAL "i386")
  list(APPEND CFLAGS_ALL -frounding-math)
endif()

# Set optimization flags
list(APPEND CFLAGS_ALL
  "$<$<CONFIG:Release>:-O2>"
  "$<$<CONFIG:RelWithDbgInfo>:-O2>"
  "$<$<CONFIG:MinSizeRel>:-Os>"
)

# Set debug info flags
list(APPEND CFLAGS_ALL
  "$<$<CONFIG:RelWithDbgInfo>:-g>"
  "$<$<CONFIG:Debug>:-g>"
)

# Silence some warnings that are hopefully intentional
list(APPEND CFLAGS_ALL
  -Wno-shift-op-parentheses
  -Wno-unknown-pragmas
  -Wno-string-plus-int
)

# Generated files
include(MuslGenerated)

# Need a dummy C file to make the target work
file(WRITE "${CMAKE_BINARY_DIR}/dummy.c" "")

# Overall libc target
add_llvm_ir_library(${PREFIX}libc "${CMAKE_BINARY_DIR}/dummy.c")
target_include_directories(${PREFIX}libc INTERFACE include)

# Source directories that we are currently able to build
set(source_dirs
  complex
  ctype
  math
  multibyte
  prng
  regex
  search
  stdlib
  string
)

foreach(dir ${source_dirs})
  file(GLOB sources
    src/${dir}/*.c
    src/${dir}/*.h
  )

  set(target ${PREFIX}${dir})

  add_llvm_ir_library(${target} "${sources}")

  # Note: order matters here!
  target_include_directories(${target} 
    PRIVATE arch/${MUSL_ARCH}
    PRIVATE arch/generic
    PRIVATE "${CMAKE_BINARY_DIR}/include/internal"
    PRIVATE src/include
    PRIVATE src/internal
    PRIVATE "${CMAKE_BINARY_DIR}/include"
  )
  target_include_directories(${target} PUBLIC include)

  target_compile_options(${target} PRIVATE ${CFLAGS_ALL})

  add_dependencies(${target} ${PREFIX}generated-files)

  # libc target includes all libraries
  target_link_libraries(${PREFIX}libc PRIVATE ${PREFIX}${dir})
endforeach()


