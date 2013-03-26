# This file sets the basic flags for the Pascal language in CMake.
# It also loads the available platform file for the system-compiler
# if it exists.

get_filename_component(CMAKE_BASE_NAME ${CMAKE_Pascal_COMPILER} NAME_WE)
set(CMAKE_SYSTEM_AND_Pascal_COMPILER_INFO_FILE
    ${CMAKE_ROOT}/Modules/Platform/${CMAKE_SYSTEM_NAME}-${CMAKE_BASE_NAME}.cmake)
include(Platform/${CMAKE_SYSTEM_NAME}-${CMAKE_BASE_NAME} OPTIONAL)

# This section should actually be in Platform/${CMAKE_SYSTME_NAME}-fpc.cmake
set(CMAKE_Pascal_FLAGS_INIT "-l- -v0ewn")
set(CMAKE_Pascal_FLAGS_DEBUG_INIT "-g -gl -gp -gh")
set(CMAKE_Pascal_FLAGS_MINSIZEREL_INIT "-Os -dNDEBUG")
set(CMAKE_Pascal_FLAGS_RELEASE_INIT "-O3 -dNDEBUG")
set(CMAKE_Pascal_FLAGS_RELWITHDEBINFO_INIT "-O2 -g -gl -gp")

# This should be included before the _INIT variables are
# used to initialize the cache. Since the rule variables
# have if blocks on them, users can still define them here.
# But, it should still be after the platform file so changes can
# be made to those values.

if(CMAKE_USER_MAKE_RULES_OVERRIDE)
   include(${CMAKE_USER_MAKE_RULES_OVERRIDE})
endif(CMAKE_USER_MAKE_RULES_OVERRIDE)

if(CMAKE_USER_MAKE_RULES_OVERRIDE_Pascal)
   include(${CMAKE_USER_MAKE_RULES_OVERRIDE_Pascal})
endif(CMAKE_USER_MAKE_RULES_OVERRIDE_Pascal)

# Create a set of shared library variable specific to Pascal
# For 90% of the systems, these are the same flags as the C versions
# so if these are not set just copy the flags from the c version

# No flags supported during linking as a shell script takes care of it
IF(NOT CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS)
#-dynamiclib -Wl,-headerpad_max_install_names for C
  SET(CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS ${CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS})
ENDIF(NOT CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS)

if(NOT CMAKE_SHARED_LIBRARY_Pascal_FLAGS)
    #another similarity, fpc: -fPIC  Same as -Cg
    #(maybe required only for x86_64)
    set(CMAKE_SHARED_LIBRARY_Pascal_FLAGS ${CMAKE_SHARED_LIBRARY_C_FLAGS})
endif(NOT CMAKE_SHARED_LIBRARY_Pascal_FLAGS)

if(NOT CMAKE_SHARED_LIBRARY_LINK_Pascal_FLAGS)
    set(CMAKE_SHARED_LIBRARY_LINK_Pascal_FLAGS ${CMAKE_SHARED_LIBRARY_LINK_C_FLAGS})
endif(NOT CMAKE_SHARED_LIBRARY_LINK_Pascal_FLAGS)

#IF(NOT CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG)
#  SET(CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG ${CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG})
#ENDIF(NOT CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG)

#IF(NOT CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG_SEP)
#  SET(CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG_SEP ${CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG_SEP})
#ENDIF(NOT CMAKE_SHARED_LIBRARY_RUNTIME_Pascal_FLAG_SEP)

if(NOT CMAKE_SHARED_LIBRARY_RPATH_LINK_Pascal_FLAG)
    set(CMAKE_SHARED_LIBRARY_RPATH_LINK_Pascal_FLAG ${CMAKE_SHARED_LIBRARY_RPATH_LINK_C_FLAG})
endif(NOT CMAKE_SHARED_LIBRARY_RPATH_LINK_Pascal_FLAG)

# for most systems a module is the same as a shared library
# so unless the variable CMAKE_MODULE_EXISTS is set just
# copy the values from the LIBRARY variables
if(NOT CMAKE_MODULE_EXISTS)
    set(CMAKE_SHARED_MODULE_Pascal_FLAGS ${CMAKE_SHARED_LIBRARY_Pascal_FLAGS})
    set(CMAKE_SHARED_MODULE_CREATE_Pascal_FLAGS ${CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS})
endif(NOT CMAKE_MODULE_EXISTS)

# repeat for modules
IF(NOT CMAKE_SHARED_MODULE_CREATE_Pascal_FLAGS)
  SET(CMAKE_SHARED_MODULE_CREATE_Pascal_FLAGS ${CMAKE_SHARED_MODULE_CREATE_C_FLAGS})
ENDIF(NOT CMAKE_SHARED_MODULE_CREATE_Pascal_FLAGS)

