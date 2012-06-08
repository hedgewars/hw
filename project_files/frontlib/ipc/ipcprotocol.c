#include "ipcprotocol.h"
#include "../util.h"
#include "../logging.h"

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

int flib_ipc_append_message(flib_vector vec, const char *fmt, ...) {
	int result = -1;
	if(!vec || !fmt) {
		flib_log_e("null parameter in flib_ipc_appendmessage");
	} else {
		// 1 byte size prefix, 255 bytes max message length, 1 0-byte for vsnprintf
		char msgbuffer[257];

		// Format the message, leaving one byte at the start for the length
		va_list argp;
		va_start(argp, fmt);
		int msgSize = vsnprintf(msgbuffer+1, 256, fmt, argp);
		va_end(argp);

		if(msgSize > 255) {
			flib_log_e("Message too long (%u bytes) in flib_ipc_appendmessage", (unsigned)msgSize);
		} else if(msgSize<0) {
			flib_log_e("printf error in flib_ipc_appendmessage");
		} else {
			// Add the length prefix
			((uint8_t*)msgbuffer)[0] = msgSize;

			// Append it to the vector
			if(flib_vector_append(vec, msgbuffer, msgSize+1) == msgSize+1) {
				result = 0;
			}
		}
	}
	return result;
}

int flib_ipc_append_mapconf(flib_vector vec, flib_map *map, bool mappreview) {
	int result = -1;
	flib_vector tempvector = flib_vector_create();
	if(!vec || !map) {
		flib_log_e("null parameter in flib_ipc_append_mapconf");
	} else if(tempvector) {
		bool error = false;

		if(map->mapgen == MAPGEN_NAMED) {
			error |= flib_ipc_append_message(tempvector, "emap %s", map->name);
		}
		if(map->theme && !mappreview) {
			error |= flib_ipc_append_message(tempvector, "etheme %s", map->theme);
		}
		error |= flib_ipc_append_message(tempvector, "e$template_filter %i", map->templateFilter);
		error |= flib_ipc_append_message(tempvector, "e$mapgen %i", map->mapgen);

		if(map->mapgen == MAPGEN_MAZE) {
			error |= flib_ipc_append_message(tempvector, "e$maze_size %i", map->mazeSize);
		}
		if(map->mapgen == MAPGEN_DRAWN) {
			/*
			 * We have to split the drawn map data into several edraw messages here because
			 * it can be longer than the maximum message size.
			 */
			const char *edraw = "edraw ";
			int edrawlen = strlen(edraw);
			for(int offset=0; offset<map->drawDataSize; offset+=200) {
				int bytesRemaining = map->drawDataSize-offset;
				int fragmentsize = bytesRemaining < 200 ? bytesRemaining : 200;
				uint8_t messagesize = edrawlen + fragmentsize;
				error |= (flib_vector_append(tempvector, &messagesize, 1) != 1);
				error |= (flib_vector_append(tempvector, edraw, edrawlen) != edrawlen);
				error |= (flib_vector_append(tempvector, map->drawData+offset, fragmentsize) != fragmentsize);
			}
		}

		if(!error) {
			// Message created, now we can copy everything.
			flib_constbuffer constbuf = flib_vector_as_constbuffer(tempvector);
			if(flib_vector_append(vec, constbuf.data, constbuf.size) == constbuf.size) {
				result = 0;
			}
		}
	}
	flib_vector_destroy(&tempvector);
	return result;
}

int flib_ipc_append_seed(flib_vector vec, const char *seed) {
	if(!vec || !seed) {
		flib_log_e("null parameter in flib_ipc_append_seed");
		return -1;
	} else {
		return flib_ipc_append_message(vec, "eseed %s", seed);
	}
}
