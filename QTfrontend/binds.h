/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef BINDS_H
#define BINDS_H

#include <QString>
#include <QtGlobal>

#define BINDS_NUMBER 26

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
	{"switch",	"tab",	QT_TRANSLATE_NOOP("binds", "switch"),	true},
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
	{"fullscr",	"f",	QT_TRANSLATE_NOOP("binds", "change mode"),	false},
	{"capture",	"f11",	QT_TRANSLATE_NOOP("binds", "capture"),	false},
	{"quit",	"f10",	QT_TRANSLATE_NOOP("binds", "quit"),	true}
};

#endif // BINDS_H
