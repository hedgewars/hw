set(ANDROID_NDK /home/richard/SoftDev/android/android-ndk-r5b)
set(ANDROID_SDK /home/richard/SoftDev/android/android-sdk-linux_86)
set(FPC_DIR /home/richard/SoftDev/fpc-2.4.4)
set(ANDROID_SDK_API_LVL 8)
set(ANDROID_NDK_API_LVL 5)

configure_file(Templates/complete_build.sh .)
configure_file(Templates/default.properties SDL-android-project/)
configure_file(Templates/local.properties SDL-android-project/)
configure_file(Templates/default.properties DataPackage/)
configure_file(Templates/local.properties DataPackage/)
configure_file(Templates/Makefile.android .)
configure_file(Templates/pushToDevice.sh .)

set(PREFERED_DIRS 
    Sounds
    Music
)
set(DIRS
    Fonts
    Forts
    Graphics
    Locale
    Maps
    misc
    Missions
    Names
    Scripts
    Themes
)
set(PREFERED_DIRS_PREFIX ../../../../Data)
set(DIRS_PREFIX ../../../../../share/hedgewars/Data)

if(CMAKE_HOST_WIN32) #Copy the asset files to the proper folder when using windows
    set(OPERATION copy_directory)
else(CMAKE_HOST_WIN32)#If it isn't windows we can assume it's unix/darwin which supports symlinks
    set(OPERATION create_symlink)
endif(CMAKE_HOST_WIN32)#We can make the above assumption because the android ndk/sdk only support Linux/Windows/Mac

#Copy or symlink the smaller sized resources first
foreach(DIR ${PREFERED_DIRS})
        EXECUTE_PROCESS(COMMAND "${CMAKE_COMMAND}"
            -E 
            ${OPERATION}
            ${PREFERED_DIRS_PREFIX}/${DIR}
            DataPackage/assets/Data/${DIR} 
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
endforeach(DIR)

#Use the global resources second
foreach(DIR ${DIRS})
         EXECUTE_PROCESS(COMMAND "${CMAKE_COMMAND}"
            -E 
            ${OPERATION} 
            ${DIRS_PREFIX}/${DIR}
            DataPackage/assets/Data/${DIR} 
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
         )
endforeach(DIR)
