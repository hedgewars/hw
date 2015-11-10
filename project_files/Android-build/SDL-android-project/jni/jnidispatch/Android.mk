LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libjnidispatch
LOCAL_SRC_FILES := libjnidispatch.so
include $(PREBUILT_SHARED_LIBRARY)