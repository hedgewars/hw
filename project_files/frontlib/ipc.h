#ifndef IPC_H_
#define IPC_H_

#include "buffer.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

struct _flib_ipc;
typedef struct _flib_ipc *flib_ipc;

typedef enum {
	GAME_END_FINISHED,
	GAME_END_INTERRUPTED,
	GAME_END_HALTED
} flib_GameEndType;

flib_ipc flib_ipc_create(bool recordDemo, const char *localPlayerName);
void flib_ipc_destroy(flib_ipc *ipcptr);

void flib_ipc_onConnect(flib_ipc ipc, void (*callback)(void* context), void* context);
void flib_ipc_onDisconnect(flib_ipc ipc, void (*callback)(void* context), void* context);
void flib_ipc_onConfigQuery(flib_ipc ipc, void (*callback)(void* context), void* context);
void flib_ipc_onEngineError(flib_ipc ipc, void (*callback)(void* context, const uint8_t *error), void* context);
void flib_ipc_onGameEnd(flib_ipc ipc, void (*callback)(void* context, int gameEndType), void* context);
void flib_ipc_onChat(flib_ipc ipc, void (*callback)(void* context, const uint8_t *messagestr, int teamchat), void* context);
void flib_ipc_onEngineMessage(flib_ipc ipc, void (*callback)(void* context, const uint8_t *message, int len), void* context);

int flib_ipc_send_raw(flib_ipc ipc, void *data, size_t len);
int flib_ipc_send_message(flib_ipc ipc, void *data, size_t len);
int flib_ipc_send_messagestr(flib_ipc ipc, char *data);

uint16_t flib_ipc_port(flib_ipc ipc);
flib_constbuffer flib_ipc_getdemo(flib_ipc ipc);

void flib_ipc_tick(flib_ipc ipc);

#endif /* IPC_H_ */
