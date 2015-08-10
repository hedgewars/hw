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

#ifndef UPLOAD_VIDEO_H
#define UPLOAD_VIDEO_H

#include <QDialog>

class QLineEdit;
class QCheckBox;
class QPlainTextEdit;
class QLabel;
class QNetworkAccessManager;

class HWUploadVideoDialog : public QDialog
{
        Q_OBJECT
    public:
    HWUploadVideoDialog(QWidget* parent, const QString& filename, QNetworkAccessManager* netManager);

        QLineEdit* leAccount;
        QLineEdit* lePassword;
        QCheckBox* cbSave;

        QLineEdit* leTitle;
        QPlainTextEdit* teDescription;
        QLineEdit* leTags;
        QCheckBox* cbPrivate;

        QPushButton* btnUpload;

        QString location;

    private:
        QNetworkAccessManager* netManager;
        QString filename;

        void setEditable(bool editable);

    protected:
        // virtual from QWidget
        void showEvent(QShowEvent * event);

    private slots:
        void upload();
        void authFinished();
        void startUpload();
};

#endif // UPLOAD_VIDEO_H
