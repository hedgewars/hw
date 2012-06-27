#ifndef NETPROTOCOL_H_
#define NETPROTOCOL_H_

#include "../model/team.h"
#include "../model/cfg.h"
#include "../model/map.h"

#include <stddef.h>

/**
 * Create a new team from this 23-part net message
 */
flib_team *flib_team_from_netmsg(char **parts);

/**
 * Create a new scheme from this net message, which must have
 * meta->modCount+meta->settingCount+1 parts.
 */
flib_cfg *flib_netmsg_to_cfg(flib_cfg_meta *meta, char **parts);

/**
 * Create a new map from this five-part netmsg
 */
flib_map *flib_netmsg_to_map(char **parts);

/**
 * Decode the drawn map data from this netmessage line.
 *
 * The data is first base64 decoded and then quncompress()ed.
 * The return value is a newly allocated byte buffer, the length
 * is written to the variable pointed to by outlen.
 * Returns NULL on error.
 */
int flib_netmsg_to_drawnmapdata(char *netmsg, uint8_t **outbuf, size_t *outlen);

#endif /* NETPROTOCOL_H_ */
