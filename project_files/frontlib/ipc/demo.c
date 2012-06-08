#include "demo.h"
#include "../logging.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

static int demo_record(flib_vector demoBuffer, const void *data, size_t len) {
	if(flib_vector_append(demoBuffer, data, len) < len) {
		flib_log_e("Error recording demo: Out of memory.");
		return -1;
	} else {
		return 0;
	}
}

int flib_demo_record_from_engine(flib_vector demoBuffer, const uint8_t *message, const char *playerName) {
	if(!demoBuffer || !message || !playerName) {
		flib_log_e("Call to flib_demo_record_from_engine with demoBuffer==null or message==null or playerName==null");
		return -1;
	}

	if(strchr("?CEiQqHb", message[1])) {
		return 0; // Those message types are not recorded in a demo.
	}

	if(message[1] == 's') {
		if(message[0] >= 3) {
			// Chat messages are reformatted to make them look as if they were received, not sent.
			// Get the actual chat message as C string
			char chatMsg[256];
			memcpy(chatMsg, message+2, message[0]-3);
			chatMsg[message[0]-3] = 0;

			// If the message starts with /me, it will be displayed differently.
			char converted[257];
			bool memessage = message[0] >= 7 && !memcmp(message+2, "/me ", 4);
			const char *template = memessage ? "s\x02* %s %s  " : "s\x01%s: %s  ";
			int size = snprintf(converted+1, 256, template, playerName, chatMsg);
			if(size>0) {
				converted[0] = size>255 ? 255 : size;
				return demo_record(demoBuffer, converted, converted[0]+1);
			} else {
				return 0;
			}
		} else {
			return 0; // Malformed chat message is no reason to abort...
		}
	} else {
		return demo_record(demoBuffer, message, message[0]+1);
	}
}

int flib_demo_record_to_engine(flib_vector demoBuffer, const uint8_t *message, size_t len) {
	if(!demoBuffer || (len>0 && !message)) {
		flib_log_e("Call to flib_demo_record_to_engine with demoBuffer==null or message==null");
		return -1;
	}
	return demo_record(demoBuffer, message, len);
}

void flib_demo_replace_gamemode(flib_buffer buf, char gamemode) {
	size_t msgStart = 0;
	char *data = (char*)buf.data;
	while(msgStart+2 < buf.size) {
		if(!memcmp(data+msgStart, "\x02T", 2)) {
			data[msgStart+2] = gamemode;
		}
		msgStart += (uint8_t)data[msgStart]+1;
	}
}
