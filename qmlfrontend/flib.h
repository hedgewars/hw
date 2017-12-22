#ifndef FLIB_H
#define FLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum MessageType {
    MSG_RENDERINGPREVIEW
    , MSG_PREVIEW
    , MSG_PREVIEWHOGCOUNT
    , MSG_ADDPLAYINGTEAM
    , MSG_REMOVEPLAYINGTEAM
    , MSG_ADDTEAM
    , MSG_REMOVETEAM
    , MSG_TEAMCOLOR
    , MSG_HEDGEHOGSNUMBER
    , MSG_NETDATA
    , MSG_TONET
    , MSG_FLIBEVENT
    , MSG_CONNECTED
    , MSG_DISCONNECTED
    , MSG_ADDLOBBYCLIENT
    , MSG_REMOVELOBBYCLIENT
    , MSG_LOBBYCHATLINE
    , MSG_ADDROOMCLIENT
    , MSG_REMOVEROOMCLIENT
    , MSG_ROOMCHATLINE
    , MSG_ADDROOM
    , MSG_UPDATEROOM
    , MSG_REMOVEROOM
    , MSG_ERROR
    , MSG_WARNING
    , MSG_MOVETOLOBBY
    , MSG_MOVETOROOM
    , MSG_NICKNAME
    , MSG_SEED
    , MSG_THEME
    , MSG_SCRIPT
    , MSG_FEATURESIZE
    , MSG_MAPGEN
    , MSG_MAP
    , MSG_MAZESIZE
    , MSG_TEMPLATE
    , MSG_AMMO
    , MSG_SCHEME
};

typedef union string255_
    {
        struct {
            unsigned char s[256];
        };
        struct {
            unsigned char len;
            unsigned char str[255];
        };
    } string255;

typedef void RunEngine_t(int argc, const char ** argv);
typedef void registerUIMessagesCallback_t(void * context, void (*)(void * context, MessageType mt, const char * msg, uint32_t len));
typedef void flibInit_t(const char * localPrefix, const char * userPrefix);
typedef void flibFree_t();
typedef void passFlibEvent_t(const char * data);

#ifdef __cplusplus
}
#endif

#endif // FLIB_H
