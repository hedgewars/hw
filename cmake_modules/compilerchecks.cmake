
#TESTING TIME
include(CheckCCompilerFlag)
#when you need to check for a linker flag, just leave the argument of "check_c_compiler_flag" empty


#check for noexecstack on ELF, Gentoo security
set(CMAKE_REQUIRED_FLAGS "-Wl,-z,noexecstack")
check_c_compiler_flag("" HAVE_NOEXECSTACK)
if(HAVE_NOEXECSTACK)
    list(APPEND pascal_flags "-k-z" "-knoexecstack")
    list(APPEND haskell_flags "-optl" "-z" "-optl" "noexecstack")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()

#check for full relro on ELF, Debian security
set(CMAKE_REQUIRED_FLAGS "-Wl,-z,relro,-z,now")
check_c_compiler_flag("" HAVE_RELROFULL)
if(HAVE_RELROFULL)
    list(APPEND pascal_flags "-k-z" "-krelro" "-k-z" "-know")
    list(APPEND haskell_flags "-optl" "-z" "-optl" "relro" "-optl" "-z" "-optl" "now")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
else()
    #if full relro is not available, try partial relro
    set(CMAKE_REQUIRED_FLAGS "-Wl,-z,relro")
    check_c_compiler_flag("" HAVE_RELROPARTIAL)
    if(HAVE_RELROPARTIAL)
        list(APPEND pascal_flags "-k-z" "-krelro")
        list(APPEND haskell_flags "-optl" "-z" "-optl" "relro")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
    endif()
endif()

#check for ASLR on Windows Vista or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--nxcompat")
check_c_compiler_flag("" HAVE_WINASLR)
if(HAVE_WINASLR)
    list(APPEND pascal_flags "-k--nxcompat")
    list(APPEND haskell_flags "-optl" "--nxcompat")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()

#check for DEP on Windows XP SP2 or later, requires binutils >= 2.20
set(CMAKE_REQUIRED_FLAGS "-Wl,--dynamicbase")
check_c_compiler_flag("" HAVE_WINDEP)
if(HAVE_WINDEP)
    list(APPEND pascal_flags "-k--dynamicbase")
    list(APPEND haskell_flags "-optl" "--dynamicbase")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS}")
endif()


#always unset or these flags will be spread everywhere
unset(CMAKE_REQUIRED_FLAGS)

