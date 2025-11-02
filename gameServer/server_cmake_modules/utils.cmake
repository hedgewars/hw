
#find package helpers
macro(find_package_or_fail _PKG_NAME)
    find_package(${_PKG_NAME})
    string(TOUPPER ${_PKG_NAME} _PKG_NAME_UP)
    if(NOT ${_PKG_NAME_UP}_FOUND)
        message(SEND_ERROR "Missing ${_PKG_NAME}! Please install it and rerun cmake.")
    endif(NOT ${_PKG_NAME_UP}_FOUND)
endmacro(find_package_or_fail _PKG_NAME)

macro(find_package_or_disable _PKG_NAME _VAR_NAME)
    find_package(${_PKG_NAME})
    string(TOUPPER ${_PKG_NAME} _PKG_NAME_UP)
    if(NOT ${_PKG_NAME_UP}_FOUND)
        message(SEND_ERROR "Missing ${_PKG_NAME}! Rerun cmake with -D${_VAR_NAME}=1 to skip this error.")
    endif(NOT ${_PKG_NAME_UP}_FOUND)
endmacro(find_package_or_disable _PKG_NAME _VAR_NAME)

macro(find_package_or_disable_msg _PKG_NAME _VAR_NAME _MSG)
    if(NOT ${_VAR_NAME})
        find_package_or_disable(${_PKG_NAME} ${_VAR_NAME})
    else(NOT ${_VAR_NAME})
        message(STATUS "${_PKG_NAME} disabled. ${_MSG}")
        string(TOUPPER ${_PKG_NAME} _PKG_NAME_UP)
        set(${_PKG_NAME_UP}_FOUND false)
    endif(NOT ${_VAR_NAME})
endmacro(find_package_or_disable_msg _PKG_NAME _VAR_NAME _MSG)

#variable manipulation macros
macro(add_flag_append _VAR_NAME _FLAG)
    set(${_VAR_NAME} "${${_VAR_NAME}} ${_FLAG}")
endmacro(add_flag_append _VAR_NAME _FLAG)

macro(add_flag_prepend _VAR_NAME _FLAG)
    set(${_VAR_NAME} "${_FLAG} ${${_VAR_NAME}}")
endmacro(add_flag_prepend _VAR_NAME _FLAG)

macro(add_linker_flag _FLAG)
    list(APPEND haskell_flags "-optl" "-Wl,${_FLAG}")
    #executables
    add_flag_append(CMAKE_C_LINK_FLAGS "-Wl,${_FLAG}")
    add_flag_append(CMAKE_CXX_LINK_FLAGS "-Wl,${_FLAG}")
    add_flag_append(CMAKE_Pascal_LINK_FLAGS "-k${_FLAG}")
    #libraries
    add_flag_append(CMAKE_SHARED_LIBRARY_C_FLAGS "-Wl,${_FLAG}")
    add_flag_append(CMAKE_SHARED_LIBRARY_CXX_FLAGS "-Wl,${_FLAG}")
    #CMAKE_SHARED_LIBRARY_Pascal_FLAGS is already set by CMAKE_Pascal_LINK_FLAGS
endmacro(add_linker_flag _FLAG)

#TODO: find_package_or_bundle



