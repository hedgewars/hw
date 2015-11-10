LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := frontlib

LOCAL_CFLAGS := -I$(LOCAL_PATH)/../Android-build/SDL-android-project/jni/SDL_net -std=c99 -I$(LOCAL_PATH)/../Android-build/SDL-android-project/jni/SDL/include

LOCAL_SRC_FILES := base64/base64.c iniparser/iniparser.c \
    iniparser/dictionary.c ipc/gameconn.c ipc/ipcbase.c \
    ipc/ipcprotocol.c ipc/mapconn.c md5/md5.c model/scheme.c \
    model/gamesetup.c model/map.c model/mapcfg.c model/room.c \
    model/schemelist.c model/team.c model/teamlist.c model/weapon.c \
    net/netbase.c net/netconn_callbacks.c net/netconn_send.c \
    net/netconn.c net/netprotocol.c util/buffer.c util/inihelper.c \
    util/logging.c util/util.c frontlib.c hwconsts.c socket.c \
    extra/jnacontrol.c

LOCAL_SHARED_LIBRARIES += SDL SDL_net
LOCAL_LDLIBS += -lz

include $(BUILD_SHARED_LIBRARY)
