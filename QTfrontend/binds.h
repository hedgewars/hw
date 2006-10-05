/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef BINDS_H
#define BINDS_H

#include <QString>
#include <QtGlobal>

#define BINDS_NUMBER 29

struct BindAction
{
	QString action;
	QString strbind;
	const char * name;
	bool chwidget;
};

const BindAction cbinds[BINDS_NUMBER] =
{
	{"+up",	"up",	QT_TRANSLATE_NOOP("binds", "up"),	false},
	{"+left",	"left",	QT_TRANSLATE_NOOP("binds", "left"),	false},
	{"+right",	"right",	QT_TRANSLATE_NOOP("binds", "right"),	false},
	{"+down",	"down",	QT_TRANSLATE_NOOP("binds", "down"),	false},
	{"ljump",	"return",	QT_TRANSLATE_NOOP("binds", "jump"),	false},
	{"hjump",	"backspace",	QT_TRANSLATE_NOOP("binds", "jump"),	false},
	{"+attack",	"space",	QT_TRANSLATE_NOOP("binds", "attack"),	false},
	{"put",	"mousel",	QT_TRANSLATE_NOOP("binds", "put"),	false},
	{"switch",	"tab",	QT_TRANSLATE_NOOP("binds", "switch"),	false},
	{"findhh",	"h",	QT_TRANSLATE_NOOP("binds", "find hedgehog"),	true},
	{"ammomenu",	"mouser",	QT_TRANSLATE_NOOP("binds", "ammo menu"),	false},
	{"slot 1",	"f1",	QT_TRANSLATE_NOOP("binds", "slot 1"),	false},
	{"slot 2",	"f2",	QT_TRANSLATE_NOOP("binds", "slot 2"),	false},
	{"slot 3",	"f3",	QT_TRANSLATE_NOOP("binds", "slot 3"),	false},
	{"slot 4",	"f4",	QT_TRANSLATE_NOOP("binds", "slot 4"),	false},
	{"slot 5",	"f5",	QT_TRANSLATE_NOOP("binds", "slot 5"),	false},
	{"slot 6",	"f6",	QT_TRANSLATE_NOOP("binds", "slot 6"),	false},
	{"slot 7",	"f7",	QT_TRANSLATE_NOOP("binds", "slot 7"),	false},
	{"slot 8",	"f8",	QT_TRANSLATE_NOOP("binds", "slot 8"),	true},
	{"timer 1",	"1",	QT_TRANSLATE_NOOP("binds", "timer 1 sec"),	false},
	{"timer 2",	"2",	QT_TRANSLATE_NOOP("binds", "timer 2 sec"),	false},
	{"timer 3",	"3",	QT_TRANSLATE_NOOP("binds", "timer 3 sec"),	false},
	{"timer 4",	"4",	QT_TRANSLATE_NOOP("binds", "timer 4 sec"),	false},
	{"timer 5",	"5",	QT_TRANSLATE_NOOP("binds", "timer 5 sec"),	true},
	{"+voldown",	"9",	QT_TRANSLATE_NOOP("binds", "volume down"),	false},
	{"+volup",	"0",	QT_TRANSLATE_NOOP("binds", "volume up"),	false},
	{"fullscr",	"f",	QT_TRANSLATE_NOOP("binds", "change mode"),	false},
	{"capture",	"c",	QT_TRANSLATE_NOOP("binds", "capture"),	false},
	{"quit",	"escape",	QT_TRANSLATE_NOOP("binds", "quit"),	true}
};

#endif // BINDS_H
