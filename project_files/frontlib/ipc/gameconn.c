/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "gameconn.h"
#include "ipcbase.h"
#include "ipcprotocol.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../hwconsts.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    AWAIT_CONNECTION,
    CONNECTED,
    FINISHED
} gameconn_state;

struct _flib_gameconn {
    flib_ipcbase *ipcBase;
    flib_vector *configBuffer;
    flib_vector *demoBuffer;
    char *playerName;

    gameconn_state state;
    bool netgame;
    int disconnectReason;

    void (*onConnectCb)(void* context);
    void *onConnectCtx;

    void (*onDisconnectCb)(void* context, int reason);
    void *onDisconnectCtx;

    void (*onErrorMessageCb)(void* context, const char *msg);
    void *onErrorMessageCtx;

    void (*onChatCb)(void* context, const char *msg, bool teamchat);
    void *onChatCtx;

    void (*onGameRecordedCb)(void *context, const uint8_t *record, size_t size, bool isSavegame);
    void *onGameRecordedCtx;

    void (*onEngineMessageCb)(void *context, const uint8_t *em, size_t size);
    void *onEngineMessageCtx;

    bool running;
    bool destroyRequested;
};

static void defaultCallback_onErrorMessage(void* context, const char *msg) {
    flib_log_w("Error from engine (no callback set): %s", msg);
}

static void clearCallbacks(flib_gameconn *conn) {
    flib_gameconn_onConnect(conn, NULL, NULL);
    flib_gameconn_onDisconnect(conn, NULL, NULL);
    flib_gameconn_onErrorMessage(conn, NULL, NULL);
    flib_gameconn_onChat(conn, NULL, NULL);
    flib_gameconn_onGameRecorded(conn, NULL, NULL);
    flib_gameconn_onEngineMessage(conn, NULL, NULL);
}

static flib_gameconn *flib_gameconn_create_partial(bool record, const char *playerName, bool netGame) {
    flib_gameconn *result = NULL;
    flib_gameconn *tempConn = flib_calloc(1, sizeof(flib_gameconn));
    if(tempConn) {
        tempConn->ipcBase = flib_ipcbase_create();
        tempConn->configBuffer = flib_vector_create();
        tempConn->playerName = flib_strdupnull(playerName);
        if(tempConn->ipcBase && tempConn->configBuffer && tempConn->playerName) {
            if(record) {
                tempConn->demoBuffer = flib_vector_create();
            }
            tempConn->state = AWAIT_CONNECTION;
            tempConn->netgame = netGame;
            tempConn->disconnectReason = GAME_END_ERROR;
            clearCallbacks(tempConn);
            result = tempConn;
            tempConn = NULL;
        }
    }
    flib_gameconn_destroy(tempConn);
    return result;
}

flib_gameconn *flib_gameconn_create(const char *playerName, const flib_gamesetup *setup, bool netgame) {
    if(log_badargs_if2(playerName==NULL, setup==NULL)) {
        return NULL;
    }
    flib_gameconn *result = NULL;
    flib_gameconn *tempConn = flib_gameconn_create_partial(true, playerName, netgame);
    if(tempConn) {
        if(flib_ipc_append_fullconfig(tempConn->configBuffer, setup, netgame)) {
            flib_log_e("Error generating full game configuration for the engine.");
        } else {
            result = tempConn;
            tempConn = NULL;
        }
    }
    flib_gameconn_destroy(tempConn);
    return result;
}

flib_gameconn *flib_gameconn_create_playdemo(const uint8_t *demoFileContent, size_t size) {
    if(log_badargs_if(demoFileContent==NULL && size>0)) {
        return NULL;
    }
    flib_gameconn *result = NULL;
    flib_gameconn *tempConn = flib_gameconn_create_partial(false, "Player", false);
    if(tempConn) {
        if(!flib_vector_append(tempConn->configBuffer, demoFileContent, size)) {
            result = tempConn;
            tempConn = NULL;
        }
    }
    flib_gameconn_destroy(tempConn);
    return result;
}

