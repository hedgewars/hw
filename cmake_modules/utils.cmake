
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

#TODO: find_package_or_bundle

