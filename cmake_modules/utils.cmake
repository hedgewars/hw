
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
        message(SEND_ERROR "Missing ${_PKG_NAME}! Rerun cmake with -D${_VAR_NAME}=1 to build without it.")
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

macro(append_linker_flag _FLAG)
    list(APPEND pascal_flags "-k${_FLAG}")
    list(APPEND haskell_flags "-optl" "${_FLAG}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,${_FLAG}")
    set(CMAKE_SHARED_LIBRARY_C_FLAGS "${CMAKE_SHARED_LIBRARY_C_FLAGS} -Wl,${_FLAG}")
    set(CMAKE_SHARED_LIBRARY_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_CXX_FLAGS} -Wl,${_FLAG}")
endmacro(append_linker_flag _FLAG)

#TODO: find_package_or_bundle


macro(add_flag_append _VAR_NAME _FLAG)
    set(${_VAR_NAME} "${${_VAR_NAME}} ${_FLAG}")
endmacro(add_flag_append _VAR_NAME _FLAG)

macro(add_flag_prepend _VAR_NAME _FLAG)
    set(${_VAR_NAME} "${_FLAG} ${${_VAR_NAME}}")
endmacro(add_flag_prepend _VAR_NAME _FLAG)

