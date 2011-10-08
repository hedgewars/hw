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
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
###################################################################################




###################################################################################
# Uncomment (remove the leading '#') and change the paths accordingly to your own 
# build environment, please do specify an absolute path (/home/richard/SoftDev    
# rather than ~/SoftDev).
# You only need to change the three lines below, after that you can run 'cmake .'
# from the hedgewars root directory
# 
# optionally you can specify SDL_DIR this will move the required SDL libraries to
# the correct place
##################################################################################

set(ANDROID_NDK /home/richard/SoftDev/android/android-ndk-r5b)
set(ANDROID_SDK /home/richard/SoftDev/android/android-sdk-linux_86)
set(FPC_DIR /home/richard/SoftDev/fpc-2.4.4)
set(SDL_DIR /home/richard/Downloads/android-project)

if(ANDROID_NDK AND ANDROID_SDK AND FPC_DIR)

    set(ANDROID_SDK_API_LVL 8)
    set(ANDROID_NDK_API_LVL 5)

    MESSAGE("Creating android scripts and configuration files")

    configure_file(Templates/complete_build.sh .)
    configure_file(Templates/default.properties SDL-android-project/)
    configure_file(Templates/local.properties SDL-android-project/)
    configure_file(Templates/Makefile.android .)
    configure_file(Templates/pushToDevice.sh .)

    if(SDL_DIR)

        MESSAGE("Moving Android port of SDL to the proper directories")

        set(DirsToCopy
            SDL
	    SDL_image
            SDL_mixer
            SDL_ttf
	    jpeg
	    png
            mikmod
           ) 
         foreach(DIR ${DirsToCopy})
             exec_program( 
	        ${CMAKE_COMMAND} 
                ARGS -E copy_directory 
	        ${SDL_DIR}/jni/${DIR}
	        ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/${DIR}
        	)
             MESSAGE("Moved ${DIR}")
         endforeach(DIR)
        exec_program(${HGCOMMAND}
	            ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/core/android/SDL_android.cpp
		    )
        exec_program(${HGCOMMAND}
		    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/main/android/SDL_android_main.cpp
		    )
        exec_program(${HGCOMMAND}
		    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/video/android/SDL_androidtouch.c
		    )

        exec_program(${HGCOMMAND}
		    ARGS revert ${CMAKE_CURRENT_SOURCE_DIR}/SDL-android-project/jni/SDL/src/video/android/SDL_androidtouch.h
		    )


    else(SDL_DIR)
        MESSAGE("Android port of SDL not moved..")
    endif(SDL_DIR)

 
else(ANDROID_AND AND ANDROID_SDK AND FPC_DIR)
    MESSAGE("Android port files not created, edit top of ${CMAKE_CURRENT_SOURCE_DIR}/CMakeList.txt to create android specific files")
endif(ANDROID_NDK AND ANDROID_SDK AND FPC_DIR)


