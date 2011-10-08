#Set the current path
JNI_DIR  := $(call my-dir)
LOCAL_PATH := $(JNI_DIR)

include $(call all-subdir-makefiles)

include $(CLEAR_VARS)
include $(JNI_DIR)/../../../../misc/Android.mk


