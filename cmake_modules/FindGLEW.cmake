#
# Try to find GLEW library and include path.
# Once done this will define
#
# GLEW_FOUND
# GLEW_INCLUDE_PATH
# GLEW_LIBRARY
# 

if (GLEW_LIBRARY AND GLEW_INCLUDE_PATH)
  # in cache already
  set(GLEW_FOUND TRUE)
else (GLEW_LIBRARY AND GLEW_INCLUDE_PATH)

    IF (WIN32)
        FIND_PATH( GLEW_INCLUDE_PATH GL/glew.h
            $ENV{PROGRAMFILES}/GLEW/include
            ${PROJECT_SOURCE_DIR}/src/nvgl/glew/include
            DOC "The directory where GL/glew.h resides")
        FIND_LIBRARY( GLEW_LIBRARY
            NAMES glew GLEW glew32 glew32s
            PATHS
            $ENV{PROGRAMFILES}/GLEW/lib
            ${PROJECT_SOURCE_DIR}/src/nvgl/glew/bin
            ${PROJECT_SOURCE_DIR}/src/nvgl/glew/lib
        DOC "The GLEW library")
    ELSE (WIN32)
        FIND_PATH( GLEW_INCLUDE_PATH GL/glew.h
            /usr/include
            /usr/local/include
            /sw/include
            /opt/local/include
            DOC "The directory where GL/glew.h resides")
        FIND_LIBRARY( GLEW_LIBRARY
            NAMES GLEW glew
            PATHS
            /usr/lib64
            /usr/lib
            /usr/local/lib64
            /usr/local/lib
            /sw/lib
            /opt/local/lib
            DOC "The GLEW library")
    ENDIF (WIN32)

    IF (GLEW_LIBRARY AND GLEW_INCLUDE_PATH)
        SET( GLEW_FOUND 1 CACHE STRING "Set to 1 if GLEW is found, 0 otherwise")
    ELSE (GLEW_LIBRARY AND GLEW_INCLUDE_PATH)
        SET( GLEW_FOUND 0 CACHE STRING "Set to 1 if GLEW is found, 0 otherwise")
    ENDIF (GLEW_LIBRARY AND GLEW_INCLUDE_PATH)

endif(GLEW_LIBRARY AND GLEW_INCLUDE_PATH)

if (GLEW_FOUND)
    if (NOT GLEW_FIND_QUIETLY)
        message(STATUS "Found GLEW: ${GLEW_LIBRARY}, ${GLEW_INCLUDE_PATH}")
    endif (NOT GLEW_FIND_QUIETLY)
else (GLEW_FOUND)
    if (GLEW_FIND_REQUIRED)
        message(FATAL_ERROR "Could NOT find GLEW")
    endif (GLEW_FIND_REQUIRED)
endif (GLEW_FOUND)

#MARK_AS_ADVANCED( GLEW_FOUND )