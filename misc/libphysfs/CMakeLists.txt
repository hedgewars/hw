# PhysicsFS; a portable, flexible file i/o abstraction.
# Copyright (C) 2007  Ryan C. Gordon.
#
# Please see the file LICENSE.txt in the source's root directory.

## lines starting with '##' are lines overridden/modified/added by Hedgewars configuration
##CMAKE_MINIMUM_REQUIRED(VERSION 2.4)
##PROJECT(PhysicsFS)
set(PHYSFS_VERSION 2.1.0)

# Increment this if/when we break backwards compatibility.
set(PHYSFS_SOVERSION 1)

# I hate that they define "WIN32" ... we're about to move to Win64...I hope!
if(WIN32 AND NOT WINDOWS)
    set(WINDOWS TRUE)
endif(WIN32 AND NOT WINDOWS)

# Bleh, let's do it for "APPLE" too.
if(APPLE AND NOT MACOSX)
    set(MACOSX TRUE)
endif(APPLE AND NOT MACOSX)

# For now, Haiku and BeOS are the same, as far as the build system cares.
if(HAIKU AND NOT BEOS)
    set(BEOS TRUE)
endif(HAIKU AND NOT BEOS)

if(CMAKE_SYSTEM_NAME STREQUAL "SunOS")
    set(SOLARIS TRUE)
endif(CMAKE_SYSTEM_NAME STREQUAL "SunOS")

include(CheckIncludeFile)
include(CheckLibraryExists)
include(CheckCSourceCompiles)


if(MACOSX)
    # Fallback to older OS X on PowerPC to support wider range of systems...
    if(CMAKE_OSX_ARCHITECTURES MATCHES ppc)
        add_definitions(-DMAC_OS_X_VERSION_MIN_REQUIRED=1020)
        list(APPEND OTHER_LDFLAGS "-mmacosx-version-min=10.2")
    endif(CMAKE_OSX_ARCHITECTURES MATCHES ppc)

    # Need these everywhere...
    add_definitions(-fno-common)
    find_library(foundation_framework NAMES Foundation)
    list(APPEND OTHER_LDFLAGS ${foundation_framework})
    find_library(iokit_framework NAMES IOKit)
    list(APPEND OTHER_LDFLAGS ${iokit_framework})
endif(MACOSX)

# Add some gcc-specific command lines.
if(CMAKE_COMPILER_IS_GNUCC)
    # Always build with debug symbols... you can strip it later.
    add_definitions(-g -fsigned-char)
endif(CMAKE_COMPILER_IS_GNUCC)

if(CMAKE_C_COMPILER_ID STREQUAL "SunPro")
    add_definitions(-erroff=E_EMPTY_TRANSLATION_UNIT)
    add_definitions(-xldscope=hidden)
endif(CMAKE_C_COMPILER_ID STREQUAL "SunPro")

if(MSVC)
    # VS.NET 8.0 got really really anal about strcpy, etc, which even if we
    #  cleaned up our code, zlib, etc still use...so disable the warning.
    add_definitions(-D_CRT_SECURE_NO_WARNINGS=1)
endif(MSVC)


if(BEOS)
    # We add this explicitly, since we don't want CMake to think this
    #  is a C++ project unless we're on BeOS.
    set(PHYSFS_BEOS_SRCS src/platform_beos.cpp)
    find_library(BE_LIBRARY be)
    find_library(ROOT_LIBRARY root)
    set(optional_library_libs ${optional_library_libs} ${BE_LIBRARY} ${ROOT_LIBRARY})
endif(BEOS)


