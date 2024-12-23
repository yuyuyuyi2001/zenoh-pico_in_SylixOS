set(CMAKE_SYSTEM_NAME SylixOS)
set(SYLIXOS ON)
set(ENV{SYLIXOS} ON)
set(POSIX_COMPATIBLE true)

# config.mk
if(CMAKE_SYLIXOS_BASE_PATH)
string(REPLACE "\\" "/" result "${CMAKE_SYLIXOS_BASE_PATH}")
set(CMAKE_SYLIXOS_BASE_PATH ${result})
set(ENV{SYLIXOS_BASE_PATH} "${CMAKE_SYLIXOS_BASE_PATH}")
else()
return()
endif()

set(SYLIXOS_BASE_PATH $ENV{SYLIXOS_BASE_PATH})
message(STATUS "SylixOS Base Path: ${SYLIXOS_BASE_PATH}")
if(NOT EXISTS ${SYLIXOS_BASE_PATH})
message(FATAL_ERROR "${SYLIXOS_BASE_PATH} not found.")
endif()

if(SYLIXOS_BASE_PATH)
file(STRINGS "${SYLIXOS_BASE_PATH}/config.mk" MK_STRINGS REGEX "^MULTI_PLATFORM_BUILD := .*")
string(REPLACE "MULTI_PLATFORM_BUILD := " "" MULTI_PLATFORM_BUILD "${MK_STRINGS}")

message(STATUS "MULTI_PLATFORM_BUILD := ${MULTI_PLATFORM_BUILD}")
if (MULTI_PLATFORM_BUILD STREQUAL "yes")
    message(FATAL_ERROR "${SYLIXOS_BASE_PATH} is multi platform build. CMake not support.")
else ()
    file(STRINGS "${SYLIXOS_BASE_PATH}/config.mk" MK_STRINGS REGEX "^TOOLCHAIN_PREFIX := .*")
    string(REPLACE "TOOLCHAIN_PREFIX := " "" TOOLCHAIN_PREFIX "${MK_STRINGS}")

    file(STRINGS "${SYLIXOS_BASE_PATH}/config.mk" MK_STRINGS REGEX "^FPU_TYPE := .*")
    string(REPLACE "FPU_TYPE := " "" FPU_TYPE "${MK_STRINGS}")

    file(STRINGS "${SYLIXOS_BASE_PATH}/config.mk" MK_STRINGS REGEX "^CPU_TYPE := .*")
    string(REPLACE "CPU_TYPE := " "" CPU_TYPE "${MK_STRINGS}")

    file(STRINGS "${SYLIXOS_BASE_PATH}/config.mk" MK_STRINGS REGEX "^DEBUG_LEVEL := .*")
    string(REPLACE "DEBUG_LEVEL := " "" DEBUG_LEVEL "${MK_STRINGS}")
    endif()
endif()

message(STATUS "TOOLCHAIN_PREFIX := ${TOOLCHAIN_PREFIX}")
message(STATUS "FPU_TYPE := ${FPU_TYPE}")
message(STATUS "CPU_TYPE := ${CPU_TYPE}")


# target.mk
set(LOCAL_INC_PATH         "")
set(LOCAL_DSYMBOL          "")
set(LOCAL_CFLAGS           "")
set(LOCAL_CXXFLAGS         "")
set(LOCAL_LINKFLAGS        "")
set(LOCAL_DEPEND_LIB       "")
set(LOCAL_DEPEND_LIB_PATH  "")
set(LOCAL_USE_CXX          "yes")
set(LOCAL_USE_CXX_EXCEPT   "no")
set(LOCAL_USE_GCOV         "no")
set(LOCAL_USE_OMP          "no")
set(LOCAL_NO_UNDEF_SYM     "no")

if(FPU_TYPE AND NOT(FPU_TYPE MATCHES "disable") AND NOT(FPU_TYPE MATCHES "default"))
  if((FPU_TYPE MATCHES "hard-float") OR (FPU_TYPE MATCHES "soft-float") OR (FPU_TYPE MATCHES "double-float") OR (FPU_TYPE MATCHES "float-abi=soft") OR (FPU_TYPE MATCHES "float-abi=hard"))
    set(ARCH_FPUFLAGS       "-m${FPU_TYPE}")
  elseif(FPU_TYPE MATCHES "softfp")
    set(ARCH_FPUFLAGS "-mfloat-abi=softfp")
  else()
    set(ARCH_FPUFLAGS "-mfloat-abi=softfp -mfpu=${FPU_TYPE}")
  endif()