IF(NOT CMAKE_SHARED_MODULE_Pascal_FLAGS)
  SET(CMAKE_SHARED_MODULE_Pascal_FLAGS ${CMAKE_SHARED_MODULE_C_FLAGS})
ENDIF(NOT CMAKE_SHARED_MODULE_Pascal_FLAGS)

IF(NOT CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG)
  SET(CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG ${CMAKE_SHARED_MODULE_RUNTIME_C_FLAG})
ENDIF(NOT CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG)

IF(NOT CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG_SEP)
  SET(CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG_SEP ${CMAKE_SHARED_MODULE_RUNTIME_C_FLAG_SEP})
ENDIF(NOT CMAKE_SHARED_MODULE_RUNTIME_Pascal_FLAG_SEP)

if(NOT CMAKE_INCLUDE_FLAG_Pascal)
    #amazing, fpc: -I<x>  Add <x> to include path
    set(CMAKE_INCLUDE_FLAG_Pascal ${CMAKE_INCLUDE_FLAG_C})
endif(NOT CMAKE_INCLUDE_FLAG_Pascal)

if(NOT CMAKE_INCLUDE_FLAG_SEP_Pascal)
    set(CMAKE_INCLUDE_FLAG_SEP_Pascal ${CMAKE_INCLUDE_FLAG_SEP_C})
endif(NOT CMAKE_INCLUDE_FLAG_SEP_Pascal)

# Copy C version of this flag which is normally determined in platform file.
if(NOT CMAKE_SHARED_LIBRARY_SONAME_Pascal_FLAG)
  set(CMAKE_SHARED_LIBRARY_SONAME_Pascal_FLAG ${CMAKE_SHARED_LIBRARY_SONAME_C_FLAG})
endif(NOT CMAKE_SHARED_LIBRARY_SONAME_Pascal_FLAG)

set(CMAKE_VERBOSE_MAKEFILE FALSE CACHE BOOL "If this value is on, makefiles will be generated without the .SILENT directive, and all commands will be echoed to the console during the make.  This is useful for debugging only. With Visual Studio IDE projects all commands are done without /nologo.")

set(CMAKE_Pascal_FLAGS "$ENV{FPFLAGS} ${CMAKE_Pascal_FLAGS_INIT}" CACHE STRING "Flags for Pascal compiler.")

INCLUDE(CMakeCommonLanguageInclude)

# now define the following rule variables

# CMAKE_Pascal_CREATE_SHARED_LIBRARY
# CMAKE_Pascal_CREATE_SHARED_MODULE
# CMAKE_Pascal_CREATE_STATIC_LIBRARY
# CMAKE_Pascal_COMPILE_OBJECT
# CMAKE_Pascal_LINK_EXECUTABLE

# variables supplied by the generator at use time
# <TARGET>
# <TARGET_BASE> the target without the suffix
# <OBJECTS>
# <OBJECT>
# <LINK_LIBRARIES>
# <FLAGS>
# <LINK_FLAGS>

# Pascal compiler information
# <CMAKE_Pascal_COMPILER>
# <CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS>
# <CMAKE_SHARED_MODULE_CREATE_Pascal_FLAGS>
# <CMAKE_Pascal_LINK_FLAGS>

# Static library tools
#  NONE!

