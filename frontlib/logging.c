#include "logging.h"

char* flib_format_ip(uint32_t numip) {
	static char ip[16];
	snprintf(ip, 16, "%u.%u.%u.%u", numip>>24, (numip>>16)&0xff, (numip>>8)&0xff, numip&0xff);
	return ip;
}
