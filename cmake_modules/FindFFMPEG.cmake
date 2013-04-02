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
if (PKG_CONFIG_FOUND)
    pkg_check_modules(_FFMPEG_AVCODEC libavcodec ${VERBOSITY})
    pkg_check_modules(_FFMPEG_AVFORMAT libavformat ${VERBOSITY})
    pkg_check_modules(_FFMPEG_AVUTIL libavutil ${VERBOSITY})
endif (PKG_CONFIG_FOUND)

find_path(LIBAVCODEC_INCLUDE_DIR
    NAMES libavcodec/avcodec.h
    PATHS ${_AVCODEC_INCLUDE_DIRS}
        /usr/include /usr/local/include #system level
        /opt/local/include #macports
        /sw/include #fink
    PATH_SUFFIXES libav ffmpeg
)

#TODO: add other include paths

find_library(LIBAVCODEC_LIBRARY
    NAMES avcodec
    PATHS ${_AVCODEC_LIBRARY_DIRS}
        /usr/lib /usr/local/lib #system level
        /opt/local/lib #macports
        /sw/lib #fink
)

find_library(LIBAVFORMAT_LIBRARY
    NAMES avformat
    PATHS ${_AVFORMAT_LIBRARY_DIRS}
        /usr/lib /usr/local/lib #system level
        /opt/local/lib #macports
        /sw/lib #fink
)

find_library(LIBAVUTIL_LIBRARY
    NAMES avutil
    PATHS ${_AVUTIL_LIBRARY_DIRS}
        /usr/lib /usr/local/lib #system level
        /opt/local/lib #macports
        /sw/lib #fink
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


