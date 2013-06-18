#ifndef HEDGEWARS_PACKAGES_MOUNTER_H
#define HEDGEWARS_PACKAGES_MOUNTER_H

#include "physfs.h"

#ifndef STRINIT
#include "lua.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

PHYSFS_DECL void hedgewarsMountPackages();
PHYSFS_DECL void hedgewarsMountPackage(char * fileName);

PHYSFS_DECL const char * physfsReader(lua_State *L, PHYSFS_File *f, size_t *size);
PHYSFS_DECL void physfsReaderSetBuffer(void *buffer);

#ifdef __cplusplus
}
#endif

#endif