# Almost everything is "compiled" here, but things that don't apply to the
#  build are #ifdef'd out. This is to make it easy to embed PhysicsFS into
#  another project or bring up a new build system: just compile all the source
#  code and #define the things you want.
set(PHYSFS_SRCS
    physfs.c
    physfs_byteorder.c
    physfs_unicode.c
    platform_posix.c
    platform_unix.c
    platform_macosx.c
    platform_windows.c
    archiver_dir.c
    archiver_unpacked.c
    archiver_grp.c
    archiver_hog.c
    archiver_lzma.c
    archiver_mvl.c
    archiver_qpak.c
    archiver_wad.c
    archiver_zip.c
    archiver_iso9660.c
    ${PHYSFS_BEOS_SRCS}
)


# platform layers ...

if(UNIX)
    if(BEOS)
        set(PHYSFS_HAVE_CDROM_SUPPORT TRUE)
        set(PHYSFS_HAVE_THREAD_SUPPORT TRUE)
        set(HAVE_PTHREAD_H TRUE)
    else(BEOS)
        CHECK_INCLUDE_FILE(sys/ucred.h HAVE_UCRED_H)
        if(HAVE_UCRED_H)
            add_definitions(-DPHYSFS_HAVE_SYS_UCRED_H=1)
            set(PHYSFS_HAVE_CDROM_SUPPORT TRUE)
        endif(HAVE_UCRED_H)

        CHECK_INCLUDE_FILE(mntent.h HAVE_MNTENT_H)
        if(HAVE_MNTENT_H)
            add_definitions(-DPHYSFS_HAVE_MNTENT_H=1)
            set(PHYSFS_HAVE_CDROM_SUPPORT TRUE)
        endif(HAVE_MNTENT_H)

        # !!! FIXME: Solaris fails this, because mnttab.h implicitly
        # !!! FIXME:  depends on other system headers.  :(
        #CHECK_INCLUDE_FILE(sys/mnttab.h HAVE_SYS_MNTTAB_H)
        CHECK_C_SOURCE_COMPILES("
            #include <stdio.h>
            #include <sys/mnttab.h>
            int main(int argc, char **argv) { return 0; }
        " HAVE_SYS_MNTTAB_H)

        if(HAVE_SYS_MNTTAB_H)
            add_definitions(-DPHYSFS_HAVE_SYS_MNTTAB_H=1)
            set(PHYSFS_HAVE_CDROM_SUPPORT TRUE)
        endif(HAVE_SYS_MNTTAB_H)

        CHECK_INCLUDE_FILE(pthread.h HAVE_PTHREAD_H)
        if(HAVE_PTHREAD_H)
            set(PHYSFS_HAVE_THREAD_SUPPORT TRUE)
        endif(HAVE_PTHREAD_H)
    endif(BEOS)
endif(UNIX)

if(WINDOWS)
    set(PHYSFS_HAVE_CDROM_SUPPORT TRUE)
    set(PHYSFS_HAVE_THREAD_SUPPORT TRUE)
    list(APPEND OTHER_LDFLAGS ${SDL2_LIBRARY})
endif(WINDOWS)

if(NOT PHYSFS_HAVE_CDROM_SUPPORT)
    add_definitions(-DPHYSFS_NO_CDROM_SUPPORT=1)
    message(WARNING " ***")
    message(WARNING " *** There is no CD-ROM support in this build!")
    message(WARNING " *** PhysicsFS will just pretend there are no discs.")
    message(WARNING " *** This may be fine, depending on how PhysicsFS is used,")
    message(WARNING " ***   but is this what you REALLY wanted?")
    message(WARNING " *** (Maybe fix CMakeLists.txt, or write a platform driver?)")
    message(WARNING " ***")
endif(NOT PHYSFS_HAVE_CDROM_SUPPORT)

if(PHYSFS_HAVE_THREAD_SUPPORT)
    add_definitions(-D_REENTRANT -D_THREAD_SAFE)
else(PHYSFS_HAVE_THREAD_SUPPORT)
    add_definitions(-DPHYSFS_NO_THREAD_SUPPORT=1)
    message(WARNING " ***")
    message(WARNING " *** There is no thread support in this build!")
    message(WARNING " *** PhysicsFS will NOT be reentrant!")
    message(WARNING " *** This may be fine, depending on how PhysicsFS is used,")
    message(WARNING " ***   but is this what you REALLY wanted?")
    message(WARNING " *** (Maybe fix CMakeLists.txt, or write a platform driver?)")
    message(WARNING " ***")
endif(PHYSFS_HAVE_THREAD_SUPPORT)


# Archivers ...

option(PHYSFS_ARCHIVE_ZIP "Enable ZIP support" TRUE)
if(PHYSFS_ARCHIVE_ZIP)
    add_definitions(-DPHYSFS_SUPPORTS_ZIP=1)
    set(PHYSFS_FEATURES "ZIP")
endif(PHYSFS_ARCHIVE_ZIP)

#option(PHYSFS_ARCHIVE_GRP "Enable Build Engine GRP support" TRUE)
#if(PHYSFS_ARCHIVE_GRP)
#    add_definitions(-DPHYSFS_SUPPORTS_GRP=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} GRP")
#endif(PHYSFS_ARCHIVE_GRP)

#option(PHYSFS_ARCHIVE_WAD "Enable Doom WAD support" TRUE)
#if(PHYSFS_ARCHIVE_WAD)
#    add_definitions(-DPHYSFS_SUPPORTS_WAD=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} WAD")
#endif(PHYSFS_ARCHIVE_WAD)

#option(PHYSFS_ARCHIVE_HOG "Enable Descent I/II HOG support" TRUE)
#if(PHYSFS_ARCHIVE_HOG)
#    add_definitions(-DPHYSFS_SUPPORTS_HOG=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} HOG")
#endif(PHYSFS_ARCHIVE_HOG)

#option(PHYSFS_ARCHIVE_MVL "Enable Descent I/II MVL support" TRUE)
#if(PHYSFS_ARCHIVE_MVL)
#    add_definitions(-DPHYSFS_SUPPORTS_MVL=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} MVL")
#endif(PHYSFS_ARCHIVE_MVL)

#option(PHYSFS_ARCHIVE_QPAK "Enable Quake I/II QPAK support" TRUE)
#if(PHYSFS_ARCHIVE_QPAK)
#    add_definitions(-DPHYSFS_SUPPORTS_QPAK=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} QPAK")
#endif(PHYSFS_ARCHIVE_QPAK)

#option(PHYSFS_ARCHIVE_ISO9660 "Enable ISO9660 support" TRUE)
#if(PHYSFS_ARCHIVE_ISO9660)
#    add_definitions(-DPHYSFS_SUPPORTS_ISO9660=1)
#    set(PHYSFS_FEATURES "${PHYSFS_FEATURES} CD-ROM")
#endif(PHYSFS_ARCHIVE_ISO9660)


##Hedgewars modifications
add_library(physfs ${PHYSFS_SRCS})
set_target_properties(physfs PROPERTIES
                          VERSION ${PHYSFS_VERSION}
                          SOVERSION ${PHYSFS_SOVERSION}
                          OUTPUT_NAME ${physfs_output_name})
target_link_libraries(physfs ${optional_library_libs} ${OTHER_LDFLAGS})
install(TARGETS physfs RUNTIME DESTINATION ${target_binary_install_dir}
                       LIBRARY DESTINATION ${target_library_install_dir}
                       ARCHIVE DESTINATION ${target_library_install_dir})
get_target_property(physfs_fullpath physfs LOCATION)

## added standard variables emulating the FindPhysFS.cmake ones (FORCE or cmake won't pick 'em)
set(PHYSFS_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Physfs include dir" FORCE)
set(PHYSFS_LIBRARY ${physfs_fullpath} CACHE STRING "Physfs library path" FORCE)


## removed language bindings and test program
## simplified configuration output
## merged shared and static library building

#message(STATUS "PhysFS will be built with ${PHYSFS_FEATURES} support")

