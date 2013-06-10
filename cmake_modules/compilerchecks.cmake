
#TESTING TIME
include(CheckCCompilerFlag)
#when you need to check for a linker flag, just leave the argument of "check_c_compiler_flag" empty

# CMAKE_C{XX}_FLAGS is for compiler flags (c and c++)
# CMAKE_EXE_LINKER_FLAGS is for linker flags (also add them to pascal_flags and haskell_flags)
# CMAKE_SHARED_LIBRARY_<lang>_FLAGS same but for shared libraries

#TODO: should there be two different checks for C and CXX?

#stack protection, when found it needs to go in the linker flags too (-lssp is added)
check_c_compiler_flag("-fstack-protector-all -fstack-protector" HAVE_STACKPROTECTOR)
if(HAVE_STACKPROTECTOR)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_SHARED_LIBRARY_C_FLAGS  "${CMAKE_SHARED_LIBRARY_C_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_SHARED_LIBRARY_CXX_FLAGS  "${CMAKE_SHARED_LIBRARY_C_FLAGS} -fstack-protector-all -fstack-protector")
endif()

#symbol visibility, not supported on Windows (so we error out to avoid spam)
check_c_compiler_flag("-fvisibility=hidden -Werror" HAVE_VISIBILITY)
if(HAVE_VISIBILITY)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden")
endif()


#check for noexecstack on ELF, Gentoo security
set(CMAKE_REQUIRED_FLAGS "-Wl,-z,noexecstack")
check_c_compiler_flag("" HAVE_NOEXECSTACK)
if(HAVE_NOEXECSTACK)
    list(APPEND pascal_flags "-k-z" "-knoexecstack")
    list(APPEND haskell_flags "-optl" "-z" "-optl" "noexecstack")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()

#check for full relro on ELF, Debian security
set(CMAKE_REQUIRED_FLAGS "-Wl,-z,relro,-z,now")
check_c_compiler_flag("" HAVE_RELROFULL)
if(HAVE_RELROFULL)
    list(APPEND pascal_flags "-k-z" "-krelro" "-k-z" "-know")
    list(APPEND haskell_flags "-optl" "-z" "-optl" "relro" "-optl" "-z" "-optl" "now")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
else()
    #if full relro is not available, try partial relro
    set(CMAKE_REQUIRED_FLAGS "-Wl,-z,relro")
    check_c_compiler_flag("" HAVE_RELROPARTIAL)
    if(HAVE_RELROPARTIAL)
        list(APPEND pascal_flags "-k-z" "-krelro")
        list(APPEND haskell_flags "-optl" "-z" "-optl" "relro")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
    endif()
endif()

#check for ASLR on Windows Vista or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--nxcompat")
check_c_compiler_flag("" HAVE_WINASLR)
if(HAVE_WINASLR)
    list(APPEND pascal_flags "-k--nxcompat")
    list(APPEND haskell_flags "-optl" "--nxcompat")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()

#check for DEP on Windows XP SP2 or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--dynamicbase")
check_c_compiler_flag("" HAVE_WINDEP)
if(HAVE_WINDEP)
    list(APPEND pascal_flags "-k--dynamicbase")
    list(APPEND haskell_flags "-optl" "--dynamicbase")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()


#always unset or these flags will be spread everywhere
unset(CMAKE_REQUIRED_FLAGS)