flib_gameconn *flib_gameconn_create_loadgame(const char *playerName, const uint8_t *saveFileContent, size_t size) {
    if(log_badargs_if(saveFileContent==NULL && size>0)) {
        return NULL;
    }
    flib_gameconn *result = NULL;
    flib_gameconn *tempConn = flib_gameconn_create_partial(true, playerName, false);
    if(tempConn) {
        if(!flib_vector_append(tempConn->configBuffer, saveFileContent, size)) {
            result = tempConn;
            tempConn = NULL;
        }
    }
    flib_gameconn_destroy(tempConn);
    return result;
}

flib_gameconn *flib_gameconn_create_campaign(const char *playerName, const char *seed, const char *script) {
    if(log_badargs_if3(playerName==NULL, seed==NULL, script==NULL)) {
        return NULL;
    }
    flib_gameconn *result = NULL;
    flib_gameconn *tempConn = flib_gameconn_create_partial(true, playerName, false);
    if(tempConn) {
        if(!flib_ipc_append_message(tempConn->configBuffer, "TL")
                && !flib_ipc_append_seed(tempConn->configBuffer, seed)
                && !flib_ipc_append_script(tempConn->configBuffer, script)
                && !flib_ipc_append_message(tempConn->configBuffer, "!")) {
            result = tempConn;
            tempConn = NULL;
        }
    }
    flib_gameconn_destroy(tempConn);
    return result;
}

void flib_gameconn_destroy(flib_gameconn *conn) {
    if(conn) {
        if(conn->running) {
            /*
             * The function was called from a callback, so the tick function is still running
             * and we delay the actual destruction. We ensure no further callbacks will be
             * sent to prevent surprises.
             */
            clearCallbacks(conn);
            conn->destroyRequested = true;
        } else {
            flib_ipcbase_destroy(conn->ipcBase);
            flib_vector_destroy(conn->configBuffer);
            flib_vector_destroy(conn->demoBuffer);
            free(conn->playerName);
            free(conn);
        }
    }
}

int flib_gameconn_getport(flib_gameconn *conn) {
    if(log_badargs_if(conn==NULL)) {
        return 0;
    }
    return flib_ipcbase_port(conn->ipcBase);
}

static void demo_append(flib_gameconn *conn, const void *data, size_t len) {
    if(conn->demoBuffer) {
        if(flib_vector_append(conn->demoBuffer, data, len)) {
            flib_log_e("Error recording demo: Out of memory.");
            flib_vector_destroy(conn->demoBuffer);
            conn->demoBuffer = NULL;
        }
    }
}

static int format_chatmessage(uint8_t buffer[257], const char *playerName, const char *message) {
    size_t msglen = strlen(message);

    // If the message starts with /me, it will be displayed differently.
    bool meMessage = msglen >= 4 && !memcmp(message, "/me ", 4);
    const char *template = meMessage ? "s\x02* %s %s  " : "s\x01%s: %s  ";
    int size = snprintf((char*)buffer+1, 256, template, playerName, meMessage ? message+4 : message);
    if(log_e_if(size<=0, "printf error")) {
        return -1;
    } else {
        buffer[0] = size>255 ? 255 : size;
        return 0;
    }
}

static void demo_append_chatmessage(flib_gameconn *conn, const char *message) {
    // Chat messages are reformatted to make them look as if they were received, not sent.
    uint8_t converted[257];
    if(!format_chatmessage(converted, conn->playerName, message)) {
        demo_append(conn, converted, converted[0]+1);
    }
}

static void demo_replace_gamemode(flib_buffer buf, char gamemode) {
    size_t msgStart = 0;
    uint8_t *data = (uint8_t*)buf.data;
    while(msgStart+2 < buf.size) {
        if(!memcmp(data+msgStart, "\x02T", 2)) {
            data[msgStart+2] = gamemode;
        }
        msgStart += (uint8_t)data[msgStart]+1;
    }
}

int flib_gameconn_send_enginemsg(flib_gameconn *conn, const uint8_t *data, size_t len) {
    if(log_badargs_if2(conn==NULL, data==NULL && len>0)) {
        return -1;
    }
    int result = flib_ipcbase_send_raw(conn->ipcBase, data, len);
    if(!result) {
        demo_append(conn, data, len);
    }
    return result;
}

