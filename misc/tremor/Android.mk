LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := tremor

LOCAL_CFLAGS := -I$(LOCAL_PATH) -DHAVE_ALLOCA_H

LOCAL_SRC_FILES =    \
        bitwise.c    \
        block.c      \
        codebook.c   \
        floor0.c     \
        floor1.c     \
        framing.c    \
        info.c       \
        mapping0.c   \
        mdct.c       \
        registry.c   \
        res012.c     \
        sharedbook.c \
        synthesis.c  \
        vorbisfile.c \
        window.c     

include $(BUILD_STATIC_LIBRARY)

