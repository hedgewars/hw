/**
 * Demo recording functions. Only used by the ipc game code.
 */

#ifndef DEMO_H_
#define DEMO_H_

#include "../buffer.h"

/**
 * Record a message sent from the engine to the frontend.
 * Returns 0 for OK, a negative value on error.
 * Don't pass NULL.
 */
int flib_demo_record_from_engine(flib_vector demoBuffer, const uint8_t *message, const char *playerName);

/**
 * Record a message sent from the frontend to the engine.
 * Returns 0 for OK, a negative value on error.
 * Don't pass NULL.
 */
int flib_demo_record_to_engine(flib_vector demoBuffer, const uint8_t *message, size_t len);

/**
 * Replace game mode messages ("TL", "TD", "TS", "TN") in the recording to mirror
 * the intended use. Pass 'S' for savegames, 'D' for demos.
 */
void flib_demo_replace_gamemode(flib_buffer buf, char gamemode);

#endif /* DEMO_H_ */
