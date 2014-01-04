
if(APPLE)
    if(${CMAKE_VERSION} VERSION_GREATER "2.8.10.2" AND
       ${CMAKE_VERSION} VERSION_LESS "2.8.12.1")
        message(FATAL_ERROR "This version of CMake is known *not* to work, please update or use a lower version")
    endif()

    set(CMAKE_FIND_FRAMEWORK "FIRST")

    #what system are we building for
    set(minimum_macosx_version $ENV{MACOSX_DEPLOYMENT_TARGET})

    #detect on which system we are: if sw_vers cannot be found for any reason (re)use minimum_macosx_version
    find_program(sw_vers sw_vers)
    if(sw_vers)
        execute_process(COMMAND ${sw_vers} "-productVersion"
                        OUTPUT_VARIABLE current_macosx_version
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" current_macosx_version ${current_macosx_version})
    else()
        if(NOT minimum_macosx_version)
            message(FATAL_ERROR "sw_vers not found! Need explicit MACOSX_DEPLOYMENT_TARGET variable set")
        else()
            message("*** sw_vers not found! Fallback to MACOSX_DEPLOYMENT_TARGET variable ***")
            set(current_macosx_version ${minimum_macosx_version})
        endif()
    endif()

    #if nothing is set, we deploy only for the current system
    if(NOT minimum_macosx_version)
        set(minimum_macosx_version ${current_macosx_version})
    endif()

    #10.3 systems don't have enough processing power anyway
    #10.4 does not have @rpath support (which SDL uses)
    if(minimum_macosx_version VERSION_LESS "10.5")
        message(FATAL_ERROR "Hedgewars is not supported on your version of Mac OS X")
    endif()

    if(NOT CMAKE_OSX_ARCHITECTURES)
        if(current_macosx_version VERSION_LESS "10.6")
            #SDL is only 32 bit on older OS version
            if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "powerpc*")
                set(CMAKE_OSX_ARCHITECTURES "ppc7400")
            else()
                set(CMAKE_OSX_ARCHITECTURES "i386")
            endif()
        endif()
    endif()

    #parse this system variable and adjust only the powerpc syntax to be compatible with -P
    if(CMAKE_OSX_ARCHITECTURES)
        string(REGEX MATCH "[pP][pP][cC]+" powerpc_build "${CMAKE_OSX_ARCHITECTURES}")
        string(REGEX MATCH "[iI]386+" i386_build "${CMAKE_OSX_ARCHITECTURES}")
        string(REGEX MATCH "[xX]86_64+" x86_64_build "${CMAKE_OSX_ARCHITECTURES}")
        if(x86_64_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Px86_64)
        elseif(i386_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Pi386)
        elseif(powerpc_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Ppowerpc)
        else()
            message(FATAL_ERROR "Unknown architecture present in CMAKE_OSX_ARCHITECTURES (${CMAKE_OSX_ARCHITECTURES})")
        endif()
        list(LENGTH CMAKE_OSX_ARCHITECTURES num_of_archs)
        if(num_of_archs GREATER 1)
            message("*** Only one architecture in CMAKE_OSX_ARCHITECTURES is supported, picking the first one ***")
        endif()
    elseif(CMAKE_SIZEOF_VOID_P MATCHES "8")
        #if that variable is not set check if we are on x86_64 and if so force it, else use default
        add_flag_prepend(CMAKE_Pascal_FLAGS -Px86_64)
    endif()

    #CMAKE_OSX_SYSROOT is set at the system version we are supposed to build on
    #we need to provide the correct one when host and target differ
    if(NOT CMAKE_OSX_SYSROOT AND
       NOT ${minimum_macosx_version} VERSION_EQUAL ${current_macosx_version})
        find_program(xcrun xcrun)
        if(xcrun)
            execute_process(COMMAND ${xcrun} "--show-sdk-path"
                            OUTPUT_VARIABLE current_sdk_path
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            string(REPLACE "${current_macosx_version}"
                           "${minimum_macosx_version}"
                           CMAKE_OSX_SYSROOT
                           "${current_sdk_path}")
        else()
            message("*** xcrun not found! Build will work on ${current_macosx_version} only ***")
        endif()
    endif()
    if(CMAKE_OSX_SYSROOT)
        add_flag_append(CMAKE_Pascal_FLAGS "-XR${CMAKE_OSX_SYSROOT}")
        add_flag_append(CMAKE_Pascal_FLAGS "-k-macosx_version_min -k${minimum_macosx_version}")
        add_flag_append(CMAKE_Pascal_FLAGS "-k-L${LIBRARY_OUTPUT_PATH} -Fl${LIBRARY_OUTPUT_PATH}")
    endif()

    #add user framework directory
    add_flag_append(CMAKE_Pascal_FLAGS "-Ff~/Library/Frameworks")

    #workaround older cmake versions
    if(${CMAKE_VERSION} VERSION_LESS "2.8.12")
        add_flag_append(CMAKE_C_LINK_FLAGS "-Wl,-rpath -Wl,${CMAKE_INSTALL_RPATH}")
        add_flag_append(CMAKE_CXX_LINK_FLAGS "-Wl,-rpath -Wl,${CMAKE_INSTALL_RPATH}")
        add_flag_append(CMAKE_Pascal_LINK_FLAGS "-k-rpath -k${CMAKE_INSTALL_RPATH}")
    endif()
endif(APPLE)

if(MINGW)
    #this flags prevents a few dll hell problems
    add_flag_append(CMAKE_C_FLAGS "-static-libgcc")
    add_flag_append(CMAKE_CXX_FLAGS "-static-libgcc")
endif(MINGW)

if(WIN32)
    if(NOT ${BUILD_SHARED_LIB})
        message(FATAL_ERROR "Static linking is not supported on Windows")
    endif()
endif(WIN32)

if(UNIX)
    add_flag_append(CMAKE_C_FLAGS "-fPIC")
    add_flag_append(CMAKE_CXX_FLAGS "-fPIC")
endif(UNIX)
