cmake_minimum_required(VERSION 3.16)

project(hhtracer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Svg)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(apphhtracer
    main.cpp
)

qt_add_qml_module(apphhtracer
    URI hhtracer
    VERSION 1.0
    QML_FILES
        Main.qml
        SOURCES tracer.h tracer.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(apphhtracer PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.apphhtracer
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(apphhtracer
    PRIVATE Qt6::Quick
    Qt6::Svg
)

include(GNUInstallDirs)
install(TARGETS apphhtracer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
