# PhysicsFS; a portable, flexible file i/o abstraction.
# Copyright (C) 2007  Ryan C. Gordon.
#
# Please see the file LICENSE.txt in the source's root directory.

#lines overridden by Hedgewars configuration
#CMAKE_MINIMUM_REQUIRED(VERSION 2.4)
#PROJECT(PhysicsFS)
set(PHYSFS_VERSION 2.1.0)

# Increment this if/when we break backwards compatibility.
set(PHYSFS_SOVERSION 1)

# I hate that they define "WIN32" ... we're about to move to Win64...I hope!
if(WIN32 AND NOT WINDOWS)
    set(WINDOWS true)
endif(WIN32 AND NOT WINDOWS)

# Bleh, let's do it for "APPLE" too.
if(APPLE AND NOT MACOSX)
    set(MACOSX true)
endif(APPLE AND NOT MACOSX)

# For now, Haiku and BeOS are the same, as far as the build system cares.
if(HAIKU AND NOT BEOS)
    set(BEOS true)
endif(HAIKU AND NOT BEOS)

if(CMAKE_SYSTEM_NAME STREQUAL "SunOS")
    set(SOLARIS true)
endif(CMAKE_SYSTEM_NAME STREQUAL "SunOS")

include(CheckIncludeFile)
include(CheckLibraryExists)
include(CheckCSourceCompiles)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${SDL_INCLUDE_DIR}) #hw
include_directories(${LUA_INCLUDE_DIR}) #hw

if(MACOSX)
    # Fallback to older OS X on PowerPC to support wider range of systems...
    if(CMAKE_OSX_ARCHITECTURES MATCHES ppc)
        add_definitions(-DMAC_OS_X_VERSION_MIN_REQUIRED=1020)
        set(OTHER_LDFLAGS ${OTHER_LDFLAGS} " -mmacosx-version-min=10.2")
    endif(CMAKE_OSX_ARCHITECTURES MATCHES ppc)

    # Need these everywhere...
    add_definitions(-fno-common)
    set(OTHER_LDFLAGS ${OTHER_LDFLAGS} "-framework IOKit")
endif(MACOSX)

