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

#ifndef LIBAV_INTERACTION
#define LIBAV_INTERACTION

#include <QComboBox>

/**
 * @brief Class for interacting with ffmpeg/libav libraries
 *
 * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
 */
class LibavInteraction : public QObject
{
    Q_OBJECT;

    LibavInteraction();

public:

    static LibavInteraction & instance();

    // fill combo box with known file formats
    void fillFormats(QComboBox * pFormats);

    // fill combo boxes with known codecs for given formats
    void fillCodecs(const QString & format, QComboBox * pVCodecs, QComboBox * pACodecs);

    QString getExtension(const QString & format);

    // get information about file (duration, resolution etc) in multiline string
    QString getFileInfo(const QString & filepath);
};

#endif // LIBAV_INTERACTION
