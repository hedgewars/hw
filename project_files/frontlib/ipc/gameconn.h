#ifndef GAMECONN_H_
#define GAMECONN_H_

#include "../model/gamesetup.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define GAME_END_FINISHED 0
#define GAME_END_INTERRUPTED 1
#define GAME_END_HALTED 2
#define GAME_END_ERROR 3

struct _flib_gameconn;
typedef struct _flib_gameconn flib_gameconn;

flib_gameconn *flib_gameconn_create(const char *playerName, const flib_gamesetup *setup, bool netgame);
flib_gameconn *flib_gameconn_create_playdemo(const uint8_t *demo, int size);
flib_gameconn *flib_gameconn_create_loadgame(const char *playerName, const uint8_t *save, int size);
flib_gameconn *flib_gameconn_create_campaign(const char *playerName, const char *seed, const char *script);

void flib_gameconn_destroy(flib_gameconn *conn);

/**
 * Returns the port on which the gameconn is listening. Only fails if you
 * pass NULL (not allowed), in that case 0 is returned.
 */
int flib_gameconn_getport(flib_gameconn *conn);

/**
 * Perform I/O operations and call callbacks if something interesting happens.
 * Should be called regularly.
 */
void flib_gameconn_tick(flib_gameconn *conn);

int flib_gameconn_send_enginemsg(flib_gameconn *conn, uint8_t *data, int len);
int flib_gameconn_send_textmsg(flib_gameconn *conn, int msgtype, const char *msg);
int flib_gameconn_send_chatmsg(flib_gameconn *conn, const char *playername, const char *msg);

/**
 * handleConnect(void *context)
 */
void flib_gameconn_onConnect(flib_gameconn *conn, void (*callback)(void* context), void* context);

/**
 * handleDisconnect(void *context, int reason)
 */
void flib_gameconn_onDisconnect(flib_gameconn *conn, void (*callback)(void* context, int reason), void* context);

/**
 * Receives error messages sent by the engine
 * handleErrorMessage(void* context, const char *msg)
 */
void flib_gameconn_onErrorMessage(flib_gameconn *conn, void (*callback)(void* context, const char *msg), void* context);

/**
 * handleChat(void* context, const char *msg, bool teamchat)
 */
void flib_gameconn_onChat(flib_gameconn *conn, void (*callback)(void* context, const char *msg, bool teamchat), void* context);

/**
 * Called when the game ends
 * handleGameRecorded(void *context, const uint8_t *record, int size, bool isSavegame)
 */
void flib_gameconn_onGameRecorded(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *record, int size, bool isSavegame), void* context);

/**
 * Called when the game ends
 * TODO handleStats(???)
 */

/**
 * ...needs to be passed on to the server in a net game
 * handleEngineMessage(void *context, const uint8_t *em, int size)
 */
void flib_gameconn_onEngineMessage(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *em, int size), void* context);

// TODO efinish

#endif