if(NOT EXECUTABLE_OUTPUT_PATH)
    set (EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
endif(NOT EXECUTABLE_OUTPUT_PATH)

# create a Pascal shared library
if(NOT CMAKE_Pascal_CREATE_SHARED_LIBRARY)
    if(WIN32)
        set(CMAKE_Pascal_CREATE_SHARED_LIBRARY "${EXECUTABLE_OUTPUT_PATH}/ppas.bat")
    else(WIN32)
        set(CMAKE_Pascal_CREATE_SHARED_LIBRARY "${EXECUTABLE_OUTPUT_PATH}/ppas.sh")
    endif(WIN32)
# other expandable variables here are <CMAKE_Pascal_COMPILER> <CMAKE_SHARED_LIBRARY_Pascal_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_Pascal_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_Pascal_FLAG> <TARGET_SONAME> <TARGET> <OBJECTS> <LINK_LIBRARIES>
endif(NOT CMAKE_Pascal_CREATE_SHARED_LIBRARY)

# create an Pascal shared module just copy the shared library rule
IF(NOT CMAKE_Pascal_CREATE_SHARED_MODULE)
  SET(CMAKE_Pascal_CREATE_SHARED_MODULE ${CMAKE_Pascal_CREATE_SHARED_LIBRARY})
ENDIF(NOT CMAKE_Pascal_CREATE_SHARED_MODULE)

# create an Pascal static library (unsupported)
IF(NOT CMAKE_Pascal_CREATE_STATIC_LIBRARY)
  SET(CMAKE_Pascal_CREATE_STATIC_LIBRARY
      "echo STATIC LIBRARIES ARE NOT SUPPORTED" "exit")
ENDIF(NOT CMAKE_Pascal_CREATE_STATIC_LIBRARY)

# compile a Pascal file into an object file
if(NOT CMAKE_Pascal_COMPILE_OBJECT)
    if(UNIX)
        #when you have multiple ld installation make sure you get the one bundled with the system C compiler
        include(Platform/${CMAKE_SYSTEM_NAME}-GNU-C.cmake OPTIONAL)
        if(CMAKE_C_COMPILER)
            get_filename_component(CMAKE_C_COMPILER_DIR ${CMAKE_C_COMPILER} PATH)
            set(CMAKE_Pascal_UNIX_FLAGS "-FD${CMAKE_C_COMPILER_DIR}")
        endif(CMAKE_C_COMPILER)
        if(APPLE)
            #add user framework directory
            set(CMAKE_Pascal_UNIX_FLAGS "-Ff~/Library/Frameworks ${CMAKE_Pascal_UNIX_FLAGS}")
            #when sysroot is set, make sure that fpc picks it
            if(CMAKE_OSX_SYSROOT)
                set(CMAKE_Pascal_UNIX_FLAGS "-XD${CMAKE_OSX_SYSROOT} ${CMAKE_Pascal_UNIX_FLAGS}")
            endif(CMAKE_OSX_SYSROOT)
        endif(APPLE)
    endif(UNIX)

    set(CMAKE_Pascal_COMPILE_OBJECT
        "<CMAKE_Pascal_COMPILER> -Cn -FE${EXECUTABLE_OUTPUT_PATH} -FU${CMAKE_CURRENT_BINARY_DIR}/<OBJECT_DIR> ${CMAKE_Pascal_UNIX_FLAGS} <FLAGS> <SOURCE>")
endif(NOT CMAKE_Pascal_COMPILE_OBJECT)

# link Pascal objects in a single executable
if(NOT CMAKE_Pascal_LINK_EXECUTABLE)
    if(WIN32)
        set(CMAKE_Pascal_LINK_EXECUTABLE "${EXECUTABLE_OUTPUT_PATH}/ppas.bat")
    else(WIN32)
        set(CMAKE_Pascal_LINK_EXECUTABLE "${EXECUTABLE_OUTPUT_PATH}/ppas.sh")
    endif(WIN32)
# other expandable variables here are <CMAKE_Pascal_LINK_FLAGS> <LINK_FLAGS> <TARGET_BASE> <FLAGS> <LINK_LIBRARIES>
endif(NOT CMAKE_Pascal_LINK_EXECUTABLE)

if(CMAKE_Pascal_STANDARD_LIBRARIES_INIT)
    set(CMAKE_Pascal_STANDARD_LIBRARIES "${CMAKE_Pascal_STANDARD_LIBRARIES_INIT}"
    CACHE STRING "Libraries linked by default (usually handled internally).")
    MARK_AS_ADVANCED(CMAKE_Pascal_STANDARD_LIBRARIES)
endif(CMAKE_Pascal_STANDARD_LIBRARIES_INIT)

if(NOT CMAKE_NOT_USING_CONFIG_FLAGS)
  SET (CMAKE_Pascal_FLAGS_DEBUG "${CMAKE_Pascal_FLAGS_DEBUG_INIT}" CACHE STRING
     "Flags used by the compiler during debug builds.")
  SET (CMAKE_Pascal_FLAGS_MINSIZEREL "${CMAKE_Pascal_FLAGS_MINSIZEREL_INIT}" CACHE STRING
     "Flags used by the compiler during release minsize builds.")
  SET (CMAKE_Pascal_FLAGS_RELEASE "${CMAKE_Pascal_FLAGS_RELEASE_INIT}" CACHE STRING
     "Flags used by the compiler during release builds (/MD /Ob1 /Oi /Ot /Oy /Gs will produce slightly less optimized but smaller files).")
  SET (CMAKE_Pascal_FLAGS_RELWITHDEBINFO "${CMAKE_Pascal_FLAGS_RELWITHDEBINFO_INIT}" CACHE STRING
     "Flags used by the compiler during Release with Debug Info builds.")
endif(NOT CMAKE_NOT_USING_CONFIG_FLAGS)

mark_as_advanced(CMAKE_Pascal_FLAGS CMAKE_Pascal_FLAGS_DEBUG CMAKE_Pascal_FLAGS_MINSIZEREL
                 CMAKE_Pascal_FLAGS_RELEASE CMAKE_Pascal_FLAGS_RELWITHDEBINFO)
set(CMAKE_Pascal_INFORMATION_LOADED 1)

