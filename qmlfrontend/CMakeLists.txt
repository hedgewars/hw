cmake_minimum_required(VERSION 2.8.12)

project(qmlfrontend LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt5 COMPONENTS Core Quick REQUIRED)

add_executable(${PROJECT_NAME} "main.cpp" "qml.qrc"
    "hwengine.cpp" "hwengine.h"
    "game_config.cpp" "game_config.h"
    "game_view.cpp" "game_view.h"
    "team.cpp" "team.h"
    "engine_instance.cpp" "engine_instance.h"
    "preview_image_provider.cpp" "preview_image_provider.h"
    "engine_interface.h")

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Quick)
