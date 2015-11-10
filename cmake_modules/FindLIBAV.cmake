# Find ffmpeg/libav libraries (libavcodec, libavformat and libavutil)
# Once done this will define
#
#  LIBAV_FOUND             - system has libavcodec, libavformat, libavutil
#  LIBAV_INCLUDE_DIR       - libav include directories
#  LIBAV_LIBRARIES         - libav libraries (libavcodec, libavformat, libavutil)
#
#  LIBAVCODEC_LIBRARY      - libavcodec library
#  LIBAVCODEC_INCLUDE_DIR  - libavcodec include directory
#  LIBAVFORMAT_LIBRARY     - libavformat library
#  LIBAVUTIL_LIBRARY       - libavutil library
#
#  Copyright (c) 2008 Andreas Schneider <mail@cynapses.org>
#  Modified for other libraries by Lasse Kärkkäinen <tronic>
#  Modified for Hedgewars by Stepik777
#  Copyright (c) 2013 Vittorio Giovara <vittorio.giovara@gmail.com>
#
#  Redistribution and use is allowed according to the terms of the New
#  BSD license.
#

include(FindPackageHandleStandardArgs)


# use pkg-config to get the directories and then use these values
# in the FIND_PATH() and FIND_LIBRARY() calls
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
    if(NOT LIBAVCODEC_INCLUDE_DIR OR NOT LIBAVCODEC_LIBRARY)
        pkg_check_modules(_LIBAV_AVCODEC libavcodec)
    endif()
    if(NOT LIBAVFORMAT_LIBRARY)
        pkg_check_modules(_LIBAV_AVFORMAT libavformat)
    endif()
    if(NOT LIBAVUTIL_LIBRARY)
        pkg_check_modules(_LIBAV_AVUTIL libavutil)
    endif()
endif(PKG_CONFIG_FOUND)

find_path(LIBAVCODEC_INCLUDE_DIR
    NAMES libavcodec/avcodec.h
    PATHS ${_LIBAV_AVCODEC_INCLUDE_DIRS}     #pkg-config
          /usr/include /usr/local/include    #system level
          /opt/local/include /sw/include     #macports & fink
    PATH_SUFFIXES libav ffmpeg
)

#TODO: add other include paths

find_library(LIBAVCODEC_LIBRARY
    NAMES avcodec
    PATHS ${_LIBAV_AVCODEC_LIBRARY_DIRS}    #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_library(LIBAVFORMAT_LIBRARY
    NAMES avformat
    PATHS ${_LIBAV_AVFORMAT_LIBRARY_DIRS}   #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_library(LIBAVUTIL_LIBRARY
    NAMES avutil
    PATHS ${_LIBAV_AVUTIL_LIBRARY_DIRS}     #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_package_handle_standard_args(LIBAV DEFAULT_MSG LIBAVCODEC_LIBRARY
                                                    LIBAVCODEC_INCLUDE_DIR
                                                    LIBAVFORMAT_LIBRARY
                                                    LIBAVUTIL_LIBRARY
                                                    )
set(LIBAV_INCLUDE_DIR ${LIBAVCODEC_INCLUDE_DIR}
                      #TODO: add other include paths
                      )
set(LIBAV_LIBRARIES ${LIBAVCODEC_LIBRARY}
                    ${LIBAVFORMAT_LIBRARY}
                    ${LIBAVUTIL_LIBRARY}
                    )

mark_as_advanced(LIBAV_INCLUDE_DIR
                 LIBAV_LIBRARIES
                 LIBAVCODEC_LIBRARY
                 LIBAVCODEC_INCLUDE_DIR
                 LIBAVFORMAT_LIBRARY
                 LIBAVUTIL_LIBRARY)

