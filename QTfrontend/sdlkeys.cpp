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

#include "sdlkeys.h"

#include <QtGlobal>

char sdlkeys[1024][2][128] =
{
    {"mousel", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: Left button")},
    {"mousem", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: Middle button")},
    {"mouser", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: Right button")},
    {"mousex1", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: X1 button ")},
    {"mousex2", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: X2 button")},
    {"wheelup", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: Wheel up")},
    {"wheeldown", QT_TRANSLATE_NOOP("binds (keys)", "Mouse: Wheel down")},
    {"backspace", QT_TRANSLATE_NOOP("binds (keys)", "Backspace")},
    {"tab", QT_TRANSLATE_NOOP("binds (keys)", "Tab")},
    {"clear", QT_TRANSLATE_NOOP("binds (keys)", "Clear")},
    {"return", QT_TRANSLATE_NOOP("binds (keys)", "Return")},
    {"pause", QT_TRANSLATE_NOOP("binds (keys)", "Pause")},
    {"escape", QT_TRANSLATE_NOOP("binds (keys)", "Escape")},
    {"space", QT_TRANSLATE_NOOP("binds (keys)", "Space")},
    {"!", "!"},
    {"\"", "\""},
    {"#", "#"},
    {"$", "$"},
    {"&", "&"},
    {"'", "'"},
    {"(", "("},
    {")", ")"},
    {"*", "*"},
    {"+", "+"},
    {",", ","},
    {"-", "-"},
    {".", "."},
    {"/", "/"},
    {"0", "0"},
    {"1", "1"},
    {"2", "2"},
    {"3", "3"},
    {"4", "4"},
    {"5", "5"},
    {"6", "6"},
    {"7", "7"},
    {"8", "8"},
    {"9", "9"},
    {":", ":"},
    {";", ";"},
    {"<", "<"},
    {"=", "="},
    {">", ">"},
    {"?", "?"},
    {"@", "@"},
    {"[", "["},
    {"\\", "\\"},
    {"]", "]"},
    {"^", "^"},
    {"_", "_"},
    {"`", "`"},
    {"a", "A"},
    {"b", "B"},
    {"c", "C"},
    {"d", "D"},
    {"e", "E"},
    {"f", "F"},
    {"g", "G"},
    {"h", "H"},
    {"i", "I"},
    {"j", "J"},
    {"k", "K"},
    {"l", "L"},
    {"m", "M"},
    {"n", "N"},
    {"o", "O"},
    {"p", "P"},
    {"q", "Q"},
    {"r", "R"},
    {"s", "S"},
    {"t", "T"},
    {"u", "U"},
    {"v", "V"},
    {"w", "W"},
    {"x", "X"},
    {"y", "Y"},
    {"z", "Z"},
    {"delete", QT_TRANSLATE_NOOP("binds (keys)", "Delete")},
    {"keypad_0", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 0")},
    {"keypad_1", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 1")},
    {"keypad_2", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 2")},
    {"keypad_3", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 3")},
    {"keypad_4", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 4")},
    {"keypad_5", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 5")},
    {"keypad_6", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 6")},
    {"keypad_7", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 7")},
    {"keypad_8", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 8")},
    {"keypad_9", QT_TRANSLATE_NOOP("binds (keys)", "Keypad 9")},
    {"keypad_.", QT_TRANSLATE_NOOP("binds (keys)", "Keypad .")},
    {"keypad_/", QT_TRANSLATE_NOOP("binds (keys)", "Keypad /")},
    {"keypad_*", QT_TRANSLATE_NOOP("binds (keys)", "Keypad *")},
    {"keypad_-", QT_TRANSLATE_NOOP("binds (keys)", "Keypad -")},
    {"keypad_+", QT_TRANSLATE_NOOP("binds (keys)", "Keypad +")},
    {"keypad_enter", QT_TRANSLATE_NOOP("binds (keys)", "Keypad Enter")},
    {"up", QT_TRANSLATE_NOOP("binds (keys)", "Up")},
    {"down", QT_TRANSLATE_NOOP("binds (keys)", "Down")},
    {"right", QT_TRANSLATE_NOOP("binds (keys)", "Right")},
    {"left", QT_TRANSLATE_NOOP("binds (keys)", "Left")},
    {"insert", QT_TRANSLATE_NOOP("binds (keys)", "Insert")},
    {"home", QT_TRANSLATE_NOOP("binds (keys)", "Home")},
    {"end", QT_TRANSLATE_NOOP("binds (keys)", "End")},
    {"pageup", QT_TRANSLATE_NOOP("binds (keys)", "PageUp")},
    {"pagedown", QT_TRANSLATE_NOOP("binds (keys)", "PageDown")},
    {"f1", "F1"},
    {"f2", "F2"},
    {"f3", "F3"},
    {"f4", "F4"},
    {"f5", "F5"},
    {"f6", "F6"},
    {"f7", "F7"},
    {"f8", "F8"},
    {"f9", "F9"},
    {"f10", "F10"},
    {"f11", "F11"},
    {"f12", "F12"},
    {"f13", "F13"},
    {"f14", "F14"},
    {"f15", "F15"},
    {"numlock", QT_TRANSLATE_NOOP("binds (keys)", "Numlock")},
    {"capslock", QT_TRANSLATE_NOOP("binds (keys)", "CapsLock")},
    {"scrolllock", QT_TRANSLATE_NOOP("binds (keys)", "ScrollLock")},
    {"right_shift", QT_TRANSLATE_NOOP("binds (keys)", "Right Shift")},
    {"left_shift", QT_TRANSLATE_NOOP("binds (keys)", "Left Shift")},
    {"right_ctrl", QT_TRANSLATE_NOOP("binds (keys)", "Right Ctrl")},
    {"left_ctrl", QT_TRANSLATE_NOOP("binds (keys)", "Left Ctrl")},
    {"right_alt", QT_TRANSLATE_NOOP("binds (keys)", "Right Alt")},
    {"left_alt", QT_TRANSLATE_NOOP("binds (keys)", "Left Alt")},
    //: Windows key / Command key / Meta key /Super key (right)
    {"right_gui", QT_TRANSLATE_NOOP("binds (keys)", "Right GUI")},
    //: Windows key / Command key / Meta key /Super key (left)
    {"left_gui", QT_TRANSLATE_NOOP("binds (keys)", "Left GUI")}
};

// button name definitions for Microsoft's XBox360 controller
// don't modify button order!
char xb360buttons[10][128] =
{
    QT_TRANSLATE_NOOP("binds (keys)", "A button"),
    QT_TRANSLATE_NOOP("binds (keys)", "B button"),
    QT_TRANSLATE_NOOP("binds (keys)", "X button"),
    QT_TRANSLATE_NOOP("binds (keys)", "Y button"),
    QT_TRANSLATE_NOOP("binds (keys)", "LB button"),
    QT_TRANSLATE_NOOP("binds (keys)", "RB button"),
    QT_TRANSLATE_NOOP("binds (keys)", "Back button"),
    QT_TRANSLATE_NOOP("binds (keys)", "Start button"),
    QT_TRANSLATE_NOOP("binds (keys)", "Left stick"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right stick")
};

// axis name definitions for Microsoft's XBox360 controller
// don't modify axis order!
char xbox360axes[][128] =
{
    QT_TRANSLATE_NOOP("binds (keys)", "Left stick (Right)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Left stick (Left)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Left stick (Down)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Left stick (Up)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Left trigger"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right trigger"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right stick (Down)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right stick (Up)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right stick (Right)"),
    QT_TRANSLATE_NOOP("binds (keys)", "Right stick (Left)"),
};
char xb360dpad[128] = QT_TRANSLATE_NOOP("binds (keys)", "D-pad");

// Generic controller binding names
//: Game controller axis direction. %1 = axis number, %2 = direction
char controlleraxis[128] = QT_TRANSLATE_NOOP("binds (keys)", "Axis %1 %2");
//: Game controller button. %1 = button number
char controllerbutton[128] = QT_TRANSLATE_NOOP("binds (keys)", "Button %1");
//: Game controller D-pad button. %1 = D-pad number, %2 = direction
char controllerhat[128] = QT_TRANSLATE_NOOP("binds (keys)", "D-pad %1 %2");
char controllerup[128] = QT_TRANSLATE_NOOP("binds (keys)", "Up");
char controllerdown[128] = QT_TRANSLATE_NOOP("binds (keys)", "Down");
char controllerleft[128] = QT_TRANSLATE_NOOP("binds (keys)", "Left");
char controllerright[128] = QT_TRANSLATE_NOOP("binds (keys)", "Right");

//: Special entry in key selection when an action has no control assigned
char unboundcontrol[128] = QT_TRANSLATE_NOOP("binds (keys)", "(Don't use)");