# Add some gcc-specific command lines.
if(CMAKE_COMPILER_IS_GNUCC)
    # Always build with debug symbols...you can strip it later.
    add_definitions(-g -pipe -Werror -fsigned-char)

    # Stupid BeOS generates warnings in the system headers.
    if(NOT BEOS)
        add_definitions(-Wall)
    endif(NOT BEOS)

    CHECK_C_SOURCE_COMPILES("
        #if ((defined(__GNUC__)) && (__GNUC__ >= 4))
        int main(int argc, char **argv) { int is_gcc4 = 1; return 0; }
        #else
        #error This is not gcc4.
        #endif
    " PHYSFS_IS_GCC4)

    if(PHYSFS_IS_GCC4)
        # Not supported on several operating systems at this time.
        if(NOT SOLARIS AND NOT WINDOWS)
            add_definitions(-fvisibility=hidden)
        endif(NOT SOLARIS AND NOT WINDOWS)
    endif(PHYSFS_IS_GCC4)

    # Don't use -rpath.
    set(CMAKE_SKIP_RPATH ON CACHE BOOL "Skip RPATH" FORCE)
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

# Basic chunks of source code ...

set(LZMA_SRCS
    src/lzma/C/7zCrc.c
    src/lzma/C/Archive/7z/7zBuffer.c
    src/lzma/C/Archive/7z/7zDecode.c
    src/lzma/C/Archive/7z/7zExtract.c
    src/lzma/C/Archive/7z/7zHeader.c
    src/lzma/C/Archive/7z/7zIn.c
    src/lzma/C/Archive/7z/7zItem.c
    src/lzma/C/Archive/7z/7zMethodID.c
    src/lzma/C/Compress/Branch/BranchX86.c
    src/lzma/C/Compress/Branch/BranchX86_2.c
    src/lzma/C/Compress/Lzma/LzmaDecode.c
)

if(BEOS)
    # We add this explicitly, since we don't want CMake to think this
    #  is a C++ project unless we're on BeOS.
    set(PHYSFS_BEOS_SRCS src/platform_beos.cpp)
    find_library(BE_LIBRARY be)
    find_library(ROOT_LIBRARY root)
    set(OPTIONAL_LIBRARY_LIBS ${OPTIONAL_LIBRARY_LIBS} ${BE_LIBRARY} ${ROOT_LIBRARY})
endif(BEOS)

# Almost everything is "compiled" here, but things that don't apply to the
#  build are #ifdef'd out. This is to make it easy to embed PhysicsFS into
#  another project or bring up a new build system: just compile all the source
#  code and #define the things you want.
set(PHYSFS_SRCS
    src/physfs.c
    src/physfs_byteorder.c
    src/physfs_unicode.c
    src/platform_posix.c
    src/platform_unix.c
    src/platform_macosx.c
    src/platform_windows.c
    src/archiver_dir.c
    src/archiver_unpacked.c
    src/archiver_grp.c
    src/archiver_hog.c
    src/archiver_lzma.c
    src/archiver_mvl.c
    src/archiver_qpak.c
    src/archiver_wad.c
    src/archiver_zip.c
    src/archiver_iso9660.c
    #custom files from Hedgewars
    extras/physfsrwops.c
    extras/physfslualoader.c
    extras/hwpacksmounter.c
    ${PHYSFS_BEOS_SRCS}
)


# platform layers ...

if(UNIX)
    if(BEOS)
        set(PHYSFS_HAVE_CDROM_SUPPORT true)
        set(PHYSFS_HAVE_THREAD_SUPPORT true)
        set(HAVE_PTHREAD_H true)
    else(BEOS)
        CHECK_INCLUDE_FILE(sys/ucred.h HAVE_UCRED_H)
        if(HAVE_UCRED_H)
            add_definitions(-DPHYSFS_HAVE_SYS_UCRED_H=1)
            set(PHYSFS_HAVE_CDROM_SUPPORT false)
        endif(HAVE_UCRED_H)

        CHECK_INCLUDE_FILE(mntent.h HAVE_MNTENT_H)
        if(HAVE_MNTENT_H)
            add_definitions(-DPHYSFS_HAVE_MNTENT_H=1)
            set(PHYSFS_HAVE_CDROM_SUPPORT false)
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
            set(PHYSFS_HAVE_CDROM_SUPPORT false)
        endif(HAVE_SYS_MNTTAB_H)

        CHECK_INCLUDE_FILE(pthread.h HAVE_PTHREAD_H)
        if(HAVE_PTHREAD_H)
            set(PHYSFS_HAVE_THREAD_SUPPORT false)
        endif(HAVE_PTHREAD_H)
    endif(BEOS)
endif(UNIX)

if(WINDOWS)
    set(PHYSFS_HAVE_CDROM_SUPPORT true)
    set(PHYSFS_HAVE_THREAD_SUPPORT true)
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

option(PHYSFS_ARCHIVE_ZIP "Enable ZIP support" true)
if(PHYSFS_ARCHIVE_ZIP)
    add_definitions(-DPHYSFS_SUPPORTS_ZIP=1)
endif(PHYSFS_ARCHIVE_ZIP)

option(PHYSFS_ARCHIVE_7Z "Enable 7zip support" false)
if(PHYSFS_ARCHIVE_7Z)
    add_definitions(-DPHYSFS_SUPPORTS_7Z=1)
    # !!! FIXME: rename to 7z.c?
    set(PHYSFS_SRCS ${PHYSFS_SRCS} ${LZMA_SRCS})
endif(PHYSFS_ARCHIVE_7Z)

option(PHYSFS_ARCHIVE_GRP "Enable Build Engine GRP support" true)
if(PHYSFS_ARCHIVE_GRP)
    add_definitions(-DPHYSFS_SUPPORTS_GRP=1)
endif(PHYSFS_ARCHIVE_GRP)

option(PHYSFS_ARCHIVE_WAD "Enable Doom WAD support" true)
if(PHYSFS_ARCHIVE_WAD)
    add_definitions(-DPHYSFS_SUPPORTS_WAD=1)
endif(PHYSFS_ARCHIVE_WAD)

option(PHYSFS_ARCHIVE_HOG "Enable Descent I/II HOG support" true)
if(PHYSFS_ARCHIVE_HOG)
    add_definitions(-DPHYSFS_SUPPORTS_HOG=1)
endif(PHYSFS_ARCHIVE_HOG)

option(PHYSFS_ARCHIVE_MVL "Enable Descent I/II MVL support" true)
if(PHYSFS_ARCHIVE_MVL)
    add_definitions(-DPHYSFS_SUPPORTS_MVL=1)
endif(PHYSFS_ARCHIVE_MVL)

option(PHYSFS_ARCHIVE_QPAK "Enable Quake I/II QPAK support" true)
if(PHYSFS_ARCHIVE_QPAK)
    add_definitions(-DPHYSFS_SUPPORTS_QPAK=1)
endif(PHYSFS_ARCHIVE_QPAK)

option(PHYSFS_ARCHIVE_ISO9660 "Enable ISO9660 support" true)
if(PHYSFS_ARCHIVE_ISO9660)
    add_definitions(-DPHYSFS_SUPPORTS_ISO9660=1)
endif(PHYSFS_ARCHIVE_ISO9660)

#as needed by Hedgewars configuration
if(WINDOWS)
    option(PHYSFS_BUILD_STATIC "Build static library" false)
    option(PHYSFS_BUILD_SHARED "Build shared library" true)
    set(OTHER_LDFLAGS ${OTHER_LDFLAGS} ${SDL_LIBRARY})
else(WINDOWS)
    option(PHYSFS_BUILD_STATIC "Build static library" true)
    option(PHYSFS_BUILD_SHARED "Build shared library" false)
endif(WINDOWS)

if(PHYSFS_BUILD_STATIC)
    add_library(physfs STATIC ${PHYSFS_SRCS})
    set_target_properties(physfs PROPERTIES OUTPUT_NAME "physfs")
    set(PHYSFS_LIB_TARGET physfs)
    set(PHYSFS_INSTALL_TARGETS ${PHYSFS_INSTALL_TARGETS} ";physfs")
endif(PHYSFS_BUILD_STATIC)

if(PHYSFS_BUILD_SHARED)
    find_package(SDL REQUIRED)
    add_library(physfs SHARED ${PHYSFS_SRCS})
    set_target_properties(physfs PROPERTIES VERSION ${PHYSFS_VERSION})
    set_target_properties(physfs PROPERTIES SOVERSION ${PHYSFS_SOVERSION})
    target_link_libraries(physfs ${OPTIONAL_LIBRARY_LIBS} ${OTHER_LDFLAGS})
    set(PHYSFS_LIB_TARGET physfs)
    set(PHYSFS_INSTALL_TARGETS ${PHYSFS_INSTALL_TARGETS} ";physfs")
    install(TARGETS ${PHYSFS_INSTALL_TARGETS}
            RUNTIME DESTINATION bin)
endif(PHYSFS_BUILD_SHARED)

if(NOT PHYSFS_BUILD_SHARED AND NOT PHYSFS_BUILD_STATIC)
    message(FATAL "Both shared and static libraries are disabled!")
endif(NOT PHYSFS_BUILD_SHARED AND NOT PHYSFS_BUILD_STATIC)

# CMake FAQ says I need this...
if(PHYSFS_BUILD_SHARED AND PHYSFS_BUILD_STATIC)
    set_target_properties(physfs PROPERTIES CLEAN_DIRECT_OUTPUT 1)
endif(PHYSFS_BUILD_SHARED AND PHYSFS_BUILD_STATIC)

option(PHYSFS_BUILD_TEST "Build stdio test program." false)
mark_as_advanced(PHYSFS_BUILD_TEST)
if(PHYSFS_BUILD_TEST)
    find_path(READLINE_H readline/readline.h)
    find_path(HISTORY_H readline/history.h)
    if(READLINE_H AND HISTORY_H)
        find_library(CURSES_LIBRARY NAMES curses ncurses)
        set(CMAKE_REQUIRED_LIBRARIES ${CURSES_LIBRARY})
        find_library(READLINE_LIBRARY readline)
        if(READLINE_LIBRARY)
            set(HAVE_SYSTEM_READLINE true)
            set(TEST_PHYSFS_LIBS ${TEST_PHYSFS_LIBS} ${READLINE_LIBRARY} ${CURSES_LIBRARY})
            include_directories(${READLINE_H} ${HISTORY_H})
            add_definitions(-DPHYSFS_HAVE_READLINE=1)
        endif(READLINE_LIBRARY)
    endif(READLINE_H AND HISTORY_H)
    add_executable(test_physfs test/test_physfs.c)
    target_link_libraries(test_physfs ${PHYSFS_LIB_TARGET} ${TEST_PHYSFS_LIBS} ${OTHER_LDFLAGS})
    set(PHYSFS_INSTALL_TARGETS ${PHYSFS_INSTALL_TARGETS} ";test_physfs")
endif(PHYSFS_BUILD_TEST)


# Scripting language bindings...

#CMake's SWIG support is basically useless.
#FIND_PACKAGE(SWIG)

option(PHYSFS_BUILD_SWIG "Build ${_LANG} bindings." false)
mark_as_advanced(PHYSFS_BUILD_SWIG)

find_program(SWIG swig DOC "Path to swig command line app: http://swig.org/")
if(NOT SWIG)
    message(STATUS "SWIG not found. You won't be able to build scripting language bindings.")
else(NOT SWIG)
    mark_as_advanced(SWIG)
    if(DEFINED CMAKE_BUILD_TYPE)
        if((NOT CMAKE_BUILD_TYPE STREQUAL "") AND (NOT CMAKE_BUILD_TYPE STREQUAL "Debug"))
            if(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
                set(SWIG_OPT_CFLAGS "-small")
            else(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
                set(SWIG_OPT_CFLAGS "-O")
            endif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
        endif((NOT CMAKE_BUILD_TYPE STREQUAL "") AND (NOT CMAKE_BUILD_TYPE STREQUAL "Debug"))
    endif(DEFINED CMAKE_BUILD_TYPE)

    set(SWIG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/physfs-swig-bindings")

    macro(CONFIGURE_SWIG_BINDING _LANG _INSTALLPATH _EXTRAOUTPUTS _EXTRACFLAGS _EXTRALDFLAGS)
        string(TOUPPER "${_LANG}" _UPPERLANG)
        string(TOLOWER "${_LANG}" _LOWERLANG)
        set(_TARGET "physfs-${_LOWERLANG}")
        set(_TARGETDIR "${SWIG_OUTPUT_DIR}/${_LOWERLANG}")

        if(NOT EXISTS "${_TARGETDIR}")
            file(MAKE_DIRECTORY "${_TARGETDIR}")
        endif(NOT EXISTS "${_TARGETDIR}")

        if(PHYSFS_BUILD_${_UPPERLANG})
            add_custom_command(
                OUTPUT "${_TARGETDIR}/${_TARGET}.c" ${_EXTRAOUTPUTS}
                MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/extras/physfs-swig.i"
                COMMAND "${SWIG}"
                ARGS ${SWIG_OPT_CFLAGS} -${_LOWERLANG} -outdir "${_TARGETDIR}" -o "${_TARGETDIR}/${_TARGET}.c" "${CMAKE_CURRENT_SOURCE_DIR}/extras/physfs-swig.i"
                COMMENT "Generating ${_LANG} bindings..."
            )

            add_library(${_TARGET} SHARED "${_TARGETDIR}/${_TARGET}.c")
            target_link_libraries(${_TARGET} ${PHYSFS_LIB_TARGET})
            set_target_properties(${_TARGET} PROPERTIES
                COMPILE_FLAGS "${_EXTRACFLAGS}"
                LINK_FLAGS "${_EXTRALDFLAGS}"
                LIBRARY_OUTPUT_NAME "physfs"
                LIBRARY_OUTPUT_DIRECTORY "${_TARGETDIR}"
                CLEAN_DIRECT_OUTPUT 1
            )
            install(TARGETS ${_TARGET} LIBRARY DESTINATION "${_INSTALLPATH}")
            message(STATUS "${_LANG} bindings configured!")
        else(PHYSFS_BUILD_${_UPPERLANG})
            message(STATUS "Couldn't figure out ${_LANG} configuration. Skipping ${_LANG} bindings.")
        endif(PHYSFS_BUILD_${_UPPERLANG})
    endmacro(CONFIGURE_SWIG_BINDING)

    macro(ADD_SCRIPT_BINDING_OPTION _VAR _LANG _DEFVAL)
        set(BUILDSWIGVAL ${_DEFVAL})
        if(NOT PHYSFS_BUILD_SWIG)
            set(BUILDSWIGVAL false)
        endif(NOT PHYSFS_BUILD_SWIG)
        option(${_VAR} "Build ${_LANG} bindings." ${BUILDSWIGVAL})
        mark_as_advanced(${_VAR})
    endmacro(ADD_SCRIPT_BINDING_OPTION)

    ADD_SCRIPT_BINDING_OPTION(PHYSFS_BUILD_PERL "Perl" true)
    ADD_SCRIPT_BINDING_OPTION(PHYSFS_BUILD_RUBY "Ruby" true)
endif(NOT SWIG)

if(PHYSFS_BUILD_PERL)
    message(STATUS "Configuring Perl bindings...")
    find_program(PERL perl DOC "Path to perl command line app: http://perl.org/")
    if(NOT PERL)
        message(STATUS "Perl not found. You won't be able to build perl bindings.")
        set(PHYSFS_BUILD_PERL false)
    endif(NOT PERL)
    mark_as_advanced(PERL)

    macro(GET_PERL_CONFIG _KEY _VALUE)
        if(PHYSFS_BUILD_PERL)
            message(STATUS "Figuring out perl config value '${_KEY}' ...")
            execute_process(
                COMMAND ${PERL} -w -e "use Config; print \$Config{${_KEY}};"
                RESULT_VARIABLE GET_PERL_CONFIG_RC
                OUTPUT_VARIABLE ${_VALUE}
            )
            if(NOT GET_PERL_CONFIG_RC EQUAL 0)
                message(STATUS "Perl executable ('${PERL}') reported failure: ${GET_PERL_CONFIG_RC}")
                set(PHYSFS_BUILD_PERL false)
            endif(NOT GET_PERL_CONFIG_RC EQUAL 0)
            if(NOT ${_VALUE})
                message(STATUS "Perl executable ('${PERL}') didn't have a value for '${_KEY}'")
                set(PHYSFS_BUILD_PERL false)
            endif(NOT ${_VALUE})

            if(PHYSFS_BUILD_PERL)
                message(STATUS "Perl says: '${${_VALUE}}'.")
            endif(PHYSFS_BUILD_PERL)
        endif(PHYSFS_BUILD_PERL)
    endmacro(GET_PERL_CONFIG)

    # !!! FIXME: installsitearch might be the wrong location.
    GET_PERL_CONFIG("archlibexp" PERL_INCLUDE_PATH)
    GET_PERL_CONFIG("ccflags" PERL_CCFLAGS)
    GET_PERL_CONFIG("ldflags" PERL_LDFLAGS)
    GET_PERL_CONFIG("installsitearch" PERL_INSTALL_PATH)

    # !!! FIXME: this test for Mac OS X is wrong.
    if(MACOSX)
        GET_PERL_CONFIG("libperl" PERL_LIBPERL)
        set(TMPLIBPERL "${PERL_LIBPERL}")
        string(REGEX REPLACE "^lib" "" TMPLIBPERL "${TMPLIBPERL}")
        string(REGEX REPLACE "\\.so$" "" TMPLIBPERL "${TMPLIBPERL}")
        string(REGEX REPLACE "\\.dylib$" "" TMPLIBPERL "${TMPLIBPERL}")
        string(REGEX REPLACE "\\.dll$" "" TMPLIBPERL "${TMPLIBPERL}")
        if(NOT "${TMPLIBPERL}" STREQUAL "${PERL_LIBPERL}")
            message(STATUS "Stripped '${PERL_LIBPERL}' down to '${TMPLIBPERL}'.")
            set(PERL_LIBPERL "${TMPLIBPERL}")
        endif(NOT "${TMPLIBPERL}" STREQUAL "${PERL_LIBPERL}")
        set(PERL_LIBPERL "-l${PERL_LIBPERL}")
    endif(MACOSX)

    CONFIGURE_SWIG_BINDING(Perl "${PERL_INSTALL_PATH}" "${SWIG_OUTPUT_DIR}/perl/physfs.pm" "\"-I${PERL_INCLUDE_PATH}/CORE\" ${PERL_CCFLAGS} -w" "\"-L${PERL_INCLUDE_PATH}/CORE\" ${PERL_LIBPERL} ${PERL_LDFLAGS}")
    install(FILES "${SWIG_OUTPUT_DIR}/perl/physfs.pm" DESTINATION "${PERL_INSTALL_PATH}")
    install(
        FILES test/test_physfs.pl
        DESTINATION bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
endif(PHYSFS_BUILD_PERL)

# !!! FIXME: lots of cut-and-paste from perl bindings.
if(PHYSFS_BUILD_RUBY)
    message(STATUS "Configuring Ruby bindings...")
    find_program(RUBY ruby DOC "Path to ruby command line app: http://ruby-lang.org/")
    if(NOT RUBY)
        message(STATUS "Ruby not found. You won't be able to build ruby bindings.")
        set(PHYSFS_BUILD_RUBY FALSE)
    endif(NOT RUBY)
    mark_as_advanced(RUBY)

    macro(GET_RUBY_CONFIG _KEY _VALUE)
        if(PHYSFS_BUILD_RUBY)
            message(STATUS "Figuring out ruby config value '${_KEY}' ...")
            execute_process(
                COMMAND ${RUBY} -e "require 'rbconfig'; puts RbConfig::CONFIG['${_KEY}'];"
                RESULT_VARIABLE GET_RUBY_CONFIG_RC
                OUTPUT_VARIABLE ${_VALUE}
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            if(NOT GET_RUBY_CONFIG_RC EQUAL 0)
                message(STATUS "Ruby executable ('${RUBY}') reported failure: ${GET_RUBY_CONFIG_RC}")
                set(PHYSFS_BUILD_RUBY FALSE)
            endif(NOT GET_RUBY_CONFIG_RC EQUAL 0)
            if(NOT ${_VALUE})
                message(STATUS "Ruby executable ('${RUBY}') didn't have a value for '${_KEY}'")
                set(PHYSFS_BUILD_RUBY FALSE)
            endif(NOT ${_VALUE})

            if(PHYSFS_BUILD_RUBY)
                message(STATUS "Ruby says: '${${_VALUE}}'.")
            endif(PHYSFS_BUILD_RUBY)
        endif(PHYSFS_BUILD_RUBY)
    endmacro(GET_RUBY_CONFIG)

    GET_RUBY_CONFIG("archdir" RUBY_INCLUDE_PATH)
    GET_RUBY_CONFIG("CFLAGS" RUBY_CCFLAGS)
    GET_RUBY_CONFIG("LDFLAGS" RUBY_LDFLAGS)
    GET_RUBY_CONFIG("sitearchdir" RUBY_INSTALL_PATH)
    GET_RUBY_CONFIG("LIBRUBYARG_SHARED" RUBY_LIBRUBY)
    GET_RUBY_CONFIG("libdir" RUBY_LIBDIR)

    CONFIGURE_SWIG_BINDING(Ruby "${RUBY_INSTALL_PATH}" "" "\"-I${RUBY_INCLUDE_PATH}\" ${RUBY_CCFLAGS} -w" "\"-L${RUBY_LIBDIR}\" ${RUBY_LIBRUBY} ${RUBY_LDFLAGS}")
    set_target_properties(physfs-ruby PROPERTIES PREFIX "")
    install(
        FILES test/test_physfs.rb
        DESTINATION bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
endif(PHYSFS_BUILD_RUBY)


#INSTALL(TARGETS ${PHYSFS_INSTALL_TARGETS}
#        RUNTIME DESTINATION bin
#        LIBRARY DESTINATION lib${LIB_SUFFIX}
#        ARCHIVE DESTINATION lib${LIB_SUFFIX})
#INSTALL(FILES src/physfs.h DESTINATION include)

if(UNIX)
    set(PHYSFS_TARBALL "${CMAKE_CURRENT_SOURCE_DIR}/../physfs-${PHYSFS_VERSION}.tar.gz")
    add_custom_target(
        dist
        hg archive -t tgz "${PHYSFS_TARBALL}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "Building source tarball '${PHYSFS_TARBALL}'..."
    )
#    ADD_CUSTOM_TARGET(
#        uninstall
#        "${CMAKE_CURRENT_SOURCE_DIR}/extras/uninstall.sh"
#        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
#        COMMENT "Uninstall the project..."
#    )
endif(UNIX)

macro(MESSAGE_BOOL_OPTION _NAME _VALUE)
    if(${_VALUE})
        message(STATUS "  ${_NAME}: enabled")
    else(${_VALUE})
        message(STATUS "  ${_NAME}: disabled")
    endif(${_VALUE})
endmacro(MESSAGE_BOOL_OPTION)

message(STATUS "PhysicsFS will build with the following options:")
MESSAGE_BOOL_OPTION("ZIP support" PHYSFS_ARCHIVE_ZIP)
MESSAGE_BOOL_OPTION("7zip support" PHYSFS_ARCHIVE_7Z)
MESSAGE_BOOL_OPTION("GRP support" PHYSFS_ARCHIVE_GRP)
MESSAGE_BOOL_OPTION("WAD support" PHYSFS_ARCHIVE_WAD)
MESSAGE_BOOL_OPTION("HOG support" PHYSFS_ARCHIVE_HOG)
MESSAGE_BOOL_OPTION("MVL support" PHYSFS_ARCHIVE_MVL)
MESSAGE_BOOL_OPTION("QPAK support" PHYSFS_ARCHIVE_QPAK)
MESSAGE_BOOL_OPTION("CD-ROM drive support" PHYSFS_HAVE_CDROM_SUPPORT)
MESSAGE_BOOL_OPTION("Thread safety" PHYSFS_HAVE_THREAD_SUPPORT)
MESSAGE_BOOL_OPTION("Build static library" PHYSFS_BUILD_STATIC)
MESSAGE_BOOL_OPTION("Build shared library" PHYSFS_BUILD_SHARED)
MESSAGE_BOOL_OPTION("Build Perl bindings" PHYSFS_BUILD_PERL)
MESSAGE_BOOL_OPTION("Build Ruby bindings" PHYSFS_BUILD_RUBY)
MESSAGE_BOOL_OPTION("Build stdio test program" PHYSFS_BUILD_TEST)
if(PHYSFS_BUILD_TEST)
    MESSAGE_BOOL_OPTION("  Use readline in test program" HAVE_SYSTEM_READLINE)
endif(PHYSFS_BUILD_TEST)

# end of CMakeLists.txt ...

