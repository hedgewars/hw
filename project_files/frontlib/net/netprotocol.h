#ifndef NETPROTOCOL_H_
#define NETPROTOCOL_H_

#include "../model/team.h"

/**
 * Create a new team from this 23-part net message
 */
flib_team *flib_team_from_netmsg(char **parts);


#endif /* NETPROTOCOL_H_ */
