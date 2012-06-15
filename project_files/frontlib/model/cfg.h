/**
 * Data structures for game scheme information.
 */

#ifndef CFG_H_
#define CFG_H_

#include <stdbool.h>

// TODO: cfg/config -> scheme

typedef struct {
    char *name;
    char *engineCommand;
    bool maxMeansInfinity;
    bool times1000;
    int min;
    int max;
    int def;
} flib_cfg_setting_meta;

typedef struct {
    char *name;
    int bitmaskIndex;
} flib_cfg_mod_meta;

typedef struct {
	int _referenceCount;
	int settingCount;
	int modCount;
    flib_cfg_setting_meta *settings;
    flib_cfg_mod_meta *mods;
} flib_cfg_meta;

typedef struct {
	int _referenceCount;
    flib_cfg_meta *meta;

    char *schemeName;
    int *settings;
    bool *mods;
} flib_cfg;

/**
 * Read the meta-configuration from a .ini file (e.g. which settings exist,
 * what are their defaults etc.)
 *
 * Returns the meta-configuration or NULL.
 */
flib_cfg_meta *flib_cfg_meta_from_ini(const char *filename);

/**
 * Increase the reference count of the object. Call this if you store a pointer to it somewhere.
 * Returns the parameter.
 */
flib_cfg_meta *flib_cfg_meta_retain(flib_cfg_meta *metainfo);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_cfg_meta_release(flib_cfg_meta *metainfo);

/**
 * Create a new configuration with everything set to default or false
 * Returns NULL on error.
 */
flib_cfg *flib_cfg_create(flib_cfg_meta *meta, const char *schemeName);

/**
 * Create a copy of the scheme. Returns NULL on error or if NULL was passed.
 */
flib_cfg *flib_cfg_copy(flib_cfg *cfg);

/**
 * Increase the reference count of the object. Call this if you store a pointer to it somewhere.
 * Returns the parameter.
 */
flib_cfg *flib_cfg_retain(flib_cfg *cfg);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_cfg_release(flib_cfg* cfg);

#endif /* CFG_H_ */
