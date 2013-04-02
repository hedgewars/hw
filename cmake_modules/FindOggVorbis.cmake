# - Try to find the OggVorbis libraries
# Once done this will define
#
#  OGGVORBIS_FOUND       - system has both Ogg and Vorbis
#  OGGVORBIS_VERSION     - set either to 1 or 2
#  OGGVORBIS_INCLUDE_DIR - the OggVorbis include directory
#  OGGVORBIS_LIBRARIES   - the libraries needed to use OggVorbis
#
#  OGG_LIBRARY           - the Ogg library
#  OGG_INCLUDE_DIR       - the Ogg include directory
#  VORBIS_LIBRARY        - the Vorbis library
#  VORBIS_INCLUDE_DIR    - the Vorbis include directory
#  VORBISFILE_LIBRARY    - the VorbisFile library
#
# Copyright (c) 2006, Richard Laerkaeng <richard@goteborg.utfors.se>
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

### sommer [SuperTux]
##  - Removed unused vorbisenc library
##  - reversed order of libraries, so that cmake 2.4.5 for Windows generates an MSYS Makefile that will link correctly

### koda [Hedgewars]
##  - split ogg and vorbis lookup
##  - special case for framework handling
##  - standard variables handling


include (CheckLibraryExists)
include (FindPackageHandleStandardArgs)

find_path(OGG_INCLUDE_DIR ogg.h PATH_SUFFIXES ogg)
find_path(VORBIS_INCLUDE_DIR vorbisfile.h PATH_SUFFIXES vorbis)

find_library(OGG_LIBRARY NAMES Ogg ogg)
find_library(VORBIS_LIBRARY NAMES Vorbis vorbis)
find_library(VORBISFILE_LIBRARY NAMES vorbisfile)

set(_CMAKE_REQUIRED_LIBRARIES_TMP ${CMAKE_REQUIRED_LIBRARIES})
set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${OGGVORBIS_LIBRARIES})
check_library_exists(${VORBIS_LIBRARY} vorbis_bitrate_addblock "" HAVE_LIBVORBISENC2)
set(CMAKE_REQUIRED_LIBRARIES ${_CMAKE_REQUIRED_LIBRARIES_TMP})

if(HAVE_LIBVORBISENC2)
    set(OGGVORBIS_VERSION 2)
else(HAVE_LIBVORBISENC2)
    set(OGGVORBIS_VERSION 1)
endif(HAVE_LIBVORBISENC2)

if(${OGG_LIBRARY} MATCHES ".framework" AND ${VORBIS_LIBRARY} MATCHES ".framework")
    set(VORBISFILE_LIBRARY "") #vorbisfile will appear as NOTFOUND and discarded
    set(fphsa_vorbis_list VORBIS_LIBRARY)
else()
    set(fphsa_vorbis_list VORBISFILE_LIBRARY VORBIS_LIBRARY)
endif()

find_package_handle_standard_args(OggVorbis DEFAULT_MSG ${fphsa_vorbis_list} OGG_LIBRARY
                                                        OGG_INCLUDE_DIR VORBIS_INCLUDE_DIR)
unset(fphsa_vorbis_list)

set(OGGVORBIS_LIBRARIES ${VORBISFILE_LIBRARY} ${VORBIS_LIBRARY} ${OGG_LIBRARY})
set(OGGVORBIS_INCLUDE_DIR ${VORBIS_INCLUDE_DIR} ${OGG_INCLUDE_DIR})

mark_as_advanced(OGGVORBIS_VERSION OGGVORBIS_INCLUDE_DIR OGGVORBIS_LIBRARIES
                 OGG_LIBRARY OGG_INCLUDE_DIR VORBIS_LIBRARY VORBIS_INCLUDE_DIR VORBISFILE_LIBRARY)

