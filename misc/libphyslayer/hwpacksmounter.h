#ifndef HEDGEWARS_PACKAGES_MOUNTER_H
#define HEDGEWARS_PACKAGES_MOUNTER_H

#include "physfs.h"
#include "physfscompat.h"

#ifndef PAS2C
#ifndef QT_VERSION
#include "lua.h"
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

PHYSFS_DECL void hedgewarsMountPackages();
PHYSFS_DECL void hedgewarsMountPackage(char * fileName);

#ifndef QT_VERSION
PHYSFS_DECL const char * physfsReader(lua_State *L, PHYSFS_File *f, size_t *size);
#endif
PHYSFS_DECL void physfsReaderSetBuffer(void *buffer);

#ifdef __cplusplus
}
#endif

#endif
