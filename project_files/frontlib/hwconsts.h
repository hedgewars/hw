/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 * Copyright (c) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * This file contains important constants which might need to be changed to adapt to
 * changes in the engine or protocols.
 *
 * It also contains getter functions for some constants (in particular for constants
 * that are important for the layout of data structures), so that client code can
 * query the constants that the library was built with.
 */

#ifndef HWCONSTS_H_
#define HWCONSTS_H_

#include <inttypes.h>
#include <stddef.h>
#include <stdbool.h>

#define HEDGEHOGS_PER_TEAM 8
#define DEFAULT_HEDGEHOG_COUNT 4
#define DEFAULT_COLOR_INDEX 0

#define NETGAME_DEFAULT_PORT 46631
#define PROTOCOL_VERSION 42
#define MIN_SERVER_VERSION 1

//! Used for sending scripts to the engine
#define MULTIPLAYER_SCRIPT_PATH "Scripts/Multiplayer/"

#define WEAPONS_COUNT 56

// TODO allow frontend to override these?
/*! A merge of mikade/bugq colours w/ a bit of channel feedback */
#define HW_TEAMCOLOR_ARRAY  { UINT32_C(0xffff0204), /*! red    */ \
                              UINT32_C(0xff4980c1), /*! blue   */ \
                              UINT32_C(0xff1de6ba), /*! teal   */ \
                              UINT32_C(0xffb541ef), /*! purple */ \
                              UINT32_C(0xffe55bb0), /*! pink   */ \
                              UINT32_C(0xff20bf00), /*! green  */ \
                              UINT32_C(0xfffe8b0e), /*! orange */ \
                              UINT32_C(0xff5f3605), /*! brown  */ \
                              UINT32_C(0xffffff01), /*! yellow */ \
                              /*! add new colors here */ \
                              0 } /*! Keep this 0 at the end */

extern const size_t flib_teamcolor_count;
extern const uint32_t flib_teamcolors[];

/**
 * Returns the team color (ARGB) corresponding to the color index (0 if index out of bounds)
 */
uint32_t flib_get_teamcolor(int colorIndex);

/**
 * Returns the number of team colors (i.e. the length of the flib_teamcolors array)
 */
int flib_get_teamcolor_count();

/**
 * Returns the HEDGEHOGS_PER_TEAM constant
 */
int flib_get_hedgehogs_per_team();

/**
 * Returns the WEAPONS_COUNT constant
 */
int flib_get_weapons_count();

/*!
 * These structs define the meaning of values in the flib_scheme struct, i.e. their correspondence to
 * ini settings, engine commands and positions in the network protocol (the last is encoded in the
 * order of settings/mods).
 */
typedef struct {
    const char *name;               //!< A name identifying this setting (used as key in the schemes file)
    const char *engineCommand;      //!< The command needed to send the setting to the engine. May be null if the setting is not sent to the engine (for the "health" setting)
    const bool maxMeansInfinity;    //!< If true, send a very high number to the engine if the setting is equal to its maximum
    const bool times1000;           //!< If true (for time-based settings), multiply the setting by 1000 before sending it to the engine.
    const int min;                  //!< The smallest allowed value
    const int max;                  //!< The highest allowed value
    const int def;                  //!< The default value
} flib_metascheme_setting;

typedef struct {
    const char *name;               //!< A name identifying this mod (used as key in the schemes file)
    const int bitmaskIndex;         //!< Mods are sent to the engine in a single integer, this field describes which bit of that integer is used
                                    //! for this particular mod.
} flib_metascheme_mod;

typedef struct {
    const int settingCount;
    const int modCount;
    const flib_metascheme_setting *settings;
    const flib_metascheme_mod *mods;
} flib_metascheme;

extern const flib_metascheme flib_meta;

const flib_metascheme *flib_get_metascheme();

#endif
