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

#include <QLineEdit>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QGridLayout>
#include <QCheckBox>
#include <QLabel>
#include <QFrame>
#include <QPlainTextEdit>
#include <QSslError>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include "upload_video.h"
#include "hwconsts.h"

// User-agent string used in http requests.
static const QByteArray UserAgent = ("Hedgewars-QtFrontend/" + *cVersionString).toAscii();

// This is developer key obtained from http://code.google.com/apis/youtube/dashboard/
// If you are reusing this code outside Hedgewars, don't use this developer key,
// obtain you own at http://code.google.com/apis/youtube/dashboard/
static const QByteArray devKey = "AI39si5pKjxR0XgNIlmrEFF-LyYD31rps4g2O5dZTxLgD0fvJ2rHxrMrNFY8FYTZrzeI3VlaFVQLKfFnSBugvdZmy8vFzRDefQ";

HWUploadVideoDialog::HWUploadVideoDialog(QWidget* parent, const QString &filename, QNetworkAccessManager* netManager) : QDialog(parent)
{
    this->filename = filename;
    this->netManager = netManager;

    setWindowTitle(tr("Upload video"));

    // Google requires us to display this, see https://developers.google.com/youtube/terms
    QString GoogleNotice =
        "By clicking 'upload,' you certify that you own all rights to the content or that\n"
        "you are authorized by the owner to make the content publicly available on YouTube,\n"
        "and that it otherwise complies with the YouTube Terms of Service located at\n"
        "http://www.youtube.com/t/terms.";

    QGridLayout * layout = new QGridLayout(this);

    QLabel * lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr(
                         "Please provide either the YouTube account name\n"
                         "or the email address associated with the Google Account."));
    layout->addWidget(lbLabel, 0, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Account name (or email): "));
    layout->addWidget(lbLabel, 1, 0);

    leAccount = new QLineEdit(this);
    layout->addWidget(leAccount, 1, 1);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Password: "));
    layout->addWidget(lbLabel, 2, 0);

    lePassword = new QLineEdit(this);
    lePassword->setEchoMode(QLineEdit::Password);
    layout->addWidget(lePassword, 2, 1);

    cbSave = new QCheckBox(this);
    cbSave->setText(QCheckBox::tr("Save account name and password"));
    layout->addWidget(cbSave, 3, 0, 1, 2);

    QFrame * hr = new QFrame(this);
    hr->setFrameStyle(QFrame::HLine);
    hr->setLineWidth(3);
    hr->setFixedHeight(10);
    layout->addWidget(hr, 4, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Video title: "));
    layout->addWidget(lbLabel, 5, 0);

    leTitle = new QLineEdit(this);
    leTitle->setText(filename);
    layout->addWidget(leTitle, 5, 1);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Video description: "));
    layout->addWidget(lbLabel, 6, 0, 1, 2);

    teDescription = new QPlainTextEdit(this);
    layout->addWidget(teDescription, 7, 0, 1, 2);

    hr = new QFrame(this);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        layout->addWidget(hr, 8, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(GoogleNotice);
    layout->addWidget(lbLabel, 9, 0, 1, 2);

    labelLog = new QLabel(this);
    layout->addWidget(labelLog, 10, 0, 1, 2);

    QDialogButtonBox* dbbButtons = new QDialogButtonBox(this);
    btnUpload = dbbButtons->addButton(tr("Upload"), QDialogButtonBox::ActionRole);
    QPushButton * pbCancel = dbbButtons->addButton(QDialogButtonBox::Cancel);
    layout->addWidget(dbbButtons, 11, 0, 1, 2);

    connect(btnUpload, SIGNAL(clicked()), this, SLOT(upload()));
    connect(pbCancel, SIGNAL(clicked()), this, SLOT(reject()));
}

void HWUploadVideoDialog::log(const QString& text)
{
    labelLog->setText(labelLog->text() + text);
}

void HWUploadVideoDialog::setEditable(bool editable)
{
    leTitle->setEnabled(editable);
    leAccount->setEnabled(editable);
    lePassword->setEnabled(editable);
    btnUpload->setEnabled(editable);
}

void HWUploadVideoDialog::upload()
{
    setEditable(false);

    labelLog->clear();
    log(tr("Authenticating at www.google.com... "));

    // Documentation is at https://developers.google.com/youtube/2.0/developers_guide_protocol_clientlogin#ClientLogin_Authentication
    QNetworkRequest request;
    request.setUrl(QUrl("https://www.google.com/accounts/ClientLogin"));
    request.setRawHeader("User-Agent", UserAgent);
    request.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    QString account(QUrl::toPercentEncoding(leAccount->text()));
    QString pass(QUrl::toPercentEncoding(lePassword->text()));
    QByteArray data = QString("Email=%1&Passwd=%2&service=youtube&source=Hedgewars").arg(account).arg(pass).toAscii();

    QNetworkReply *reply = netManager->post(request, data);
    connect(reply, SIGNAL(finished()), this, SLOT(authFinished()));
}

QString XmlEscape(const QString& str)
{
    QString str2 = str;
    return "<![CDATA[" + str2.replace("]]>", "]]]]><![CDATA[>") + "]]>";
}

void HWUploadVideoDialog::authFinished()
{
    QNetworkReply *reply = (QNetworkReply*)sender();
    reply->deleteLater();

    QByteArray answer = reply->readAll();
    QString authToken = "";
    QList<QByteArray> lines = answer.split('\n');
    foreach (const QByteArray& line, lines)
    {
        QString str(line);
        if (!str.startsWith("Auth=", Qt::CaseInsensitive))
            continue;
        str.remove(0, 5);
        authToken = str;
        break;
    }
    if (authToken.isEmpty())
    {
        log(tr("failed\n"));
        log(reply->errorString() + "\n");
        setEditable(true);
        return;
    }
    log(tr("Ok\n"));

    log(tr("Sending metadata... "));

    QByteArray auth = ("GoogleLogin auth=" + authToken).toAscii();

    // We have authenticated, now we can send metadata and start upload
    // Documentation is here: https://developers.google.com/youtube/2.0/developers_guide_protocol_resumable_uploads#Resumable_uploads
    QByteArray body =
            "<?xml version=\"1.0\"?>"
            "<entry xmlns=\"http://www.w3.org/2005/Atom\" "
                "xmlns:media=\"http://search.yahoo.com/mrss/\" "
                "xmlns:yt=\"http://gdata.youtube.com/schemas/2007\">"
                "<media:group>"
                    "<yt:incomplete/>"
                    "<media:category "
                        "scheme=\"http://gdata.youtube.com/schemas/2007/categories.cat\">Games"
                    "</media:category>"
                    "<media:title type=\"plain\">"
                        + XmlEscape(leTitle->text()).toUtf8() +
                    "</media:title>"
                "</media:group>"
            "</entry>";

    QNetworkRequest request;
    request.setUrl(QUrl("http://uploads.gdata.youtube.com/resumable/feeds/api/users/default/uploads"));
    request.setRawHeader("User-Agent", UserAgent);
    request.setRawHeader("Authorization", auth);
    request.setRawHeader("GData-Version", "2");
    request.setRawHeader("X-GData-Key", "key=" + devKey);
    request.setRawHeader("Slug", filename.toUtf8());
    request.setRawHeader("Content-Type", "application/atom+xml; charset=UTF-8");

    reply = netManager->post(request, body);
    connect(reply, SIGNAL(finished()), this, SLOT(startUpload()));
}

void HWUploadVideoDialog::startUpload()
{
    QNetworkReply *reply = (QNetworkReply*)sender();
    reply->deleteLater();

    location = QString::fromAscii(reply->rawHeader("Location"));
    if (location.isEmpty())
    {
        log(tr("failed\n"));
        log(reply->errorString() + "\n");
        setEditable(true);
        return;
    }

    log(tr("Ok\n"));
    accept();
}
