find_package(Qt5 COMPONENTS Core Widgets Gui Network)

include_directories(${Qt5Core_PRIVATE_INCLUDE_DIRS})

include(CheckLibraryExists)

find_package(SDL2 REQUIRED)
find_package(SDL2_mixer 2 REQUIRED) #audio in SDLInteraction
include_directories(${SDL2_INCLUDE_DIR})
include_directories(${SDL2_MIXER_INCLUDE_DIRS})

if(LIBAV_FOUND)
    add_definitions(-DVIDEOREC -D__STDC_CONSTANT_MACROS)
    include_directories(${LIBAV_INCLUDE_DIR})
    list(APPEND HW_LINK_LIBS ${LIBAV_LIBRARIES})
endif()

# server messages localization
file(GLOB ServerSources ${CMAKE_SOURCE_DIR}/gameServer/*.hs)
foreach(hsfile ${ServerSources})
    file(READ ${hsfile} hs)
    string(REGEX MATCHALL "loc *\"[^\n\"]+\"" locs ${hs})
    foreach(str ${locs})
        string(REGEX REPLACE "loc *\"([^\n\"]+)\"" "QT_TRANSLATE_NOOP(\"server\", \"\\1\")" s ${str})
        list(APPEND serverlocs ${s})
    endforeach(str)
endforeach(hsfile)

list(REMOVE_DUPLICATES serverlocs)
list(GET serverlocs 0 firstline)
list(REMOVE_AT serverlocs 0)
set(locsout "const char * serverMessages[] = {\n")
foreach(l ${serverlocs})
    list(APPEND locsout ${l} ",\n")
endforeach(l)
list(APPEND locsout ${firstline} "\n}\\;\n")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/servermessages.h ${locsout})

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/model)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/net)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/dialog)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/page)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/widget)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/util)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/util/platform)
include_directories(BEFORE ${PHYSFS_INCLUDE_DIR})
include_directories(BEFORE ${PHYSLAYER_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR}) #brought by physlayer hwpacksmounter.h

if(UNIX)
    # HACK: in freebsd cannot find iconv.h included via SDL.h
    include_directories("/usr/local/include")
endif(UNIX)

#only the cocoa version of qt supports building 64 bit apps
if(APPLE AND (CMAKE_OSX_ARCHITECTURES MATCHES "x86_64*") AND (NOT QT_MAC_USE_COCOA))
    message(FATAL_ERROR "Building the 64 bit version of Hedgewars *requires* the Cocoa variant of QT on Mac OS X")
endif()
#endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/hwconsts.cpp.in ${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp)

file(GLOB NetCpp net/*.cpp)
file(GLOB ModelCpp model/*.cpp)
file(GLOB_RECURSE UIcpp ui/*.cpp)
file(GLOB UtilCpp util/*.cpp)

list(APPEND hwfr_src
    ${ModelCpp}
    ${NetCpp}
    ${UIcpp}
    ${UtilCpp}
    achievements.cpp
    binds.cpp
    drawmapscene.cpp
    game.cpp
    gameuiconfig.cpp
    HWApplication.cpp
    hwform.cpp
    main.cpp
    team.cpp
    campaign.cpp
    ui_hwform.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp
    )

if(MINGW)
    # resource compilation for mingw
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o
                       COMMAND windres -I ${CMAKE_CURRENT_SOURCE_DIR}
                               -i ${CMAKE_CURRENT_SOURCE_DIR}/hedgewars.rc
                               -o ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
    list(APPEND hwfr_src ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
else(MINGW)
    list(APPEND hwfr_src hedgewars.rc)
endif(MINGW)

file(GLOB ModelHdr model/*.h)
file(GLOB NetHdr net/*.h)
file(GLOB_RECURSE UIhdr ui/*.h)
file(GLOB UtilHdr util/*.h)


set(hwfr_moc_hdrs
    ${ModelHdr}
    ${NetHdr}
    ${UIhdr}
    drawmapscene.h
    game.h
    gameuiconfig.h
    HWApplication.h
    hwform.h
    team.h
    util/DataManager.h
    util/LibavInteraction.h
    )

set(hwfr_hdrs
    ${UtilHdr}
    team.h
    achievements.h
    binds.h
    ui_hwform.h
    hwconsts.h
    sdlkeys.h
    campaign.h
    ${CMAKE_CURRENT_BINARY_DIR}/servermessages.h
    )

set(hwfr_rez hedgewars.qrc)

if(BUILD_ENGINE_LIBRARY)
    add_definitions(-DHWLIBRARY=1)
    set(hwlibname "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    list(APPEND HW_LINK_LIBS ${hwlibname})

    if(LIBAV_FOUND)
#        add_subdirectory(avwrapper)
        list(APPEND HW_LINK_LIBS avwrapper)
    endif()
endif()

qt5_add_resources(hwfr_rez_src ${hwfr_rez})

qt5_wrap_cpp(hwfr_moc_srcs ${hwfr_moc_hdrs})


if(APPLE)
    find_library(iokit_framework NAMES IOKit)
    list(APPEND HW_LINK_LIBS ${iokit_framework})
    list(APPEND hwfr_src util/platform/CocoaInitializer.mm
                         util/platform/InstallController.cpp
                         util/platform/M3Panel.mm
                         util/platform/M3InstallController.m
                         util/platform/NSWorkspace_RBAdditions.m
                         )
    include(${CMAKE_MODULE_PATH}/utils.cmake)
    find_package_or_disable_msg(Sparkle NOAUTOUPDATE "Autoupdater will not be built.")
    if(SPARKLE_FOUND)
        add_definitions(-DSPARKLE_ENABLED)
        list(APPEND hwfr_src util/platform/AutoUpdater.cpp
                             util/platform/SparkleAutoUpdater.mm)
        list(APPEND HW_LINK_LIBS ${SPARKLE_LIBRARY})
    endif()
endif()

#when debugging, always prompt a console to see fronted messages
#TODO: check it doesn't interfere on UNIX
if(CMAKE_BUILD_TYPE MATCHES "RELEASE" OR CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO")
    set(console_access "WIN32")
endif(CMAKE_BUILD_TYPE MATCHES "RELEASE" OR CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO")

add_executable(hedgewars ${console_access}
    ${hwfr_src}
    ${hwfr_moc_srcs}
    ${hwfr_hdrs}
    ${hwfr_rez_src}
    )

list(APPEND HW_LINK_LIBS
    physfs physlayer
    Qt5::Core Qt5::Widgets Qt5::Gui Qt5::Network
    )

list(APPEND HW_LINK_LIBS
    ${SDL2_LIBRARY}
    ${SDL2_MIXER_LIBRARIES}
    )

if(WIN32 AND NOT UNIX)
    if(NOT SDL2_LIBRARY)
        list(APPEND HW_LINK_LIBS SDL2)
    endif()

    list(APPEND HW_LINK_LIBS
        ole32
        oleaut32
        winspool
        uuid
        )
endif()

if(CMAKE_CXX_COMPILER MATCHES "clang*")
    list(APPEND HW_LINK_LIBS stdc++ m)
endif()

target_link_libraries(hedgewars ${HW_LINK_LIBS})


install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})

