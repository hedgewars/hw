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

PHYSFS_DECL void hedgewarsMountPackage(char * fileName)
{
    int fileNameLength = strlen(fileName);
    int dirLength = 0;
    if (fileNameLength > 4)
        if (strcmp(fileName + fileNameLength - 4, ".hwp") == 0)
        {
            const char * dir = PHYSFS_getRealDir(fileName);
            if(dir)
            {
				dirLength = strlen(dir);
				if (dirLength > 4)
				{
					if (strcmp(dir + dirLength - 4, ".hwp") == 0)
					{
#if PHYSFS_VER_MAJOR > 2 || PHYSFS_VER_MINOR > 0
						char * uniqName = (char *)malloc(strlen(dir) + fileNameLength + 2);
						strcpy(uniqName, dir);
						strcat(uniqName, ",");
						strcat(uniqName, fileName);
						PHYSFS_mountHandle(PHYSFS_openRead(fileName), uniqName, NULL, 0);
						free(uniqName);
#endif
					}
					else
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
        }
}