endif()

# arch.mk
# x86-64
if(TOOLCHAIN_PREFIX STREQUAL x86_64-sylixos-elf-)
set(CMAKE_SYSTEM_PROCESSOR "x86_64")

set(ARCH_COMMONFLAGS    "-mlong-double-64 -mno-red-zone -fno-omit-frame-pointer -fno-strict-aliasing")

set(ARCH_PIC_ASFLAGS    "")
set(ARCH_PIC_CFLAGS     "-fPIC")
set(ARCH_PIC_LDFLAGS    "-Wl,-shared -fPIC -shared")

set(ARCH_KO_CFLAGS      "-mcmodel=large")
set(ARCH_KO_LDFLAGS     "-nostdlib -r")

set(ARCH_KLIB_CFLAGS    "-mcmodel=large")

set(ARCH_KERNEL_CFLAGS  "-mcmodel=kernel")
set(ARCH_KERNEL_LDFLAGS "-z max-page-size=4096")

if(CPU_TYPE AND NOT(FPU_TYPE MATCHES "generic"))
set(ARCH_CPUFLAGS       "-march=${CPU_TYPE} -m64 ${ARCH_FPUFLAGS}")
else()
set(ARCH_CPUFLAGS       "-m64 ${ARCH_FPUFLAGS}")
endif()

endif()

#aarch64
if(TOOLCHAIN_PREFIX STREQUAL aarch64-sylixos-elf-)
set(CMAKE_SYSTEM_PROCESSOR "aarch64")

set(ARCH_COMMONFLAGS    "-fno-omit-frame-pointer -mstrict-align -ffixed-x18 -fno-strict-aliasing")

set(ARCH_PIC_ASFLAGS    "")
set(ARCH_PIC_CFLAGS     "-fPIC")
set(ARCH_PIC_LDFLAGS    "-Wl,-shared -fPIC -shared")

set(ARCH_KO_CFLAGS      "-mcmodel=large -mgeneral-regs-only")
set(ARCH_KO_LDFLAGS     "-nostdlib -r")

set(ARCH_KLIB_CFLAGS    "")

set(ARCH_KERNEL_CFLAGS  "-mgeneral-regs-only")
set(ARCH_KERNEL_LDFLAGS "-Wl,--build-id=none")
set(ARCH_CPUFLAGS       "-mcpu=${CPU_TYPE} ${ARCH_FPUFLAGS}")

endif()

# gcc.mk

# specify cross compilers and tools
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

set(CMAKE_C_COMPILER    ${TOOLCHAIN_PREFIX}gcc CACHE PATH "SylixOS Base Path")
set(CMAKE_CXX_COMPILER  ${TOOLCHAIN_PREFIX}g++ CACHE PATH "SylixOS Base Path")
set(CMAKE_ASM_COMPILER  ${TOOLCHAIN_PREFIX}gcc CACHE PATH "SylixOS Base Path")
set(CMAKE_LINKER        ${TOOLCHAIN_PREFIX}g++ CACHE PATH "SylixOS Base Path")
set(CMAKE_OBJCOPY       ${TOOLCHAIN_PREFIX}objcopy CACHE PATH "SylixOS Base Path")
set(CMAKE_OBJDUMP       ${TOOLCHAIN_PREFIX}objdump CACHE PATH "SylixOS Base Path")
set(CMAKE_AR            ${TOOLCHAIN_PREFIX}ar CACHE PATH "SylixOS Base Path")
set(CMAKE_SIZE          ${TOOLCHAIN_PREFIX}size CACHE PATH "SylixOS Base Path")
set(CMAKE_RANLIB        ${TOOLCHAIN_PREFIX}ranlib CACHE PATH "SylixOS Base Path")

