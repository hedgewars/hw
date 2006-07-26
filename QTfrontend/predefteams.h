/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef PREDEFTEAMS_H
#define PREDEFTEAMS_H

#include <QtGlobal>

#define PREDEFTEAMS_COUNT 2

struct PredefinedTeam
{
	const char * TeamName;
	const char * hh0name;
	const char * hh1name;
	const char *  hh2name;
	const char *  hh3name;
	const char *  hh4name;
	const char *  hh5name;
	const char *  hh6name;
	const char *  hh7name;
	QString Grave;
	QString Fort;
};


const PredefinedTeam pteams[PREDEFTEAMS_COUNT] =
{
	{
		QT_TRANSLATE_NOOP("teams", "Hedgehogs"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 1"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 2"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 3"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 4"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 5"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 6"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 7"),
		QT_TRANSLATE_NOOP("teams", "hedgehog 8"),
		"Simple", "Island"
	},
	{
		QT_TRANSLATE_NOOP("teams", "Goddess"),
		QT_TRANSLATE_NOOP("teams", "Isis"),
		QT_TRANSLATE_NOOP("teams", "Astarte"),
		QT_TRANSLATE_NOOP("teams", "Diana"),
		QT_TRANSLATE_NOOP("teams", "Aphrodite"),
		QT_TRANSLATE_NOOP("teams", "Hecate"),
		QT_TRANSLATE_NOOP("teams", "Demeter"),
		QT_TRANSLATE_NOOP("teams", "Kali"),
		QT_TRANSLATE_NOOP("teams", "Inanna"),
		"Bone", "Island"
	}
};

#endif // PREDEFTEAMS_H