int flib_gameconn_send_textmsg(flib_gameconn *conn, int msgtype, const char *msg) {
    if(log_badargs_if2(conn==NULL, msg==NULL)) {
        return -1;
    }
    int result = -1;
    uint8_t converted[257];
    int size = snprintf((char*)converted+1, 256, "s%c%s", (char)msgtype, msg);
    if(size>0) {
        converted[0] = size>255 ? 255 : size;
        if(!flib_ipcbase_send_raw(conn->ipcBase, converted, converted[0]+1)) {
            demo_append(conn, converted, converted[0]+1);
            result = 0;
        }
    }
    return result;
}

int flib_gameconn_send_chatmsg(flib_gameconn *conn, const char *playername, const char *msg) {
    if(log_badargs_if3(conn==NULL, playername==NULL, msg==NULL)) {
        return -1;
    }
    uint8_t converted[257];
    if(!format_chatmessage(converted, playername, msg)
            && !flib_ipcbase_send_raw(conn->ipcBase, converted, converted[0]+1)) {
        demo_append(conn, converted, converted[0]+1);
        return 0;
    }
    return -1;
}

int flib_gameconn_send_quit(flib_gameconn *conn) {
    return flib_gameconn_send_cmd(conn, "efinish");
}

int flib_gameconn_send_cmd(flib_gameconn *conn, const char *cmdString) {
    if(log_badargs_if2(conn==NULL, cmdString==NULL)) {
        return -1;
    }
    int result = -1;
    uint8_t converted[256];
    size_t msglen = strlen(cmdString);
    if(!log_e_if(msglen>255, "Message too long: %s", cmdString)) {
        strcpy((char*)converted+1, cmdString);
        converted[0] = msglen;
        if(!flib_ipcbase_send_raw(conn->ipcBase, converted, msglen+1)) {
            demo_append(conn, converted, msglen+1);
            result = 0;
        }
    }
    return result;
}

/**
 * This macro generates a callback setter function. It uses the name of the callback to
 * automatically generate the function name and the fields to set, so a consistent naming
 * convention needs to be enforced (not that that is a bad thing). If null is passed as
 * callback to the generated function, the defaultCb will be set instead (with conn
 * as the context).
 */
#define GENERATE_CB_SETTER(cbName, cbParameterTypes, defaultCb) \
    void flib_gameconn_##cbName(flib_gameconn *conn, void (*callback)cbParameterTypes, void *context) { \
        if(!log_badargs_if(conn==NULL)) { \
            conn->cbName##Cb = callback ? callback : &defaultCb; \
            conn->cbName##Ctx = callback ? context : conn; \
        } \
    }

/**
 * Generate a callback setter function like GENERATE_CB_SETTER, and automatically generate a
 * no-op callback function as well that is used as default.
 */
