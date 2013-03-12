#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "hwpacksmounter.h"

PHYSFS_DECL void hedgewarsMountPackages()
{
    char ** filesList = PHYSFS_enumerateFiles("/");
    char **i;

    for (i = filesList; *i != NULL; i++)
    {
        char * fileName = *i;
        int fileNameLength = strlen(fileName);
        if (fileNameLength > 4)
            if (strcmp(fileName + fileNameLength - 4, ".hwp") == 0)
            {
                const char * dir = PHYSFS_getRealDir(fileName);
                if(dir)
                {
                    char * fullPath = (char *)malloc(strlen(dir) + fileNameLength + 2);
                    strcpy(fullPath, dir);
                    strcat(fullPath, "/");
                    strcat(fullPath, fileName);

                    PHYSFS_mount(fullPath, NULL, 0);

                    free(fullPath);
                }
            }
    }

    PHYSFS_freeList(filesList);
}
