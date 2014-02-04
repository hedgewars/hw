###################################################################################
# Hedgewars, a free turn based strategy game
# Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
###################################################################################

find_program(ANT ant DOC "Path to the java package creator: ant")
if(NOT EXISTS ${ANT})
    message(FATAL_ERROR "Couldn't detect the Ant build tool")
endif()

if(NOT ANDROID_NDK)
    find_path(ANDROID_NDK ndk-build)
endif()

if(IS_DIRECTORY "${ANDROID_NDK}")
    message(STATUS "Detected the android NDK directory at: " ${ANDROID_NDK})
else()
    message(FATAL_ERROR "Couldn't detect the Android NDK directory")
endif()

if(NOT ANDROID_NDK_TOOLCHAINDIR)
    set(toolchainbase "${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.6/prebuilt")
    find_path(ANDROID_NDK_TOOLCHAINDIR arm-linux-androideabi
                "${toolchainbase}/linux-x86"
                "${toolchainbase}/windows")
endif()

if(IS_DIRECTORY "${ANDROID_NDK_TOOLCHAINDIR}")
    message(STATUS "Detected the Android NDK toolchain at: ${ANDROID_NDK_TOOLCHAINDIR}")
else()
    message(FATAL_ERROR "Couldn't detect the Android NDK toolchain directory: ${ANDROID_NDK_TOOLCHAINDIR}")
endif()

if(NOT ANDROID_SDK) #Check if its defined at the cmdline
    find_program(ANDROID_SDK adb) #assume they've added platform-tools to their path
    get_filename_component(ANDROID_SDK "${ANDROID_SDK}" PATH)
    get_filename_component(ANDROID_SDK "${ANDROID_SDK}" PATH)
    set(ANDROID_SDK "${ANDROID_SDK}" CACHE PATH "Path to the android sdk" FORCE)
endif()

if(IS_DIRECTORY "${ANDROID_SDK}")
    message(STATUS "Detected the android SDK directory at: " ${ANDROID_SDK})
else()
    message(FATAL_ERROR "Couldn't detect the Android SDK directory")
endif()

if(NOT FPC_DIR)
    find_program(FPC_DIR ppcrossarm)
    get_filename_component(FPC_DIR "${FPC_DIR}" PATH)
    if(IS_DIRECTORY "${FPC_DIR}")
        set(FPC_DIR "${FPC_DIR}" CACHE PATH "Path to fpc dir used in the android port" FORCE)
    endif()
endif()

if(IS_DIRECTORY "${FPC_DIR}")
    message(STATUS "Detected the FreePascal directory at: ${FPC_DIR}")
else()
    message(FATAL_ERROR "Couldn't detect the FreePascal directory")
endif()

set(SDL_DIR /home/richard/Downloads/android-project)


set(ANDROID_SDK_API_LVL 16)
set(ANDROID_NDK_API_LVL 5)

message(STATUS "Creating Makefile.android...")

configure_file(Templates/Makefile.android .)

find_program(ANDROID_EXEC NAMES android android.bat PATHS "${ANDROID_SDK}/platform-tools" "${ANDROID_SDK}/tools")
if(ANDROID_EXEC)
    exec_program(${ANDROID_EXEC}
                 ARGS "update project"
                 "--path ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project"
                 "--target android-${ANDROID_SDK_API_LVL}"
                 OUTPUT_VARIABLE androidoutput
                )
    message(STATUS "Updating android project config...\n" ${androidoutput})
else()
    message(FATAL_ERROR "Couldn't find the android executable in ${ANDROID_SDK}/platform-tools or ${ANDROID_SDK}/tools.")
endif()

##
# FIXME: this was useful for early version of SDL 1.3 so is most likely not needed anymore
#        if so delete the files referenced here from the repository
#        commenting out because it inteferes with SDL 2 builds
##
#exec_program(${HGCOMMAND}
#    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/core/android/SDL_android.cpp
#    OUTPUT_VARIABLE dontcare
#)
#exec_program(${HGCOMMAND}
#    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/main/android/SDL_android_main.cpp
#    OUTPUT_VARIABLE dontcare
#)
#exec_program(${HGCOMMAND}
#    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/file/SDL_rwops.c
#    OUTPUT_VARIABLE dontcare
#)
#exec_program(${HGCOMMAND}
#    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL_mixer/Android.mk
#    OUTPUT_VARIABLE dontcare
#)
#exec_program(${HGCOMMAND}
#    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL_ttf/Android.mk
#    OUTPUT_VARIABLE dontcare
#)

