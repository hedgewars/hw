/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * @brief SDLInteraction class implementation
 */

#include "SDL.h"
#include "SDL_mixer.h"

#include "HWApplication.h"
#include "hwform.h" /* you know, we could just put a config singleton lookup function in gameuiconfig or something... */
#include "gameuiconfig.h"

#include "SDLInteraction.h"

#include "physfsrwops.h"

extern char sdlkeys[1024][2][128];
extern char xb360buttons[][128];
extern char xb360dpad[128];
extern char xbox360axes[][128];


SDLInteraction & SDLInteraction::instance()
{
    static SDLInteraction instance;
    return instance;
}


SDLInteraction::SDLInteraction()
{

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);

    m_audioInitialized = false;
    m_music = NULL;
    m_musicTrack = "";
    m_isPlayingMusic = false;
    lastchannel = 0;
    if(SDL_NumJoysticks())
        addGameControllerKeys();
    SDL_QuitSubSystem(SDL_INIT_JOYSTICK);

    m_soundMap = new QMap<QString,Mix_Chunk*>();
}


SDLInteraction::~SDLInteraction()
{
    stopMusic();
    if (m_audioInitialized)
    {
        if (m_music != NULL)
        {
            Mix_HaltMusic();
            Mix_FreeMusic(m_music);
        }
        Mix_CloseAudio();
    }
    SDL_Quit();

    delete m_soundMap;
}


QStringList SDLInteraction::getResolutions() const
{
    QStringList result;

    int modesNumber = SDL_GetNumDisplayModes(0);
    SDL_DisplayMode mode;

    for(int i = 0; i < modesNumber; ++i)
    {
        SDL_GetDisplayMode(0, i, &mode);

        if ((mode.w >= 640) && (mode.h >= 480))
            result << QString("%1x%2").arg(mode.w).arg(mode.h);
    }

    return result;
}


void SDLInteraction::addGameControllerKeys() const
{
    QStringList result;

#if SDL_VERSION_ATLEAST(2, 0, 0)
    int i = 0;
    while(i < 1024 && sdlkeys[i][1][0] != '\0')
        i++;

    // Iterate through all game controllers
    qDebug("Detecting controllers ...");
    for(int jid = 0; jid < SDL_NumJoysticks(); jid++)
    {
        SDL_Joystick* joy = SDL_JoystickOpen(jid);

        // Retrieve the game controller's name
        QString joyname = QString(SDL_JoystickNameForIndex(jid));

        // Strip "Controller (...)" that's added by some drivers (English only)
        joyname.replace(QRegExp("^Controller \\((.*)\\)$"), "\\1");

        qDebug("- Controller no. %d: %s", jid, qPrintable(joyname));

        // Connected Xbox 360 controller? Use specific button names then
        // Might be interesting to add 'named' buttons for the most often used gamepads
        bool isxb = joyname.contains("Xbox 360");

        // This part of the string won't change for multiple keys/hats, so keep it
        QString prefix = QString("%1 (%2): ").arg(joyname).arg(jid + 1);

        // Register entries for missing axes not assigned to sticks of this joystick/gamepad
        for(int aid = 0; aid < SDL_JoystickNumAxes(joy) && i < 1021; aid++)
        {
            // Again store the part of the string not changing for multiple uses
            QString axis = prefix + HWApplication::translate("binds (keys)", "Axis") + QString(" %1 ").arg(aid + 1);

            // Entry for "Axis Up"
            sprintf(sdlkeys[i][0], "j%da%du", jid, aid);
            sprintf(sdlkeys[i++][1], "%s", ((isxb && aid < 5) ? (prefix + HWApplication::translate("binds (keys)", xbox360axes[aid * 2])) : axis + HWApplication::translate("binds (keys)", "(Up)")).toUtf8().constData());

            // Entry for "Axis Down"
            sprintf(sdlkeys[i][0], "j%da%dd", jid, aid);
            sprintf(sdlkeys[i++][1], "%s", ((isxb && aid < 5) ? (prefix + HWApplication::translate("binds (keys)", xbox360axes[aid * 2 + 1])) : axis + HWApplication::translate("binds (keys)", "(Down)")).toUtf8().constData());
        }

        // Register entries for all coolie hats of this joystick/gamepad
        for(int hid = 0; hid < SDL_JoystickNumHats(joy) && i < 1019; hid++)
        {
            // Again store the part of the string not changing for multiple uses
            QString hat = prefix + (isxb ? (HWApplication::translate("binds (keys)", xb360dpad) + QString(" ")) : HWApplication::translate("binds (keys)", "Hat") + QString(" %1 ").arg(hid + 1));

            // Entry for "Hat Up"
            sprintf(sdlkeys[i][0], "j%dh%du", jid, hid);
            sprintf(sdlkeys[i++][1], "%s", (hat + HWApplication::translate("binds (keys)", "(Up)")).toUtf8().constData());

            // Entry for "Hat Down"
            sprintf(sdlkeys[i][0], "j%dh%dd", jid, hid);
            sprintf(sdlkeys[i++][1], "%s", (hat + HWApplication::translate("binds (keys)", "(Down)")).toUtf8().constData());

            // Entry for "Hat Left"
            sprintf(sdlkeys[i][0], "j%dh%dl", jid, hid);
            sprintf(sdlkeys[i++][1], "%s", (hat + HWApplication::translate("binds (keys)", "(Left)")).toUtf8().constData());

            // Entry for "Hat Right"
            sprintf(sdlkeys[i][0], "j%dh%dr", jid, hid);
            sprintf(sdlkeys[i++][1], "%s", (hat + HWApplication::translate("binds (keys)", "(Right)")).toUtf8().constData());
        }

        // Register entries for all buttons of this joystick/gamepad
        for(int bid = 0; bid < SDL_JoystickNumButtons(joy) && i < 1022; bid++)
        {
            // Buttons
            sprintf(sdlkeys[i][0], "j%db%d", jid, bid);
            sprintf(sdlkeys[i++][1], "%s", (prefix + ((isxb && bid < 10) ? (HWApplication::translate("binds (keys)", xb360buttons[bid]) + QString(" ")) : HWApplication::translate("binds (keys)", "Button") + QString(" %1").arg(bid + 1))).toUtf8().constData());
        }
        // Close the game controller as we no longer need it
        SDL_JoystickClose(joy);
    }

    if(i >= 1024)
        i = 1023;

    // Terminate the list
    sdlkeys[i][0][0] = '\0';
    sdlkeys[i][1][0] = '\0';   
#endif
}


