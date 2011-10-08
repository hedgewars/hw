LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := tremor

LOCAL_CFLAGS := -I$(LOCAL_PATH) -DHAVE_ALLOCA_H

# Note this simple makefile var substitution, you can find even simpler examples in different Android projects
LOCAL_SRC_FILES := $(notdir $(wildcard $(LOCAL_PATH)/*.c))

include $(BUILD_STATIC_LIBRARY)

