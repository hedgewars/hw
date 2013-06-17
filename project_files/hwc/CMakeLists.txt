#the usual set of dependencies
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)
find_package(SDL_net REQUIRED)
find_package(SDL_image REQUIRED)
find_package(SDL_ttf REQUIRED)

#compile our rtl implementation
include_directories(${GLEW_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/rtl)
add_subdirectory(rtl)

configure_file(${CMAKE_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#get the list of pas files that are going to be converted and compiled
file(GLOB engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/*.pas")
#TODO: temporary until cmake can configure itself accordingly
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uWeb.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uVideoRec.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uTouch.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/PNGh.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cSystem.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cRedo.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/hwLibrary.pas")

foreach(sourcefile ${engine_sources_pas})
    get_filename_component(sourcename ${sourcefile} NAME_WE) #drops .pas
    set(engine_sources "${CMAKE_CURRENT_BINARY_DIR}/${sourcename}.c" ${engine_sources})
endforeach()

#invoke pas2c on our pas files
add_custom_command(OUTPUT ${engine_sources}
        COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
        ARGS -n "hwengine"
             -i "${CMAKE_SOURCE_DIR}/hedgewars"
             -o "${CMAKE_CURRENT_BINARY_DIR}"
             -a "${CMAKE_CURRENT_BINARY_DIR}"
        DEPENDS pas2c
    )
add_custom_target(engine_c DEPENDS ${engine_sources})


#compile the c files
add_executable(hwengine WIN32 ${engine_sources})

target_link_libraries(hwengine  fpcrtl
                                ${LUA_LIBRARY}
                                ${OPENGL_LIBRARY}
                                ${SDL_LIBRARY}
                                ${SDLMIXER_LIBRARY}
                                ${SDLNET_LIBRARY}
                                ${SDLIMAGE_LIBRARY}
                                ${SDLTTF_LIBRARY}
                                ${GLEW_LIBRARY}
                                physfs
                                physlayer
                                #TODO: add other libraries
                            )
if(APPLE)
    target_link_libraries(hwengine IOKit SDLmain)
endif()

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})

