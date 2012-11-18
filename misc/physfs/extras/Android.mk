LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := physfsrwops

LOCAL_CFLAGS := -O2 -DPHYSFS_NO_CDROM_SUPPORT 

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../liblua $(LOCAL_PATH)/../src $(LOCAL_PATH)/../../../project_files/Android-build/SDL-android-project/jni/SDL/include

LOCAL_SRC_FILES := hwpacksmounter.c \
                   physfslualoader.c \
                   physfsrwops.c   

LOCAL_SHARED_LIBRARIES := SDL physfs
    
include $(BUILD_SHARED_LIBRARY)
