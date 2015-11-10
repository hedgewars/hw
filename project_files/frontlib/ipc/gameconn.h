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

/**
 * This file contains functions for starting and interacting with a game run by the engine.
 * The general usage is to first create a gameconn object by calling one of the flib_gameconn_create
 * functions. That will cause the frontlib to listen on a random port which can be queried using
 * flib_gameconn_getport(). You should also register your callback functions right at the start
 * to ensure you don't miss any callbacks.
 *
 * Next, start the engine (that part is up to you) with the appropriate command line arguments
 * for starting a game.
 *
 * In order to allow the gameconn to run, you should regularly call flib_gameconn_tick(), which
 * performs network I/O and calls your callbacks on interesting events.
 *
 * Once the engine connects, the gameconn will send it the required commands for starting the
 * game you requested in your flib_gameconn_create call.
 *
 * When the game is finished (or the connection is lost), you will receive the onDisconnect
 * message. This is the signal to destroy the gameconn and stop calling tick().
 */

#ifndef GAMECONN_H_
#define GAMECONN_H_

#include "../model/gamesetup.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

/*
 * Different reasons for a disconnect. Only GAME_END_FINISHED signals a correctly completed game.
 */
#define GAME_END_FINISHED 0
#define GAME_END_INTERRUPTED 1
#define GAME_END_HALTED 2
#define GAME_END_ERROR 3

typedef struct _flib_gameconn flib_gameconn;

/**
 * Create a gameconn that will start a local or network game with the indicated configuration.
 */
flib_gameconn *flib_gameconn_create(const char *playerName, const flib_gamesetup *setup, bool netgame);

/**
 * Create a gameconn that will play back a demo.
 */
flib_gameconn *flib_gameconn_create_playdemo(const uint8_t *demoFileContent, size_t size);

/**
 * Create a gameconn that will continue from a saved game.
 */
flib_gameconn *flib_gameconn_create_loadgame(const char *playerName, const uint8_t *saveFileContent, size_t size);

/**
 * Create a gameconn that will start a campaign or training mission with the indicated script.
 * seed is the random seed to use as entropy source (any string).
 * script is the path and filename of a Campaign or Training script, relative to the Data directory
 * (e.g. "Missions/Training/Basic_Training_-_Bazooka.lua")
 */
flib_gameconn *flib_gameconn_create_campaign(const char *playerName, const char *seed, const char *script);

/**
 * Release all resources of this gameconn, including the network connection, and free its memory.
 * It is safe to call this function from a callback.
 */
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

/**
 * Send an engine message to the engine. Only needed in net games, where you receive engine
 * messages from the server and have to pass them here.
 */
int flib_gameconn_send_enginemsg(flib_gameconn *conn, const uint8_t *data, size_t len);

/**
 * Send an info message to the engine that will be displayed in the game's chatlog.
 * The msgtype determines the color of the message;  in the QTFrontend, info messages and
 * normal chat messages use 1, emote-messages (those starting with /me) use 2, and
 * join/leave messages use 3. You should use flib_gameconn_send_chatmsg for chat messages
 * though because it automatically formats /me messages.
 *
 * Generally only needed in net games.
 */
int flib_gameconn_send_textmsg(flib_gameconn *conn, int msgtype, const char *msg);

/**
 * Send a chat message to be displayed in the game's chatlog. Messages starting with /me are
 * automatically formatted correctly.
 *
 * Generally only needed in net games.
 */
int flib_gameconn_send_chatmsg(flib_gameconn *conn, const char *playername, const char *msg);

/**
 * Request the engine to stop the game (efinish).
 * You can use this to shut down a game early without directly killing the engine process.
 */
int flib_gameconn_send_quit(flib_gameconn *conn);

/**
 * Send an arbitrary command to the engine, e.g. "eforcequit" to shut down the engine
 * quickly. Commands prefixed with "e" will be processed by the engine's ProcessCommand
 * method (with the e removed, so e.g. efinish will be parsed as finish).
 */
int flib_gameconn_send_cmd(flib_gameconn *conn, const char *cmdString);

/**
 * Expected callback signature: void handleConnect(void *context)
 * The engine has successfully connected. You don't have to react to this in any way.
 */
void flib_gameconn_onConnect(flib_gameconn *conn, void (*callback)(void* context), void* context);

/**
 * Expected callback signature: void handleDisconnect(void *context, int reason)
 * The connection to the engine was closed, either because the game has ended normally, or
 * because it was interrupted/halted, or because of an error. The reason is provided as one
 * of the GAME_END_xxx constants.
 *
 * You should destroy the gameconn and - in a netgame - notify the server that the game has ended.
 */
void flib_gameconn_onDisconnect(flib_gameconn *conn, void (*callback)(void* context, int reason), void* context);

/**
 * Expected callback signature: void handleErrorMessage(void* context, const char *msg)
 * The engine sent an error message, you should probably display it to the user or at least log it.
 */
void flib_gameconn_onErrorMessage(flib_gameconn *conn, void (*callback)(void* context, const char *msg), void* context);

/**
 * Expected callback signature: void handleChat(void* context, const char *msg, bool teamchat)
 * The player entered a chat or teamchat message. In a netgame, you should send it on to the server.
 */
void flib_gameconn_onChat(flib_gameconn *conn, void (*callback)(void* context, const char *msg, bool teamchat), void* context);

/**
 * Expected callback signature: void handleGameRecorded(void *context, const uint8_t *record, size_t size, bool isSavegame)
 * The game has stopped, and a demo or savegame is available. You can store it in a file and later pass it back
 * to the engine to either watch a replay (if it's a demo) or to continue playing (if it's a savegame).
 */
void flib_gameconn_onGameRecorded(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *record, size_t size, bool isSavegame), void* context);

/**
 * Expected callback signature: void handleEngineMessage(void *context, const uint8_t *em, size_t size)
 * The engine has generated a message with player input. In a netgame, you should send it on to the server.
 */
void flib_gameconn_onEngineMessage(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *em, size_t size), void* context);

#endif
