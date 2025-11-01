
if(APPLE)
    #minimum for macOS.  sorry!
    cmake_minimum_required(VERSION 3.9.0)

    #set c++11 standard for QT requirements
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++")

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

    #minimum OSX version is 10.8.  Earlier versions cannot compile some dependencies anymore
    #(like ffmpeg/libav)
    if(minimum_macosx_version VERSION_LESS "10.8")
        message(FATAL_ERROR "Hedgewars is unsupported on your platform and requires Mac OS X 10.8+")
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
        add_flag_append(CMAKE_Pascal_FLAGS "-k-macos_version_min -k${minimum_macosx_version}")
        add_flag_append(CMAKE_Pascal_FLAGS "-k-L${LIBRARY_OUTPUT_PATH} -Fl${LIBRARY_OUTPUT_PATH}")
    endif()

    #add user framework directory
    add_flag_append(CMAKE_Pascal_FLAGS "-Ff~/Library/Frameworks")

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
