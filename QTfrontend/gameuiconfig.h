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

#ifndef GAMECONFIG_H
#define GAMECONFIG_H

#include <QSettings>
#include <QStringList>
#include <QRect>
#include <QEvent>
#include <QList>
#include <utility>
#include "binds.h"

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
        std::pair<QRect, QRect> vid_ResolutionPair();
        bool vid_Fullscreen();
        quint32 translateQuality();
        bool isSoundEnabled();
        bool isFrontendSoundEnabled();
        QString language();
        bool isMusicEnabled();
        bool isFrontendMusicEnabled();
        bool isAudioDampenEnabled();
        bool isShowFPSEnabled();
        bool isAltDamageEnabled();
        bool appendDateTimeToRecordName();
        quint8 volume();
        quint8 timerInterval();
        QString netNick();
        QByteArray netPasswordHash();
        int netPasswordLength();
        void clearPasswordHash();
        void setPasswordHash(const QString & passwordhash);
        QString passwordHash();
        void clearTempHash();
        void setTempHash(const QString & temphash);
        QString tempHash();
        void setNetPasswordLength(int passwordLength);
        bool isReducedQuality() const;
        bool isFrontendEffects() const;
        bool isFrontendFullscreen() const;
        bool isHolidaySillinessEnabled() const;
        void resizeToConfigValues();
        quint32 stereoMode() const;
        void setValue(const QString & key, const QVariant & value);
        QString bind(int bindID);
        void setBind(int bindID, QString & strbind);

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
        QString temphash;
        QList<BindAction> m_binds;

        void applyProxySettings();
};

#endif
