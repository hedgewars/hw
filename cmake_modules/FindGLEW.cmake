# Find GLEW
#
# Once done this will define
#  GLEW_FOUND - system has GLEW
#  GLEW_INCLUDE_DIR - the GLEW include directory
#  GLEW_LIBRARY - The library needed to use GLEW
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.

include(FindPackageHandleStandardArgs)

find_path( GLEW_INCLUDE_DIR GL/glew.h
            /usr/include
            /usr/local/include
            /sw/include
            /opt/local/include
            $ENV{PROGRAMFILES}/GLEW/include
            DOC "The directory where GL/glew.h resides")
find_library( GLEW_LIBRARY
            NAMES GLEW glew glew32 glew32s
            PATHS
            /usr/lib64
            /usr/lib
            /usr/local/lib64
            /usr/local/lib
            /sw/lib
            /opt/local/lib
            $ENV{PROGRAMFILES}/GLEW/lib
            DOC "The GLEW library")

find_package_handle_standard_args(GLEW DEFAULT_MSG GLEW_LIBRARY GLEW_INCLUDE_DIR)
mark_as_advanced(GLEW_LIBRARY GLEW_INCLUDE_DIR)

