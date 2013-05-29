#ifndef HEDGEWARS_PACKAGES_MOUNTER_H
#define HEDGEWARS_PACKAGES_MOUNTER_H

#include "physfs.h"

#ifdef __cplusplus
extern "C" {
#endif

PHYSFS_DECL void hedgewarsMountPackages();
PHYSFS_DECL void hedgewarsMountPackage(char * fileName);

#ifdef __cplusplus
}
#endif

#endif
