# Find ffmpeg/libav libraries (libavcodec, libavformat and libavutil)
# Once done this will define
#
#  FFMPEG_FOUND             - system has libavcodec, libavformat, libavutil
#  FFMPEG_INCLUDE_DIR       - the libav include directories
#  FFMPEG_LIBRARIES         - the libav libraries
#
#  LIBAVCODEC_LIBRARY      - the libavcodec library
#  LIBAVCODEC_INCLUDE_DIR  - the libavcodec include directory
#  LIBAVFORMAT_LIBRARY     - the libavformat library
#  LIBAVUTIL_LIBRARY       - the libavutil library
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
        pkg_check_modules(_FFMPEG_AVCODEC libavcodec)
    endif()
    if(NOT LIBAVFORMAT_LIBRARY)
        pkg_check_modules(_FFMPEG_AVFORMAT libavformat)
    endif()
    if(NOT LIBAVUTIL_LIBRARY)
        pkg_check_modules(_FFMPEG_AVUTIL libavutil)
    endif()
endif(PKG_CONFIG_FOUND)

find_path(LIBAVCODEC_INCLUDE_DIR
    NAMES libavcodec/avcodec.h
    PATHS ${_FFMPEG_AVCODEC_INCLUDE_DIRS}    #pkg-config
          /usr/include /usr/local/include    #system level
          /opt/local/include /sw/include     #macports & fink
    PATH_SUFFIXES libav ffmpeg
)

#TODO: add other include paths

find_library(LIBAVCODEC_LIBRARY
    NAMES avcodec
    PATHS ${_FFMPEG_AVCODEC_LIBRARY_DIRS}   #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_library(LIBAVFORMAT_LIBRARY
    NAMES avformat
    PATHS ${_FFMPEG_AVFORMAT_LIBRARY_DIRS}  #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_library(LIBAVUTIL_LIBRARY
    NAMES avutil
    PATHS ${_FFMPEG_AVUTIL_LIBRARY_DIRS}    #pkg-config
          /usr/lib /usr/local/lib           #system level
          /opt/local/lib /sw/lib            #macports & fink
)

find_package_handle_standard_args(FFMPEG DEFAULT_MSG LIBAVCODEC_LIBRARY LIBAVCODEC_INCLUDE_DIR
                                                     LIBAVFORMAT_LIBRARY
                                                     LIBAVUTIL_LIBRARY
                                                     )
set(FFMPEG_INCLUDE_DIR ${LIBAVCODEC_INCLUDE_DIR}
                       #TODO: add other include paths
                       )
set(FFMPEG_LIBRARIES ${LIBAVCODEC_LIBRARY}
                     ${LIBAVFORMAT_LIBRARY}
                     ${LIBAVUTIL_LIBRARY}
                     )

mark_as_advanced(FFMPEG_INCLUDE_DIR FFMPEG_LIBRARIES LIBAVCODEC_LIBRARY LIBAVCODEC_INCLUDE_DIR LIBAVFORMAT_LIBRARY LIBAVUTIL_LIBRARY)


