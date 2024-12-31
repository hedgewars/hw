cmake_minimum_required(VERSION 3.16)

project(map_templates_tool VERSION 1.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.2 COMPONENTS Quick REQUIRED)

qt_add_executable(appmap_templates_tool
    main.cpp
)

qt_add_qml_module(appmap_templates_tool
    URI map_templates_tool
    VERSION 1.0
    QML_FILES main.qml 
)

set_target_properties(appmap_templates_tool PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appmap_templates_tool
    PRIVATE Qt6::Quick)

install(TARGETS appmap_templates_tool
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
