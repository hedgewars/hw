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


#ifndef PAGE_VIDEOS_H
#define PAGE_VIDEOS_H

#include "AbstractPage.h"

class GameUIConfig;
class HWRecorder;
class VideoItem;
class HWForm;

class PageVideos : public AbstractPage
{
        Q_OBJECT

    public:
        PageVideos(QWidget* parent = 0);

        void addRecorder(HWRecorder* pRecorder);
        bool tryQuit(HWForm *form);
        QString getVideosInProgress(); // get multi-line string with list of videos in progress
        void startEncoding(const QByteArray & record = QByteArray());
        void init(GameUIConfig * config);

    private:
        // virtuals from AbstractPage
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

        // virtual from QWidget
        void keyPressEvent(QKeyEvent * pEvent);

        void setName(VideoItem * item, const QString & newName);
        void updateSize(int row);
        int appendRow(const QString & name);
        VideoItem* nameItem(int row);
        void play(int row);
        void updateDescription();
        void clearTemp();
        void clearThumbnail();
        void setProgress(int row, VideoItem* item, float value);

        GameUIConfig * config;

        // file list group
        QTableWidget *filesTable;
        QPushButton *btnOpenDir;

        // description group
        QPushButton *btnPlay, *btnDelete;
        QLabel *labelDesc;
        QLabel *labelThumbnail;

        // this flag is used to distinguish if cell was changed from code or by user
        // (in signal cellChanged)
        bool nameChangedFromCode;

        int numRecorders;

    private slots:
        void encodingFinished(bool success);
        void updateProgress(float value);
        void cellDoubleClicked(int row, int column);
        void cellChanged(int row, int column);
        void currentCellChanged();
        void playSelectedFile();
        void deleteSelectedFiles();
        void openVideosDirectory();
        void updateFileList(const QString & path);
        void ShowFatalErrorMessage(const QString & msg);
};

#endif // PAGE_VIDEOS_H
