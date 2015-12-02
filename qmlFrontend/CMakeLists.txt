cmake_minimum_required(VERSION 2.8.11)

project(hedgewars)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

find_package(OpenGL)

find_package(Qt5 COMPONENTS Core Qml Quick Gui)

qt5_add_resources(qresources qmlFrontend.qrc)

add_executable(hedgewars WIN32
    main
    hwengine
    previewimageprovider
    themeiconprovider
    qtquick2applicationviewer/qtquick2applicationviewer
    flib.h
    ${qresources}
    )

include_directories(${OPENGL_INCLUDE_DIR})

target_link_libraries(hedgewars Qt5::Core Qt5::Gui Qt5::Quick Qt5::Qml)
install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})
