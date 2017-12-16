#the usual set of dependencies
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
find_package(SDL2 REQUIRED)
find_package(SDL2_mixer 2 REQUIRED)
find_package(SDL2_net 2 REQUIRED)
find_package(SDL2_image 2 REQUIRED)
find_package(SDL2_ttf 2 REQUIRED)

#compile our rtl implementation
include_directories(${GLEW_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/rtl)
include_directories(${PHYSFS_INCLUDE_DIR})
include_directories(${PHYSLAYER_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR})
include_directories(${SDL2_INCLUDE_DIRS})
add_subdirectory(rtl)

# convert list into pascal array
if(FONTS_DIRS)
  list(LENGTH FONTS_DIRS ndirs)
  set(FONTS_DIRS_ARRAY "array [0..${ndirs}] of PChar = (")
  foreach(fontdir ${FONTS_DIRS})
      set(FONTS_DIRS_ARRAY "${FONTS_DIRS_ARRAY}\n_P'${fontdir}',")
  endforeach(fontdir)
  set(FONTS_DIRS_ARRAY "${FONTS_DIRS_ARRAY}\nnil);\n")
else(FONTS_DIRS)
  set(FONTS_DIRS_ARRAY "array [0..1] of PChar = (nil, nil);")
endif(FONTS_DIRS)

configure_file(${CMAKE_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#get the list of pas files that are going to be converted and compiled
file(GLOB engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/*.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uVideoRec.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uTouch.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/PNGh.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cSystem.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cRedo.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/hwLibrary.pas")
if(NOT GL2)
    list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uMatrix.pas")
endif()

#remove and readd hwengine so that it is compiled first, compiling every other file in the process
list(REMOVE_ITEM engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/hwengine.pas)
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/hwengine.pas)

#process files .pas -> .c
foreach(sourcefile ${engine_sources_pas})
    get_filename_component(sourcename ${sourcefile} NAME_WE) #drops .pas
    list(APPEND engine_sources "${CMAKE_CURRENT_BINARY_DIR}/${sourcename}.c")
endforeach()

#add again files for external functions and for fpcrtl_ functions
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/pas2cSystem.pas)
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/pas2cRedo.pas)


set(pas2c_args -n hwengine
               -i ${CMAKE_SOURCE_DIR}/hedgewars
               -o ${CMAKE_CURRENT_BINARY_DIR}
               -a ${CMAKE_CURRENT_BINARY_DIR}
               -d ENDIAN_LITTLE
               -d DEBUGFILE)
if(BUILD_ENGINE_JS)
    set(pas2c_args ${pas2c_args} -d WEBGL)
endif()
if(BUILD_ENGINE_LIBRARY)
    set(pas2c_args ${pas2c_args} -d HWLIBRARY)
endif()
if(GL2)
    set(pas2c_args ${pas2c_args} -d GL2)
endif()

#invoke pas2c on main module, it will call all the others
add_custom_command(OUTPUT ${engine_sources}
                   COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
                   ARGS ${pas2c_args}
                   DEPENDS pas2c                     #converter tool
                           ${engine_sources_pas}     #original pascal file
                  )

#wrap conversion for all source in this command
add_custom_target(engine_c DEPENDS ${engine_sources})


if(BUILD_ENGINE_JS)
    add_flag_append(CMAKE_C_FLAGS "--memory-init-file 0 -O0 --js-opts 0 -g4 --use-preload-plugins -s ASSERTIONS=2 -s USE_SDL=2 -s USE_SDL_IMAGE=1 -s USE_LIBPNG=1 -s USE_SDL_TTF=2 -s USE_VORBIS=1 -s USE_OGG=1 -s TOTAL_MEMORY=100000000 -s GL_UNSAFE_OPTS=0 -s EXPORTED_FUNCTIONS=\"['_hwengine_RunEngine', '_hwengine_MainLoop']\" --post-js ${CMAKE_SOURCE_DIR}/project_files/web/post.js --pre-js ${CMAKE_SOURCE_DIR}/project_files/web/pre.js")
endif()

#compile the c files
add_definitions(-DPAS2C)
add_definitions(-Werror=incompatible-pointer-types)

add_executable(hwengine WIN32 ${engine_sources})

if(BUILD_ENGINE_JS)
    set_target_properties(hwengine PROPERTIES SUFFIX ".html")
endif()

target_link_libraries(hwengine  fpcrtl
                                ${LUA_LIBRARY}
                                ${OPENGL_LIBRARY}
                                ${SDL2_LIBRARY}
                                ${SDL2_MIXER_LIBRARIES}
                                ${SDL2_NET_LIBRARIES}
                                ${SDL2_IMAGE_LIBRARIES}
                                ${SDL2_TTF_LIBRARIES}
                                ${GLEW_LIBRARY}
                                physfs
                                physlayer
                                m
                                #TODO: add other libraries
                            )
install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})

