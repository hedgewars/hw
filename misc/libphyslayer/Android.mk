LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := physlayer

LOCAL_CFLAGS := -O2

LOCAL_C_INCLUDES := $(LOCAL_PATH) $(MISC_DIR)/liblua $(MISC_DIR)/liblua $(JNI_DIR)/SDL/include

LOCAL_SRC_FILES := hwpacksmounter.c \
                   physfslualoader.c \
                   physfsrwops.c \

LOCAL_SHARED_LIBRARIES += SDL lua

include $(BUILD_SHARED_LIBRARY)