# Compiler optimize flag
set(TOOLCHAIN_OPTIMIZE_DEBUG "-O0 -g3 -gdwarf-2")
set(TOOLCHAIN_OPTIMIZE_RELEASE "-O2 -g3 -gdwarf-2")

# Toolchain flag
set(TOOLCHAIN_CXX_CFLAGS "")
set(TOOLCHAIN_CXX_EXCEPT_CFLAGS "${TOOLCHAIN_CXX_CFLAGS} -fexceptions -frtti")
set(TOOLCHAIN_NO_CXX_EXCEPT_CFLAGS "${TOOLCHAIN_CXX_CFLAGS} -fno-exceptions -fno-rtti")
set(TOOLCHAIN_GCOV_CFLAGS "-fprofile-arcs -ftest-coverage")
set(TOOLCHAIN_OMP_FLAGS "-fopenmp")
set(TOOLCHAIN_COMMONFLAGS "-Wall -fmessage-length=0 -fsigned-char -fno-short-enums")
set(TOOLCHAIN_ASFLAGS "-x assembler-with-cpp")
set(TOOLCHAIN_NO_UNDEF_SYM_FLAGS "@${SYLIXOS_BASE_PATH}/libsylixos/${CMAKE_BUILD_TYPE}/symbol.ld")
set(TOOLCHAIN_AR_FLAGS "-r")
set(TOOLCHAIN_STRIP_FLAGS "")
set(TOOLCHAIN_STRIP_KO_FLAGS "--strip-unneeded")

# Include paths
set(TARGET_INC_PATH "${LOCAL_INC_PATH} -I${SYLIXOS_BASE_PATH}/libsylixos/SylixOS -I${SYLIXOS_BASE_PATH}/libsylixos/SylixOS/include -I${SYLIXOS_BASE_PATH}/libsylixos/SylixOS/include/network")


# Compiler preprocess
set(TARGET_DSYMBOL "-DSYLIXOS ${LOCAL_DSYMBOL}")

# Compiler flags
set(TARGET_CFLAGS "${LOCAL_CFLAGS}")
set(TARGET_CXXFLAGS "${LOCAL_CXXFLAGS}")
set(TARGET_LINKFLAGS "${SYLIXOS_BASE_PATH}/libsylixos/Release;${SYLIXOS_BASE_PATH}/libsylixos/Debug;${SYLIXOS_BASE_PATH}/libcextern/Release;${SYLIXOS_BASE_PATH}/libcextern/Debug")
if(LOCAL_USE_CXX STREQUAL yes)
    set(TARGET_LIBRARIES "cextern;vpmpdm;stdc++;dsohandle;m;gcc")
else()
    set(TARGET_LIBRARIES "cextern;vpmpdm;m;gcc")
endif()

# Depend and compiler parameter (cplusplus in kernel MUST NOT use exceptions and rtti)
if(LOCAL_USE_GCOV STREQUAL yes)
    set(TARGET_GCOV_FLAGS "${TOOLCHAIN_GCOV_CFLAGS}")
else()
    set(TARGET_GCOV_FLAGS "")
endif()
if(LOCAL_USE_OMP STREQUAL yes)
    set(TARGET_OMP_FLAGS "${TOOLCHAIN_OMP_FLAGS}")
else()
    set(TARGET_OMP_FLAGS "")
endif()

if(LOCAL_NO_UNDEF_SYM STREQUAL yes)
    set(TARGET_NO_UNDEF_SYM_FLAGS "${TOOLCHAIN_NO_UNDEF_SYM_FLAGS}")
else()
    set(TARGET_NO_UNDEF_SYM_FLAGS "")
endif()

if(LOCAL_USE_CXX_EXCEPT STREQUAL yes)
    set(TARGET_CXX_EXCEPT ${TOOLCHAIN_CXX_EXCEPT_CFLAGS})
else()
    set(TARGET_CXX_EXCEPT ${TOOLCHAIN_NO_CXX_EXCEPT_CFLAGS})
endif()

