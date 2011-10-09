#Set the current path must be set like this because call all-subdir-makefiles changes LOCAL_PATH
JNI_DIR  := $(call my-dir)
LOCAL_PATH := $(JNI_DIR)

include $(call all-subdir-makefiles)

include $(CLEAR_VARS)
include $(JNI_DIR)/../../../../misc/Android.mk