void SDLInteraction::SDLAudioInit()
{
    // don't init again
    if (m_audioInitialized)
        return;

    SDL_Init(SDL_INIT_AUDIO);
    if(!Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)) /* should we keep trying, or just turn off permanently? */
        m_audioInitialized = true;
}


void SDLInteraction::playSoundFile(const QString & soundFile)
{
    if (!HWForm::config || !HWForm::config->isFrontendSoundEnabled()) return;
    SDLAudioInit();
    if (!m_audioInitialized) return;
    if (!m_soundMap->contains(soundFile))
        m_soundMap->insert(soundFile, Mix_LoadWAV_RW(PHYSFSRWOPS_openRead(soundFile.toLocal8Bit().constData()), 1));

    //FIXME: this is a hack, but works as long as we have few concurrent playing sounds
    if (Mix_Playing(lastchannel) == false)
        lastchannel = Mix_PlayChannel(-1, m_soundMap->value(soundFile), 0);
}

void SDLInteraction::setMusicTrack(const QString & musicFile)
{
    bool wasPlayingMusic = m_isPlayingMusic;

    stopMusic();

    if (m_music != NULL)
    {
        Mix_FreeMusic(m_music);
        m_music = NULL;
    }

    m_musicTrack = musicFile;

    if (wasPlayingMusic)
        startMusic();
}


void SDLInteraction::startMusic()
{
    if (m_isPlayingMusic)
        return;

    m_isPlayingMusic = true;

    if (m_musicTrack.isEmpty())
        return;

    SDLAudioInit();
    if (!m_audioInitialized) return;

    if (m_music == NULL)
        m_music = Mix_LoadMUS_RW(PHYSFSRWOPS_openRead(m_musicTrack.toLocal8Bit().constData()), 0);

    Mix_VolumeMusic(MIX_MAX_VOLUME/4);
    Mix_FadeInMusic(m_music, -1, 1750);
}


void SDLInteraction::stopMusic()
{
    if (m_isPlayingMusic && (m_music != NULL))
    {
        // fade out music to finish 0,5 seconds from now
        while(!Mix_FadeOutMusic(1000) && Mix_PlayingMusic())
        {
            SDL_Delay(100);
        }
    }

    m_isPlayingMusic = false;
}


QSize SDLInteraction::getCurrentResolution()
{
    SDL_DisplayMode mode;

    SDL_GetDesktopDisplayMode(0, &mode);

    return QSize(mode.w, mode.h);
}
