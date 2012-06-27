/*
 * Data structure and functions for accessing the map.cfg of named maps.
 */

#ifndef MAPCFG_H_
#define MAPCFG_H_

typedef struct {
	char theme[256];
	int hogLimit;
} flib_mapcfg;

/**
 * Read the map configuration for the map with this name.
 * The dataDirPath must end in a path separator.
 */
int flib_mapcfg_read(const char *dataDirPath, const char *mapname, flib_mapcfg *out);

#endif /* MAPCFG_H_ */
