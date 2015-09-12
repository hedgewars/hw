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

#ifndef FEEDBACKDIALOG_H
#define FEEDBACKDIALOG_H

#include <QDialog>

class QNetworkReply;
class QNetworkAccessManager;
class QCheckBox;
class QLineEdit;
class QTextBrowser;
class QLabel;

class FeedbackDialog : public QDialog
{
        Q_OBJECT

    public:
        FeedbackDialog(QWidget * parent = 0);
        void EmbedSystemInfo();
        void LoadCaptchaImage();

        QPushButton * BtnSend;
        QPushButton * BtnViewInfo;
        QCheckBox * CheckSendSpecs;
        QLineEdit * summary;
        QTextBrowser * description;
        QLabel * info;
        QLabel * label_summary;
        QLabel * label_description;
        QLabel * label_captcha;
        QLabel * label_email;
        QLabel * label_captcha_input;
        QLineEdit * captcha_code;
        QLineEdit * email;
        int captchaID;
        QString specs;

    private:
        void GenerateSpecs();
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        QNetworkAccessManager * GetNetManager();
        void ShowErrorMessage(const QString & msg);

        QNetworkAccessManager * netManager;
        QNetworkReply * captchaImageRequest;
        QNetworkReply * genCaptchaRequest;
        QNetworkAccessManager * nam;

    private slots:
        virtual void NetReply(QNetworkReply*);
        virtual void ShowSpecs();
        void SendFeedback();
        void finishedSlot(QNetworkReply* reply);
};

#endif // FEEDBACKDIALOG_H
