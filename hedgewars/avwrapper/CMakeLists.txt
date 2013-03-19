#FFMPEG/Libav libraries have been searched already in main CMakeLists.txt

# TODO: this check is only for SDL < 2
# fpc will take care of linking but we need to have this library installed
find_package(GLUT REQUIRED)

#TODO: convert avwrapper to .pas unit so we can skip this step
include_directories(${FFMPEG_INCLUDE_DIR})

if(WIN32)
    # it's not possible to statically link libraries on windows, so let's build a shared version here
    add_library(avwrapper SHARED avwrapper.c)

    target_link_libraries(avwrapper ${FFMPEG_LIBRARIES})

    install(PROGRAMS "${LIBRARY_OUTPUT_PATH}/${CMAKE_SHARED_LIBRARY_PREFIX}avwrapper${CMAKE_SHARED_LIBRARY_SUFFIX}" DESTINATION ${target_library_install_dir})
else()
    add_library(avwrapper STATIC avwrapper.c)
endif()

