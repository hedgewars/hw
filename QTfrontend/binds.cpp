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

#include "binds.h"

const BindAction cbinds[BINDS_NUMBER] =
{
    {"+up",       "up",         QT_TRANSLATE_NOOP("binds", "up"),              QT_TRANSLATE_NOOP("binds (categories)", "Movement"), QT_TRANSLATE_NOOP("binds (descriptions)", "Hedgehog movement")},
    {"+left",     "left",       QT_TRANSLATE_NOOP("binds", "left"),            NULL, NULL},
    {"+right",    "right",      QT_TRANSLATE_NOOP("binds", "right"),           NULL, NULL},
    {"+down",     "down",       QT_TRANSLATE_NOOP("binds", "down"),            NULL, NULL},
    {"+precise",  "left_shift", QT_TRANSLATE_NOOP("binds", "precise aim"),     NULL, NULL},
    {"ljump",     "return",     QT_TRANSLATE_NOOP("binds", "long jump"),       NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Traverse gaps and obstacles by jumping:")},
    {"hjump",     "backspace",  QT_TRANSLATE_NOOP("binds", "high jump"),       NULL, NULL},
    {"switch",    "tab",        QT_TRANSLATE_NOOP("binds", "switch"),          NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Switch your currently active hog (if possible):")},
    {"ammomenu",  "mouser",     QT_TRANSLATE_NOOP("binds", "ammo menu"),       QT_TRANSLATE_NOOP("binds (categories)", "Weapons"), QT_TRANSLATE_NOOP("binds (descriptions)", "Pick a weapon or utility item:")},
    {"slot 1",    "f1",         QT_TRANSLATE_NOOP("binds", "slot 1"),          NULL, NULL},
    {"slot 2",    "f2",         QT_TRANSLATE_NOOP("binds", "slot 2"),          NULL, NULL},
    {"slot 3",    "f3",         QT_TRANSLATE_NOOP("binds", "slot 3"),          NULL, NULL},
    {"slot 4",    "f4",         QT_TRANSLATE_NOOP("binds", "slot 4"),          NULL, NULL},
    {"slot 5",    "f5",         QT_TRANSLATE_NOOP("binds", "slot 5"),          NULL, NULL},
    {"slot 6",    "f6",         QT_TRANSLATE_NOOP("binds", "slot 6"),          NULL, NULL},
    {"slot 7",    "f7",         QT_TRANSLATE_NOOP("binds", "slot 7"),          NULL, NULL},
    {"slot 8",    "f8",         QT_TRANSLATE_NOOP("binds", "slot 8"),          NULL, NULL},
    {"slot 9",    "f9",         QT_TRANSLATE_NOOP("binds", "slot 9"),          NULL, NULL},
    {"slot :",    "f10",        QT_TRANSLATE_NOOP("binds", "slot 10"),         NULL, NULL},
    {"setweap ~", "none",       QT_TRANSLATE_NOOP("binds", "unselect weapon"), NULL, NULL},
    {"timer 1",   "1",          QT_TRANSLATE_NOOP("binds", "timer 1 sec"),     NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Set the timer on bombs and timed weapons:")},
    {"timer 2",   "2",          QT_TRANSLATE_NOOP("binds", "timer 2 sec"),     NULL, NULL},
    {"timer 3",   "3",          QT_TRANSLATE_NOOP("binds", "timer 3 sec"),     NULL, NULL},
    {"timer 4",   "4",          QT_TRANSLATE_NOOP("binds", "timer 4 sec"),     NULL, NULL},
    {"timer 5",   "5",          QT_TRANSLATE_NOOP("binds", "timer 5 sec"),     NULL, NULL},
    {"timer_u",   "n",          QT_TRANSLATE_NOOP("binds", "change timer"),    NULL, NULL},
    {"+attack",   "space",      QT_TRANSLATE_NOOP("binds", "attack"),          NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Fire your selected weapon or trigger an utility item:")},
    {"put",       "mousel",     QT_TRANSLATE_NOOP("binds", "put"),             NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Pick a weapon or a target location under the cursor:")},
    {"findhh",    "h",          QT_TRANSLATE_NOOP("binds", "autocam / find hedgehog"),QT_TRANSLATE_NOOP("binds (categories)", "Camera"), QT_TRANSLATE_NOOP("binds (descriptions)", "Toggle automatic camera / refocus on active hedgehog:")},
    {"+cur_u",    "keypad_8",   QT_TRANSLATE_NOOP("binds", "up"),              NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Move the cursor or camera without using the mouse:")},
    {"+cur_l",    "keypad_4",   QT_TRANSLATE_NOOP("binds", "left"),            NULL, NULL},
    {"+cur_r",    "keypad_6",   QT_TRANSLATE_NOOP("binds", "right"),           NULL, NULL},
    {"+cur_d",    "keypad_2",   QT_TRANSLATE_NOOP("binds", "down"),            NULL, NULL},
//  {"+cur_m",    "",           QT_TRANSLATE_NOOP("binds", "movement key modifier"),    NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Specify a modifier key to move camera and cursor using your default hog movement keys:")},
    {"zoomin",    "wheelup",    QT_TRANSLATE_NOOP("binds", "zoom in"),         NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Modify the camera's zoom level:")},
    {"zoomout",   "wheeldown",  QT_TRANSLATE_NOOP("binds", "zoom out"),        NULL, NULL},
    {"zoomreset", "mousem",     QT_TRANSLATE_NOOP("binds", "reset zoom"),      NULL, NULL},
    {"chat",      "t",          QT_TRANSLATE_NOOP("binds", "chat"),            QT_TRANSLATE_NOOP("binds (categories)", "Miscellaneous"), QT_TRANSLATE_NOOP("binds (descriptions)", "Talk to your clan or all participants:")},
    {"chat team", "u",          QT_TRANSLATE_NOOP("binds", "clan chat"),       NULL, NULL},
    {"history",   "`",          QT_TRANSLATE_NOOP("binds", "chat history"),    NULL, NULL},
    {"pause",     "p",          QT_TRANSLATE_NOOP("binds", "pause / auto skip"),NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Pause, continue or leave your game:")},
    {"quit",      "escape",     QT_TRANSLATE_NOOP("binds", "quit"),            NULL, NULL},
    {"confirm",   "y",          QT_TRANSLATE_NOOP("binds", "confirmation"),    NULL, NULL},
    {"+voldown",  "9",          QT_TRANSLATE_NOOP("binds", "volume down"),     NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Modify the game's volume while playing:")},
    {"+volup",    "0",          QT_TRANSLATE_NOOP("binds", "volume up"),       NULL, NULL},
    {"mute",      "8",          QT_TRANSLATE_NOOP("binds", "mute audio"),      NULL, NULL},
    {"fullscr",   "f12",        QT_TRANSLATE_NOOP("binds", "change mode"),     NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Toggle fullscreen mode:")},
    {"capture",   "c",          QT_TRANSLATE_NOOP("binds", "capture"),         NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Take a screenshot:")},
    {"+speedup",  "s",          QT_TRANSLATE_NOOP("binds", "speed up replay"),         NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Demo replay:")},
    {"+mission",  "m",          QT_TRANSLATE_NOOP("binds", "show mission information"), NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Heads-up display:")},
    //: This refers to the team info bars (name/flag/health) of all teams. These are shown at the bottom center of the screen
    {"rotmask",   "delete",     QT_TRANSLATE_NOOP("binds", "toggle team bars"), NULL, NULL},
    {"rottags",   "home",       QT_TRANSLATE_NOOP("binds", "toggle hedgehog tags"), NULL, NULL},
#ifdef VIDEOREC
    {"record",    "r",          QT_TRANSLATE_NOOP("binds", "record"),          NULL, QT_TRANSLATE_NOOP("binds (descriptions)", "Record video:")}
#endif
};
