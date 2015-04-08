#ifndef FLIB_H
#define FLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum MessageType {
    MSG_PREVIEW
    , MSG_ADDPLAYINGTEAM
    , MSG_REMOVEPLAYINGTEAM
    , MSG_ADDTEAM
    , MSG_REMOVETEAM
    , MSG_TEAMCOLOR
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
typedef void registerGUIMessagesCallback_t(void * context, void (*)(void * context, MessageType mt, const char * msg, uint32_t len));
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

#ifdef __cplusplus
}
#endif

#endif // FLIB_H
