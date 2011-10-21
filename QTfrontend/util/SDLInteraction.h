/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007-2011 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#ifndef HEDGEWARS_SDLINTERACTION_H
#define HEDGEWARS_SDLINTERACTION_H


#include <QMap>
#include <QStringList>

#include "SDL_mixer.h"

/**
 * @brief Class for interacting with SDL (used for music and keys)
 * 
 * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
 */
class SDLInteraction
{

private:
    /**
     * @brief Class constructor of the <i>singleton</i>.
     * 
     * Not to be used from outside the class,
     * use the static {@link HWDataManager::instance()} instead.
     * 
     * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
     */
    SDLInteraction();

    /// Initializes SDL for sound output if needed.
    void SDLSoundInit();

    Mix_Music *music;
    int musicInitialized;

    QMap<QString,Mix_Chunk*> * soundMap; ///< maps sound file paths to channel

public:
    /**
     * @brief Returns reference to the <i>singleton</i> instance of this class.
     * 
     * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
     * 
     * @return reference to the instance.
     */
    static SDLInteraction & instance();

    /// Class Destructor.
    ~SDLInteraction();

    /**
     * @brief Returns available (screen) resolutions.
     *
     * @return list of resolutions in the format WIDTHxHEIGHT.
     */
    QStringList getResolutions() const;

    /// Adds all available joystick controlls to the list of SDL keys.
    void addGameControllerKeys() const;

    /**
     * @brief Plays a sound file.
     * 
     * @param soundFile path of the sound file.
     */
    void playSoundFile(const QString & soundFile);

    /// Starts the background music.
    void startMusic();

    /// Fades out and stops the background music.
    void stopMusic();
};


#endif //HEDGEWARS_SDLINTERACTION_H