set(TARGET_CPUFLAGS "${ARCH_CPUFLAGS}")
set(TARGET_COMMONFLAGS "${TARGET_CPUFLAGS} ${ARCH_COMMONFLAGS} ${TOOLCHAIN_COMMONFLAGS} ${TARGET_GCOV_FLAGS} ${TARGET_OMP_FLAGS}")
set(CMAKE_THREAD_LIBS_INIT "")
set(CMAKE_DL_LIBS "")
set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG "-Wl,-rpath,")
set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG_SEP ":")
set(CMAKE_SHARED_LIBRARY_RPATH_ORIGIN_TOKEN "\$ORIGIN")
set(CMAKE_SHARED_LIBRARY_RPATH_LINK_C_FLAG "-Wl,-rpath-link,")
set(CMAKE_SHARED_LIBRARY_SONAME_C_FLAG "-Wl,-soname,")
set(CMAKE_EXE_EXPORTS_C_FLAG "-Wl,--export-dynamic")

set(CMAKE_ASM_FLAGS           "${TARGET_INC_PATH} ${TARGET_COMMONFLAGS} ${ARCH_PIC_ASFLAGS} ${TOOLCHAIN_ASFLAGS} ${TARGET_DSYMBOL}" CACHE INTERNAL "ASM Compiler options")
set(CMAKE_C_FLAGS             "${TARGET_INC_PATH} ${TARGET_COMMONFLAGS} ${ARCH_PIC_CFLAGS} ${TARGET_DSYMBOL} ${TARGET_CFLAGS}" CACHE INTERNAL "C Compiler options")
set(CMAKE_CXX_FLAGS           "${TARGET_INC_PATH} ${TARGET_COMMONFLAGS} ${ARCH_PIC_CFLAGS} ${TARGET_DSYMBOL} ${TARGET_CXX_EXCEPT} ${TARGET_CXXFLAGS}" CACHE INTERNAL "C++ Compiler options")
set(CMAKE_EXE_LINKER_FLAGS    "-nostartfiles ${ARCH_PIC_LDFLAGS} ${TARGET_NO_UNDEF_SYM_FLAGS} " CACHE INTERNAL "Linker options")
set(CMAKE_SHARED_LINKER_FLAGS "-nostartfiles ${ARCH_PIC_LDFLAGS} " CACHE INTERNAL "Shared library Linker options")
set(CMAKE_MODULE_LINKER_FLAGS ${CMAKE_SHARED_LINKER_FLAGS})

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)


set(CMAKE_C_FLAGS_DEBUG "${TOOLCHAIN_OPTIMIZE_DEBUG}")
set(CMAKE_C_FLAGS_RELEASE "${TOOLCHAIN_OPTIMIZE_RELEASE}")
set(CMAKE_C_FLAGS_MINSIZEREL "")
set(CMAKE_C_FLAGS_RELEWITHDEBINFO "")
set(CMAKE_CXX_FLAGS_DEBUG "${TOOLCHAIN_OPTIMIZE_DEBUG}")
set(CMAKE_CXX_FLAGS_RELEASE "${TOOLCHAIN_OPTIMIZE_RELEASE}")
set(CMAKE_CXX_FLAGS_MINSIZEREL "")
set(CMAKE_CXX_FLAGS_RELEWITHDEBINFO "")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${TOOLCHAIN_OPTIMIZE_DEBUG}")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${TOOLCHAIN_OPTIMIZE_RELEASE}")
set(CMAKE_EXE_LINKER_MINSIZEREL "")
set(CMAKE_EXE_LINKER_RELEWITHDEBINFO "")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${TOOLCHAIN_OPTIMIZE_DEBUG}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${TOOLCHAIN_OPTIMIZE_RELEASE}")
set(CMAKE_SHARED_LINKER_MINSIZEREL "")
set(CMAKE_SHARED_LINKER_RELEWITHDEBINFO "")

set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "${TOOLCHAIN_OPTIMIZE_DEBUG}")
set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${TOOLCHAIN_OPTIMIZE_RELEASE}")
set(CMAKE_MODULE_LINKER_MINSIZEREL "")
set(CMAKE_MODULE_LINKER_RELEWITHDEBINFO "")

link_directories(${TARGET_LINKFLAGS})
link_libraries(${TARGET_LIBRARIES})