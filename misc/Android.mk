MISC_DIR   := $(call my-dir)
LOCAL_PATH := MISC_DIR

include $(MISC_DIR)/libfreetype/Android.mk
include $(MISC_DIR)/liblua/Android.mk
include $(MISC_DIR)/libtremor/Android.mk
