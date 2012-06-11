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


#ifndef PAGE_VIDEOS_H
#define PAGE_VIDEOS_H

#include <QPushButton>
#include <QTableWidget>
#include "AbstractPage.h"

class GameUIConfig;

class PageVideos : public AbstractPage
{
        Q_OBJECT

    public:
        PageVideos(QWidget* parent = 0);

        QComboBox *CBAVFormats;
        QComboBox *CBVideoCodecs;
        QComboBox *CBAudioCodecs;
        QSpinBox  *framerateBox;
        QLineEdit *widthEdit;
        QLineEdit *heightEdit;
        QCheckBox *CBUseGameRes;
        QCheckBox *CBRecordAudio;

        QString getFormat()
        { return CBAVFormats->itemData(CBAVFormats->currentIndex()).toString(); }

        QString getVideoCodec()
        { return CBVideoCodecs->itemData(CBVideoCodecs->currentIndex()).toString(); }

        QString getAudioCodec()
        { return CBAudioCodecs->itemData(CBAudioCodecs->currentIndex()).toString(); }

        void setDefaultCodecs();
        bool tryCodecs(const QString & format, const QString & vcodec, const QString & acodec);

        GameUIConfig * config;

    signals:

    private:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

        QPushButton *BtnDefaults;
        QTableWidget *filesTable;

    private slots:
        void changeAVFormat(int index);
        void changeUseGameRes(int state);
        void changeRecordAudio(int state);
        void setDefaultOptions();
};

#endif // PAGE_VIDEOS_H
