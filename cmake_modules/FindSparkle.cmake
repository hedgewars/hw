### Hedgewars

# - Try to find the Sparkle framework
# Once done this will define
#
#  SPARKLE_FOUND - system has Sparkle
#  SPARKLE_INCLUDE_DIR - the Sparkle include directory
#  SPARKLE_LIBRARY - The library needed to use Sparkle
# Copyright (c) 2009, Vittorio Giovara, <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of a Creative Commons license.
# For details see http://creativecommons.org/licenses/by-sa/3.0/
# original version of this module was derived from Richard Laerkaeng, <richard@goteborg.utfors.se>


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
   else ()
      if (NOT Sparkle_FIND_QUIETLY)
         message(STATUS "Could NOT find Sparkle framework, autoupdate feature will be disabled")
      endif()
   endif ()
endif ()

