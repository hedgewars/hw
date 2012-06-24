set(QT_USE_QTCORE TRUE)

find_package(Qt4 REQUIRED)
if(NOT CROSSAPPLE)
    include(${QT_USE_FILE})
endif()


file(GLOB SRCS "*.c" "*.cpp")
file(GLOB PUBLIC_HEADERS "*.h")
qt4_wrap_cpp(MOC_SRCS "quazipfile.h")
set(SRCS ${SRCS} ${MOC_SRCS})

add_library(quazip STATIC ${SRCS})
