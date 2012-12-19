# Configure for Qt4
set(QT_MIN_VERSION "4.5.0")
include(CheckLibraryExists)

set(QT_USE_QTCORE TRUE)
set(QT_USE_QTGUI TRUE)
set(QT_USE_QTNETWORK TRUE)
set(QT_USE_QTSVG FALSE)
set(QT_USE_QTXML FALSE)
set(QT_USE_QTOPENGL FALSE)
set(QT_USE_QTMAIN TRUE)

find_package(Qt4 REQUIRED)
if (NOT CROSSAPPLE)
    include(${QT_USE_FILE})
endif()

find_package(SDL REQUIRED)       #video in SDLInteraction
find_package(SDL_mixer REQUIRED) #audio in SDLInteraction
find_package(SDL_net REQUIRED)   #network frontlib
if(NOT NOVIDEOREC)
    find_package(FFMPEG)
    if(${FFMPEG_FOUND})
        add_definitions(-DVIDEOREC -D__STDC_CONSTANT_MACROS)
    endif()
endif()

include_directories(.)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/model)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/net)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/dialog)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/page)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ui/widget)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/util)
include_directories(${SDL_INCLUDE_DIR})
include_directories(${SDLMIXER_INCLUDE_DIR})
include_directories(${FFMPEG_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/misc/physfs/src)
include_directories(${CMAKE_SOURCE_DIR}/misc/physfs/extras)
if(UNIX)
    # HACK: in freebsd cannot find iconv.h included via SDL.h
    include_directories("/usr/local/include")
endif(UNIX)


if(WIN32 AND NOT UNIX)
    set(HEDGEWARS_BINDIR ".")
    set(HEDGEWARS_DATADIR "../share/")
    add_definitions(-DUSE_XFIRE)
else()
    set(HEDGEWARS_BINDIR ${CMAKE_INSTALL_PREFIX})
    if(DEFINED DATA_INSTALL_DIR)
        set(HEDGEWARS_DATADIR ${DATA_INSTALL_DIR})
    else()
        set(HEDGEWARS_DATADIR ${CMAKE_INSTALL_PREFIX}/share/)
    endif()
    #only the cocoa version of qt supports building 64 bit apps
    if(APPLE AND (CMAKE_OSX_ARCHITECTURES MATCHES "x86_64*") AND (NOT QT_MAC_USE_COCOA))
        message(FATAL_ERROR "Building the 64 bit version of Hedgewars *requires* the Cocoa variant of QT on Mac OS X")
    endif()
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/hwconsts.cpp.in ${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp)

file(GLOB NetCpp net/*.cpp)
file(GLOB ModelCpp model/*.cpp)
file(GLOB_RECURSE UIcpp ui/*.cpp)
file(GLOB UtilCpp util/*.cpp)

set(hwfr_src
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

#xfire integration
if(WIN32)
    set(hwfr_src ${hwfr_src} xfire.cpp ../misc/xfire/xfiregameclient.cpp)
endif(WIN32)

if(MINGW)
    # resource compilation for mingw
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o
                       COMMAND windres -I ${CMAKE_CURRENT_SOURCE_DIR}
                               -i ${CMAKE_CURRENT_SOURCE_DIR}/hedgewars.rc
                               -o ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
    set(hwfr_src ${hwfr_src} ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
else(MINGW)
    set(hwfr_src ${hwfr_src} hedgewars.rc)
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
    )

set(hwfr_rez hedgewars.qrc)

if(BUILD_ENGINE_LIBRARY)
    add_definitions(-DHWLIBRARY=1)
    set(hwlibname "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(HW_LINK_LIBS ${hwlibname} ${HW_LINK_LIBS})
endif()

qt4_add_resources(hwfr_rez_src ${hwfr_rez})

qt4_wrap_cpp(hwfr_moc_srcs ${hwfr_moc_hdrs})


if(APPLE OR CROSSAPPLE)
    find_library(iokit_framework NAMES IOKit)
    set(HW_LINK_LIBS ${iokit_framework} ${HW_LINK_LIBS})
    set(hwfr_src ${hwfr_src} CocoaInitializer.mm
                             InstallController.cpp
                             M3Panel.mm
                             M3InstallController.m
                             NSWorkspace_RBAdditions.m
                             )
    if(NOT NOAUTOUPDATE)
        find_package(Sparkle)
        if(SPARKLE_FOUND)
            add_definitions(-DSPARKLE_ENABLED)
            set(hwfr_src ${hwfr_src} AutoUpdater.cpp SparkleAutoUpdater.mm)
            set(HW_LINK_LIBS ${SPARKLE_LIBRARY} ${HW_LINK_LIBS})
        endif()
    endif()
endif()

#when debugging, always prompt a console to see fronted messages
#TODO: check it doesn't interfere on UNIX
if(CMAKE_BUILD_TYPE MATCHES "RELEASE")
    set(console_access "WIN32")
endif(CMAKE_BUILD_TYPE MATCHES "RELEASE")

add_executable(hedgewars ${console_access}
    ${hwfr_src}
    ${hwfr_moc_srcs}
    ${hwfr_hdrs}
    ${hwfr_rez_src}
    )


set(HW_LINK_LIBS
    physfs
    ${QT_LIBRARIES}
    ${SDL_LIBRARY}
    ${SDLMIXER_LIBRARY}
    ${FFMPEG_LIBRARIES}
    ${HW_LINK_LIBS}
    )

if(WIN32 AND NOT UNIX)
    if(NOT SDL_LIBRARY)
        set(HW_LINK_LIBS ${HW_LINK_LIBS} SDL)
    endif()

    set(HW_LINK_LIBS
        ${HW_LINK_LIBS}
        ole32
        oleaut32
        winspool
        uuid
        )
endif()


if (NOT CROSSAPPLE)
    target_link_libraries(hedgewars ${HW_LINK_LIBS})
endif()


install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})

