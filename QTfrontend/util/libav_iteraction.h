/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef LIBAV_ITERACTION
#define LIBAV_ITERACTION

#include <QComboBox>

/**
 * @brief Class for interacting with ffmpeg/libav libraries
 *
 * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
 */
class LibavIteraction
{
    LibavIteraction();

public:

    static LibavIteraction & instance();

    void FillFormats(QComboBox * pFormats);
    void FillCodecs(const QVariant & format, QComboBox * pVCodecs, QComboBox * pACodecs);
};

#endif // LIBAV_ITERACTION
