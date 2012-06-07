/**
 * Data structures for game scheme information.
 *
 * Important conventions:
 * - All data structures own what they point to.
 * - Strings are never null pointers.
 */

#ifndef CFG_H_
#define CFG_H_

#include <stdbool.h>

typedef struct {
    char *iniName;
    char *title;
    char *engineCommand;
    char *image;
    int netplayIndex;
    bool checkOverMax;
    bool times1000;
    int def;
    int min;
    int max;
} flib_cfg_setting_meta;

typedef struct {
    char *iniName;
    int bitmaskIndex;
} flib_cfg_mod_meta;

typedef struct {
    int settingCount;
    int modCount;
    flib_cfg_setting_meta *settings;
    flib_cfg_mod_meta *mods;
} flib_cfg_meta;

typedef struct {
    int settingCount;
    int modCount;
    char *schemeName;
    int *settings;
    bool *mods;
} flib_cfg;

flib_cfg_meta *flib_cfg_meta_from_ini(const char *settingpath, const char *modpath);
void flib_cfg_meta_destroy(flib_cfg_meta *metainfo);

flib_cfg *flib_cfg_create(const flib_cfg_meta *meta, const char *schemeName);
flib_cfg *flib_cfg_from_ini(const flib_cfg_meta *meta, const char *filename);
int flib_cfg_to_ini(const flib_cfg_meta *meta, const char *filename, const flib_cfg *config);
void flib_cfg_destroy(flib_cfg* cfg);

#endif /* CFG_H_ */
