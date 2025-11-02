/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2019 Andrey Korotaev <unC0Rr@gmail.com>
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
 * @file
 * @brief KeyMap class definition
 */

#ifndef HEDGEWARS_KEYMAP_H
#define HEDGEWARS_KEYMAP_H

#include <QFile>
#include <QHash>
#include "SDL.h"

class KeyMap
{
    public:
        /**
         * @brief Returns reference to the <i>singleton</i> instance of this class.
         *
         * @see <a href="https://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
         *
         * @return reference to the instance.
         */
        static KeyMap & instance();
        SDL_Scancode getScancodeFromKeyname(QString keyname);
        QString getKeynameFromScancode(int scancode);
        QString getKeynameFromScancodeConverted(int scancode);
        QString getKeynameFromKeycode(int keycode);

    private:
        // TODO: Optimize data structures
        QHash<SDL_Scancode, QString> mapOfKeynames;
        QHash<QString, SDL_Scancode> mapOfScancodes;
        bool getKeyMap();
        bool keyMapGenerated = false;

};

#endif // HEDGEWARS_KEYMAP_H
