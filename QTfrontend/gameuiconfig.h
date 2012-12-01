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

#ifndef GAMECONFIG_H
#define GAMECONFIG_H

#include <QSettings>
#include <QStringList>
#include <QRect>
#include <QEvent>

class HWForm;
class QSettings;

class GameUIConfig : public QSettings
{
        Q_OBJECT

    public:
        HWForm * Form;
        GameUIConfig(HWForm * FormWidgets, const QString & fileName);
        QStringList GetTeamsList();
        QRect vid_Resolution();
        bool vid_Fullscreen();
        quint32 translateQuality();
        bool isSoundEnabled();
        bool isFrontendSoundEnabled();
        QString language();
        bool isMusicEnabled();
        bool isFrontendMusicEnabled();
        bool isShowFPSEnabled();
        bool isAltDamageEnabled();
        bool appendDateTimeToRecordName();
        quint8 volume();
        quint8 timerInterval();
        quint8 bitDepth();
        QString netNick();
        QByteArray netPasswordHash();
        int netPasswordLength();
        void setNetPasswordLength(int passwordLength);
        bool isReducedQuality() const;
        bool isFrontendEffects() const;
        bool isFrontendFullscreen() const;
        void resizeToConfigValues();
        quint32 stereoMode() const;
        void setValue(const QString & key, const QVariant & value);

        QString AVFormat();
        QString videoCodec();
        QString audioCodec();
        QRect rec_Resolution();
        int rec_Framerate();
        int rec_Bitrate();
        bool recordAudio();

#ifdef __APPLE__
#ifdef SPARKLE_ENABLED
        bool isAutoUpdateEnabled();
#endif
#endif
        void reloadValues();
        void reloadVideosValues();

    signals:
        void frontendFullscreen(bool value);

    public slots:
        void SaveOptions();
        void SaveVideosOptions();
        void updNetNick();
    private:
        bool netPasswordIsValid();
        bool eventFilter(QObject *object, QEvent *event);
        quint8 depth;
};

#endif