#define GENERATE_CB_SETTER_AND_DEFAULT(cbName, cbParameterTypes) \
    static void _noop_callback_##cbName cbParameterTypes {} \
    GENERATE_CB_SETTER(cbName, cbParameterTypes, _noop_callback_##cbName)

GENERATE_CB_SETTER_AND_DEFAULT(onConnect, (void *context));
GENERATE_CB_SETTER_AND_DEFAULT(onDisconnect, (void* context, int reason));
GENERATE_CB_SETTER(onErrorMessage, (void* context, const char *msg), defaultCallback_onErrorMessage);
GENERATE_CB_SETTER_AND_DEFAULT(onChat, (void* context, const char *msg, bool teamchat));
GENERATE_CB_SETTER_AND_DEFAULT(onGameRecorded, (void *context, const uint8_t *record, size_t size, bool isSavegame));
GENERATE_CB_SETTER_AND_DEFAULT(onEngineMessage, (void *context, const uint8_t *em, size_t size));

#undef GENERATE_CB_SETTER_AND_DEFAULT
#undef GENERATE_CB_SETTER

static void flib_gameconn_wrappedtick(flib_gameconn *conn) {
    if(conn->state == AWAIT_CONNECTION) {
        flib_ipcbase_accept(conn->ipcBase);
        switch(flib_ipcbase_state(conn->ipcBase)) {
        case IPC_CONNECTED:
            {
                flib_constbuffer configBuffer = flib_vector_as_constbuffer(conn->configBuffer);
                if(flib_ipcbase_send_raw(conn->ipcBase, configBuffer.data, configBuffer.size)) {
                    conn->state = FINISHED;
                    conn->onDisconnectCb(conn->onDisconnectCtx, GAME_END_ERROR);
                    return;
                } else {
                    demo_append(conn, configBuffer.data, configBuffer.size);
                    conn->state = CONNECTED;
                    conn->onConnectCb(conn->onConnectCtx);
                    if(conn->destroyRequested) {
                        return;
                    }
                }
            }
            break;
        case IPC_NOT_CONNECTED:
            conn->state = FINISHED;
            conn->onDisconnectCb(conn->onDisconnectCtx, GAME_END_ERROR);
            return;
        default:
            break;
        }
    }

    if(conn->state == CONNECTED) {
        uint8_t msgbuffer[257];
        int len;
        while(!conn->destroyRequested && (len = flib_ipcbase_recv_message(conn->ipcBase, msgbuffer))>=0) {
            if(len<2) {
                flib_log_w("Received short message from IPC (<2 bytes)");
                continue;
            }
            switch(msgbuffer[1]) {
            case '?':   // Ping
                // The pong is already part of the config message
                break;
            case 'C':   // Config query
                // And we already send the config message on connecting.
                break;
            case 'E':   // Error message
                if(len>=3) {
                    msgbuffer[len-2] = 0;
                    conn->onErrorMessageCb(conn->onErrorMessageCtx, (char*)msgbuffer+2);
                }
                break;
            case 'i':   // Statistics
                // TODO stats
                break;
            case 'Q':   // Game interrupted
            case 'H':   // Game halted
            case 'q':   // game finished
                {
                    int reason = msgbuffer[1]=='Q' ? GAME_END_INTERRUPTED : msgbuffer[1]=='H' ? GAME_END_HALTED : GAME_END_FINISHED;
                    conn->disconnectReason = reason;
                    bool savegame = (reason != GAME_END_FINISHED) && !conn->netgame;
                    if(conn->demoBuffer) {
                        flib_buffer demoBuffer = flib_vector_as_buffer(conn->demoBuffer);
                        demo_replace_gamemode(demoBuffer, savegame ? 'S' : 'D');
                        conn->onGameRecordedCb(conn->onGameRecordedCtx, demoBuffer.data, demoBuffer.size, savegame);
                        if(conn->destroyRequested) {
                            return;
                        }
                    }
                    return;
                }
            case 's':   // Chat message
                if(len>=3) {
                    msgbuffer[len-2] = 0;
                    demo_append_chatmessage(conn, (char*)msgbuffer+2);

                    conn->onChatCb(conn->onChatCtx, (char*)msgbuffer+2, false);
                }
                break;
            case 'b':   // Teamchat message
                if(len>=3) {
                    msgbuffer[len-2] = 0;
                    conn->onChatCb(conn->onChatCtx, (char*)msgbuffer+2, true);
                }
                break;
            default:    // Engine message
                demo_append(conn, msgbuffer, len);

                conn->onEngineMessageCb(conn->onEngineMessageCtx, msgbuffer, len);
                break;
            }
        }
    }

    if(flib_ipcbase_state(conn->ipcBase) == IPC_NOT_CONNECTED) {
        conn->state = FINISHED;
        conn->onDisconnectCb(conn->onDisconnectCtx, conn->disconnectReason);
    }
}

void flib_gameconn_tick(flib_gameconn *conn) {
    if(!log_badargs_if(conn == NULL)
            && !log_w_if(conn->running, "Call to flib_gameconn_tick from a callback")
            && !log_w_if(conn->state == FINISHED, "We are already done.")) {
        conn->running = true;
        flib_gameconn_wrappedtick(conn);
        conn->running = false;

        if(conn->destroyRequested) {
            flib_gameconn_destroy(conn);
        }
    }
}
