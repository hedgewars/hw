LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := physfs

LOCAL_CFLAGS := -O2 -DPHYSFS_NO_CDROM_SUPPORT 

LOCAL_C_INCLUDES := $(LOCAL_PATH) $(MISC_DIR)/liblua $(MISC_DIR)/liblua $(JNI_DIR)/SDL/include

LOCAL_SRC_FILES :=    physfs.c \
    physfs_byteorder.c \
    physfs_unicode.c \
    platform_posix.c \
    platform_unix.c \
    platform_macosx.c \
    platform_windows.c \
    archiver_dir.c \
    archiver_grp.c \
    archiver_hog.c \
    archiver_lzma.c \
    archiver_mvl.c \
    archiver_qpak.c \
    archiver_wad.c \
    archiver_zip.c \
    ../extras/hwpacksmounter.c \
    ../extras/physfslualoader.c \
    ../extras/physfsrwops.c \

LOCAL_SHARED_LIBRARIES += SDL lua
    
include $(BUILD_SHARED_LIBRARY)
