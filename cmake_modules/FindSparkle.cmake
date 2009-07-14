### SuperTux - Removed unused vorbisenc library

# - Try to find the OggVorbis libraries
# Once done this will define
#
#  OGGVORBIS_FOUND - system has OggVorbis
#  OGGVORBIS_VERSION - set either to 1 or 2
#  OGGVORBIS_INCLUDE_DIR - the OggVorbis include directory
#  OGGVORBIS_LIBRARIES - The libraries needed to use OggVorbis
#  OGG_LIBRARY         - The Ogg library
#  VORBIS_LIBRARY      - The Vorbis library
#  VORBISFILE_LIBRARY  - The VorbisFile library
# Copyright (c) 2006, Richard Laerkaeng, <richard@goteborg.utfors.se>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

include (CheckLibraryExists)
find_path(SPARKLE_INCLUDE_DIR Sparkle.h)
find_library(SPARKLE_LIBRARY NAMES Sparkle)

if (SPARKLE_INCLUDE_DIR AND SPARKLE_LIBRARY)
   set(SPARKLE_FOUND TRUE)
else ()
   set(SPARKLE_FOUND FALSE)
endif ()

if (SPARKLE_FOUND)
   if (NOT Sparkle_FIND_QUIETLY)
      message(STATUS "Found Sparkle: ${SPARKLE_LIBRARY}")
   endif ()
else ()
   if (Sparkle_FIND_REQUIRED)
      message(FATAL_ERROR "Could NOT find Sparkle framework")
   endif ()
   if (NOT Sparkle_FIND_QUIETLY)
      message(STATUS "Could NOT find Sparkle framework")
   endif ()
endif ()

