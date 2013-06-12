
if(APPLE)
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

#lower systems don't have enough processing power anyway
    if (minimum_macosx_version VERSION_LESS "10.4")
        message(FATAL_ERROR "Hedgewars is not supported on Mac OS X pre-10.4")
    endif()

#workaround for http://playcontrol.net/ewing/jibberjabber/big_behind-the-scenes_chang.html#SDL_mixer (Update 2)
    if(current_macosx_version VERSION_EQUAL "10.4")
        find_package(SDL_mixer REQUIRED)
        set(DYLIB_SMPEG "-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg")
        set(DYLIB_MIKMOD "-dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod")
        set(CMAKE_C_FLAGS "${DYLIB_SMPEG} ${DYLIB_MIKMOD}")
        list(APPEND pascal_flags "-k${DYLIB_SMPEG}" "-k${DYLIB_MIKMOD}")
    endif()

#CMAKE_OSX_ARCHITECTURES and CMAKE_OSX_SYSROOT need to be set for universal binary and correct linking
    if(NOT CMAKE_OSX_ARCHITECTURES)
        if(current_macosx_version VERSION_LESS "10.6")
            if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "powerpc*")
                set(CMAKE_OSX_ARCHITECTURES "ppc7400")
            else()
                set(CMAKE_OSX_ARCHITECTURES "i386")
            endif()
        else()
            set(CMAKE_OSX_ARCHITECTURES "x86_64")
        endif()
    endif()

#CMAKE_OSX_SYSROOT is set at the system version we are supposed to build on
#we need to provide the correct one when host and target differ
    if(NOT ${minimum_macosx_version} VERSION_EQUAL ${current_macosx_version})
        if(minimum_macosx_version VERSION_EQUAL "10.4")
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
            set(CMAKE_C_COMPILER "/Developer/usr/bin/gcc-4.0")
            set(CMAKE_CXX_COMPILER "/Developer/usr/bin/g++-4.0")
        else()
            string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" sdk_version ${minimum_macosx_version})
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX${sdk_version}.sdk/")
        endif()
    endif()

#add user framework directory, other paths can be passed via FPFLAGS
    list(APPEND pascal_flags "-Ff~/Library/Frameworks")
#set deployment target
    list(APPEND pascal_flags "-k-macosx_version_min" "-k${minimum_macosx_version}" "-XR${CMAKE_OSX_SYSROOT}")

endif(APPLE)

if(MINGW)
    #this flags prevents a few dll hell problems
    set(CMAKE_C_FLAGS "-static-libgcc ${CMAKE_C_FLAGS}")
endif(MINGW)

if(WIN32)
    if(NOT BUILD_SHARED_LIB)
        message(FATAL_ERROR "Static linking is not supported on Windows")
    endif()
endif(WIN32)
