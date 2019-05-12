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

#include "KeyMap.h"
#include "SDL.h"

KeyMap & KeyMap::instance()
{
    static KeyMap instance;
    instance.getKeyMap();
    return instance;
}

bool KeyMap::getKeyMap()
{
    if (keyMapGenerated)
        return true;
    QFile keyFile(":keys.csv");
    if (!keyFile.open(QIODevice::ReadOnly))
    {
        qWarning("ERROR: keys.csv could not be opened!");
        return false;
    }
    QString keyString = keyFile.readAll();
    QStringList cells = QStringList() << QString("") << QString("");
    QChar currChar;
    bool isInQuote = false;
    int cell = 0;
    int charInCell = 0;
    QString scancode = "";
    QString keyname = "";
    for(long long int i = 0; i < keyString.length(); i++)
    {
        currChar = keyString.at(i);
        if (currChar == '\"') {
            isInQuote = !isInQuote;
        }
        if (currChar == ',' && !isInQuote) {
            cell++;
            continue;
        }
        if (currChar == '\n') {
            mapOfKeynames[(SDL_Scancode) scancode.toInt()] = keyname;
            mapOfScancodes[keyname] = (SDL_Scancode) scancode.toInt();
            if ((SDL_Scancode) scancode.toInt() == SDL_SCANCODE_UNKNOWN)
                continue;
            cell = 0;
            scancode = "";
            keyname = "";
            continue;
        }
        if (cell == 0 && currChar != '\"') {
            scancode += currChar;
        } else if (cell == 1 && currChar != '\"') {
            keyname += currChar;
        }
        charInCell++;
    }
    keyMapGenerated = true;
    keyFile.close();
    return true;
}

SDL_Scancode KeyMap::getScancodeFromKeyname(QString keyname)
{
    if (mapOfScancodes.contains(keyname))
        return mapOfScancodes[keyname];
    else
        return SDL_SCANCODE_UNKNOWN;
}

QString KeyMap::getKeynameFromScancode(int scancode)
{
    if (mapOfKeynames.contains((SDL_Scancode) scancode))
        if ((SDL_Scancode) scancode == SDL_SCANCODE_UNKNOWN)
            return QString("none");
        else
            return mapOfKeynames[(SDL_Scancode) scancode];
    else
        return QString("");
}

QString KeyMap::getKeynameFromScancodeConverted(int scancode)
{
    SDL_Keycode keycode = SDL_GetKeyFromScancode((SDL_Scancode) scancode);
    return SDL_GetKeyName(keycode);
}

