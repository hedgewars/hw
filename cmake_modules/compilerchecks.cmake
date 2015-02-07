
#TESTING TIME
include(CheckCCompilerFlag)
#when you need to check for a linker flag, just leave the argument of "check_c_compiler_flag" empty

# CMAKE_C{XX}_FLAGS is for compiler flags (c and c++)
# CMAKE_EXE_LINKER_FLAGS is for linker flags (also add them to pascal_flags and haskell_flags)
# CMAKE_SHARED_LIBRARY_<lang>_FLAGS same but for shared libraries

#TODO: should there be two different checks for C and CXX?
#TODO: can the various if(platform) be avoided in some way?


if(NOT (WIN32 OR (CMAKE_SYSTEM_NAME MATCHES BSD.OS) OR (CMAKE_SYSTEM_NAME MATCHES FreeBSD)))
    #stack protection, when found it needs to go in the linker flags too
    #it is disabled on win32 because it adds a dll and messes with linker
    #some bsd installations reported problems too
    #(see 822312 654424 on bugzilla.redhat.com)
    check_c_compiler_flag("-fstack-protector-all -fstack-protector" HAVE_STACKPROTECTOR)
    if(HAVE_STACKPROTECTOR)
        add_flag_append(CMAKE_C_FLAGS "-fstack-protector-all -fstack-protector")
        add_flag_append(CMAKE_CXX_FLAGS "-fstack-protector-all -fstack-protector")
    endif()
endif()



if(UNIX)
    #symbol visibility
    check_c_compiler_flag("-fvisibility=hidden" HAVE_VISIBILITY)
    if(HAVE_VISIBILITY)
        add_flag_append(CMAKE_C_FLAGS "-fvisibility=hidden")
        add_flag_append(CMAKE_CXX_FLAGS "-fvisibility=hidden")
    endif()

    #check for noexecstack on ELF, Gentoo security
    set(CMAKE_REQUIRED_FLAGS "-Wl,-znoexecstack")
    check_c_compiler_flag("" HAVE_NOEXECSTACK)
    if(HAVE_NOEXECSTACK)
        add_linker_flag("-znoexecstack")
    endif()

    #check for origin on ELF, BSD $ORIGIN support
    set(CMAKE_REQUIRED_FLAGS "-Wl,-zorigin")
    check_c_compiler_flag("" HAVE_ORIGIN)
    if(HAVE_ORIGIN)
        add_linker_flag("-zorigin")
    endif()

    #check for full relro on ELF, Debian security
    set(CMAKE_REQUIRED_FLAGS "-Wl,-zrelro,-znow")
    check_c_compiler_flag("" HAVE_RELROFULL)
    if(HAVE_RELROFULL)
        add_linker_flag("-zrelro")
        add_linker_flag("-znow")
    else()
        #if full relro is not available, try partial relro
        set(CMAKE_REQUIRED_FLAGS "-Wl,-zrelro")
        check_c_compiler_flag("" HAVE_RELROPARTIAL)
        if(HAVE_RELROPARTIAL)
            add_linker_flag("-zrelro")
        endif()
    endif()

    if(CMAKE_BUILD_TYPE MATCHES "RELEASE" OR CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO")
        set(CMAKE_REQUIRED_FLAGS "-Wl,--as-needed")
        check_c_compiler_flag("" HAVE_ASNEEDED)
        if(HAVE_ASNEEDED)
            add_linker_flag("--as-needed")
        endif()
    endif()
else(UNIX)
    #check for ASLR on Windows Vista or later, requires binutils >= 2.20
    set(CMAKE_REQUIRED_FLAGS "-Wl,--nxcompat")
    check_c_compiler_flag("" HAVE_WINASLR)
    if(HAVE_WINASLR)
        add_linker_flag("--nxcompat")
    endif()

    #check for DEP on Windows XP SP2 or later, requires binutils >= 2.20
    set(CMAKE_REQUIRED_FLAGS "-Wl,--dynamicbase")
    check_c_compiler_flag("" HAVE_WINDEP)
    if(HAVE_WINDEP)
        add_linker_flag("--dynamicbase")
    endif()
endif(UNIX)


#always unset or these flags will be spread everywhere
unset(CMAKE_REQUIRED_FLAGS)

