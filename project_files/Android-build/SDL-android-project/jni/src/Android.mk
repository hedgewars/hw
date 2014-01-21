LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := main

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../SDL/include

# Add your application source files here...
LOCAL_SRC_FILES := ../SDL/src/main/android/SDL_android_main.cpp hedgewars_main.c

LOCAL_SHARED_LIBRARIES := SDL

LOCAL_LDLIBS := -llog -lGLESv1_CM

include $(BUILD_SHARED_LIBRARY)

