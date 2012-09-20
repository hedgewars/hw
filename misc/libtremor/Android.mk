LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := tremor

LOCAL_CFLAGS := -I$(LOCAL_PATH) -DHAVE_ALLOCA_H

LOCAL_SRC_FILES =    \
    tremor/bitwise.c             tremor/info.c             tremor/codebook.c \
    tremor/dsp.c                 tremor/mapping0.c \
    tremor/floor0.c              tremor/mdct.c \
    tremor/floor1.c              tremor/misc.c \
    tremor/floor_lookup.c        tremor/res012.c \
    tremor/framing.c             tremor/vorbisfile.c

include $(BUILD_STATIC_LIBRARY)

