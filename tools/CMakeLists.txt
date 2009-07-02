if (APPLE AND BUNDLE)

find_program(macdeployqt_EXE NAMES macdeployqt macdeployqt-mac)

if(NOT macdeployqt_EXE)
	message(FATAL_ERROR "The utility macdeployqt is required to create the bundle!")
endif()

#if(HAVE_NETSERVER)
add_custom_target(bundle)
#set(deps_list hedgewars "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")
#else(HAVE_NETSERVER)
#add_custom_target(bundle )
#set(deps_list hedgewars "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")
#endif(HAVE_NETSERVER)

set_target_properties(bundle PROPERTIES POST_INSTALL_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

set(frameworks_dir ${bundle_name}/Contents/Frameworks/)

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/CreateMacBundle.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

endif()
