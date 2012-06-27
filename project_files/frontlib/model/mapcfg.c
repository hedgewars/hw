#include "mapcfg.h"

#include "../util/util.h"
#include "../util/logging.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

void removeNewline(char *str) {
	for(;*str;str++) {
		if(*str=='\n' || *str=='\r') {
			*str = 0;
			return;
		}
	}
}

int flib_mapcfg_read(const char *dataDirPath, const char *mapname, flib_mapcfg *out) {
	int result = -1;
	if(!log_badparams_if(!dataDirPath || !mapname || !out)
			&& !log_e_if(flib_contains_dir_separator(mapname), "Illegal character in mapname %s", mapname)) {
		char *path = flib_asprintf("%sMaps/%s/map.cfg", dataDirPath, mapname);
		if(path) {
			FILE *file = fopen(path, "rb");
			if(!log_e_if(!file, "Unable to open map config file %s", path)) {
				if(!log_e_if(!fgets(out->theme, sizeof(out->theme), file), "Error reading theme from %s", path)) {
					removeNewline(out->theme);
					char buf[64];
					if(!log_e_if(!fgets(buf, sizeof(buf), file), "Error reading hoglimit from %s", path)) {
						removeNewline(buf);
						errno = 0;
						out->hogLimit = strtol(buf, NULL, 10);
						result = !log_e_if(errno, "Invalid hoglimit in %s: %i", path, buf);
					}
				}
				fclose(file);
			}
		}
		free(path);
	}
	return result;
}
