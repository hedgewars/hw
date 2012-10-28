LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := tremor

LOCAL_CFLAGS := -I$(LOCAL_PATH) -DHAVE_ALLOCA_H

LOCAL_SRC_FILES =    \
        tremor/bitwise.c    \
        tremor/block.c      \
        tremor/codebook.c   \
        tremor/floor0.c     \
        tremor/floor1.c     \
        tremor/framing.c    \
        tremor/info.c       \
        tremor/mapping0.c   \
        tremor/mdct.c       \
        tremor/registry.c   \
        tremor/res012.c     \
        tremor/sharedbook.c \
        tremor/synthesis.c  \
        tremor/vorbisfile.c \
        tremor/window.c     

include $(BUILD_STATIC_LIBRARY)

