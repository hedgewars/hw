
#TESTING TIME
include(CheckCCompilerFlag)
#when you need to check for a linker flag, just leave the argument of "check_c_compiler_flag" empty

# CMAKE_C{XX}_FLAGS is for compiler flags (c and c++)
# CMAKE_EXE_LINKER_FLAGS is for linker flags (also add them to pascal_flags and haskell_flags)
# CMAKE_SHARED_LIBRARY_<lang>_FLAGS same but for shared libraries

#TODO: should there be two different checks for C and CXX?

#stack protection, when found it needs to go in the linker flags too
#it is disabled on win32 because it adds a dll and messes with linker
#(see 822312 654424 on bugzilla.redhat.com)
if(NOT WIN32)
    check_c_compiler_flag("-fstack-protector-all -fstack-protector" HAVE_STACKPROTECTOR)
endif()
if(HAVE_STACKPROTECTOR)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_SHARED_LIBRARY_C_FLAGS "${CMAKE_SHARED_LIBRARY_C_FLAGS} -fstack-protector-all -fstack-protector")
    set(CMAKE_SHARED_LIBRARY_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_CXX_FLAGS} -fstack-protector-all -fstack-protector")
endif()

#symbol visibility, not supported on Windows
if(NOT WIN32)
    check_c_compiler_flag("-fvisibility=hidden" HAVE_VISIBILITY)
endif()
if(HAVE_VISIBILITY)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden")
endif()


#check for noexecstack on ELF, Gentoo security
set(CMAKE_REQUIRED_FLAGS "-Wl,-z,noexecstack")
check_c_compiler_flag("" HAVE_NOEXECSTACK)
if(HAVE_NOEXECSTACK)
    append_linker_flag("-znoexecstack")
endif()

#check for full relro on ELF, Debian security
set(CMAKE_REQUIRED_FLAGS "-Wl,-zrelro,-znow")
check_c_compiler_flag("" HAVE_RELROFULL)
if(HAVE_RELROFULL)
    append_linker_flag("-zrelro")
    append_linker_flag("-znow")
else()
    #if full relro is not available, try partial relro
    set(CMAKE_REQUIRED_FLAGS "-Wl,-zrelro")
    check_c_compiler_flag("" HAVE_RELROPARTIAL)
    if(HAVE_RELROPARTIAL)
        append_linker_flag("-zrelro")
    endif()
endif()

#check for ASLR on Windows Vista or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--nxcompat")
check_c_compiler_flag("" HAVE_WINASLR)
if(HAVE_WINASLR)
    append_linker_flag("--nxcompat")
endif()

#check for DEP on Windows XP SP2 or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--dynamicbase")
check_c_compiler_flag("" HAVE_WINDEP)
if(HAVE_WINDEP)
    append_linker_flag("--dynamicbase")
endif()

#this is actually an optimisation
set(CMAKE_REQUIRED_FLAGS "-Wl,--as-needed")
check_c_compiler_flag("" HAVE_ASNEEDED)
if(HAVE_ASNEEDED)
    append_linker_flag("--as-needed")
endif()

#always unset or these flags will be spread everywhere
unset(CMAKE_REQUIRED_FLAGS)

