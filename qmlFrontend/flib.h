#ifndef FLIB_H
#define FLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum MessageType {
    MSG_RENDERINGPREVIEW
    , MSG_PREVIEW
    , MSG_ADDPLAYINGTEAM
    , MSG_REMOVEPLAYINGTEAM
    , MSG_ADDTEAM
    , MSG_REMOVETEAM
    , MSG_TEAMCOLOR
    , MSG_NETDATA
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
typedef void getPreview_t();
typedef void runQuickGame_t();
typedef void runLocalGame_t();
typedef void resetGameConfig_t();
typedef void setSeed_t(const char * seed);
typedef char *getSeed_t();
typedef void setTheme_t(const char * themeName);
typedef void setScript_t(const char * scriptName);
typedef void setScheme_t(const char * schemeName);
typedef void setAmmo_t(const char * ammoName);
typedef void flibInit_t(const char * localPrefix, const char * userPrefix);
typedef void flibFree_t();
typedef void passNetData_t(const char * data);
typedef void passFlibEvent_t(const char * data);
typedef void sendChatLine_t(const char * msg);
typedef void joinRoom_t(const char * roomName);
typedef void partRoom_t(const char * message);

typedef char **getThemesList_t();
typedef void freeThemesList_t(char **list);
typedef uint32_t getThemeIcon_t(char * theme, char * buffer, uint32_t size);

typedef char **getScriptsList_t();
typedef char **getSchemesList_t();
typedef char **getAmmosList_t();

typedef char **getTeamsList_t();
typedef void tryAddTeam_t(const char * teamName);
typedef void tryRemoveTeam_t(const char * teamName);
typedef void changeTeamColor_t(const char * teamName, int32_t dir);

typedef void connectOfficialServer_t();

#ifdef __cplusplus
}
#endif

#endif // FLIB_H
