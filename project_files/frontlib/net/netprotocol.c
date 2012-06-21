#include "netprotocol.h"

#include "../util/util.h"
#include "../util/logging.h"

#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

static int fillTeamFromMsg(flib_team *team, char **parts) {
	team->name = flib_strdupnull(parts[0]);
	team->grave = flib_strdupnull(parts[2]);
	team->fort = flib_strdupnull(parts[3]);
	team->voicepack = flib_strdupnull(parts[4]);
	team->flag = flib_strdupnull(parts[5]);
	if(!team->name || !team->grave || !team->fort || !team->voicepack || !team->flag) {
		return -1;
	}

	long color;
	if(sscanf(parts[1], "#%lx", &color)) {
		team->color = color;
	} else {
		return -1;
	}

	errno = 0;
	long difficulty = strtol(parts[6], NULL, 10);
	if(errno) {
		return -1;
	}

	for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
		flib_hog *hog = &team->hogs[i];
		hog->difficulty = difficulty;
		hog->name = flib_strdupnull(parts[7+2*i]);
		hog->hat = flib_strdupnull(parts[8+2*i]);
		if(!hog->name || !hog->hat) {
			return -1;
		}
	}
	return 0;
}

flib_team *flib_team_from_netmsg(char **parts) {
	flib_team *result = NULL;
	flib_team *tmpTeam = flib_calloc(1, sizeof(flib_team));
	if(tmpTeam) {
		if(!fillTeamFromMsg(tmpTeam, parts)) {
			result = tmpTeam;
			tmpTeam = NULL;
		} else {
			flib_log_e("Error parsing team from net.");
		}
	}
	flib_team_destroy(tmpTeam);
	return result;
}
