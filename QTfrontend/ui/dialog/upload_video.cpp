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
#include <QMessageBox>
#include <QRegExp>
#include <QRegExpValidator>

#include "upload_video.h"
#include "hwconsts.h"

// User-agent string used in http requests.
// Don't make it a global varibale - crash on linux because of cVersionString
#define USER_AGENT ("Hedgewars-QtFrontend/" + *cVersionString).toLatin1()

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
        "<p>By clicking 'upload,' you certify that you own all rights to the content or that "
        "you are authorized by the owner to make the content publicly available on YouTube, "
        "and that it otherwise complies with the YouTube Terms of Service located at "
        "<a href=\"https://www.youtube.com/t/terms\" style=\"color: white;\">https://www.youtube.com/t/terms</a>.</p>";

    // youtube doesn't understand this characters, even when they are properly escaped
    // (either with CDATA or with &lt or &gt)
    QRegExp rx("[^<>]*");

    int row = 0;

    QGridLayout * layout = new QGridLayout(this);
    layout->setColumnStretch(0, 1);
    layout->setColumnStretch(1, 2);

    QLabel * lbLabel = new QLabel(this);
    lbLabel->setWordWrap(true);
    lbLabel->setText(QLabel::tr(
                         "Please provide either the YouTube account name "
                         "or the email address associated with the Google Account."));
    layout->addWidget(lbLabel, row++, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Account name (or email): "));
    layout->addWidget(lbLabel, row, 0);

    leAccount = new QLineEdit(this);
    layout->addWidget(leAccount, row++, 1);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Password: "));
    layout->addWidget(lbLabel, row, 0);

    lePassword = new QLineEdit(this);
    lePassword->setEchoMode(QLineEdit::Password);
    layout->addWidget(lePassword, row++, 1);

    cbSave = new QCheckBox(this);
    cbSave->setText(QCheckBox::tr("Save account name and password"));
    layout->addWidget(cbSave, row++, 0, 1, 2);

    QFrame * hr = new QFrame(this);
    hr->setFrameStyle(QFrame::HLine);
    hr->setLineWidth(3);
    hr->setFixedHeight(10);
    layout->addWidget(hr, row++, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Video title: "));
    layout->addWidget(lbLabel, row, 0);

    leTitle = new QLineEdit(this);
    leTitle->setText(filename);
    leTitle->setValidator(new QRegExpValidator(rx, leTitle));
    layout->addWidget(leTitle, row++, 1);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Video description: "));
    layout->addWidget(lbLabel, row++, 0, 1, 2);

    teDescription = new QPlainTextEdit(this);
    layout->addWidget(teDescription, row++, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("Tags (comma separated): "));
    layout->addWidget(lbLabel, row, 0);

    leTags = new QLineEdit(this);
    leTags->setText("hedgewars");
    leTags->setMaxLength(500);
    leTags->setValidator(new QRegExpValidator(rx, leTags));
    layout->addWidget(leTags, row++, 1);

    cbPrivate = new QCheckBox(this);
    cbPrivate->setText(QCheckBox::tr("Video is private"));
    layout->addWidget(cbPrivate, row++, 0, 1, 2);

    hr = new QFrame(this);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        layout->addWidget(hr, row++, 0, 1, 2);

    lbLabel = new QLabel(this);
    lbLabel->setWordWrap(true);
    lbLabel->setTextInteractionFlags(Qt::LinksAccessibleByMouse);
    lbLabel->setTextFormat(Qt::RichText);
    lbLabel->setOpenExternalLinks(true);
    lbLabel->setText(GoogleNotice);
    layout->addWidget(lbLabel, row++, 0, 1, 2);

    QDialogButtonBox* dbbButtons = new QDialogButtonBox(this);
    btnUpload = dbbButtons->addButton(tr("Upload"), QDialogButtonBox::ActionRole);
    QPushButton * pbCancel = dbbButtons->addButton(QDialogButtonBox::Cancel);
    layout->addWidget(dbbButtons, row++, 0, 1, 2);

   /* hr = new QFrame(this);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        layout->addWidget(hr, row++, 0, 1, 2);*/

    connect(btnUpload, SIGNAL(clicked()), this, SLOT(upload()));
    connect(pbCancel, SIGNAL(clicked()), this, SLOT(reject()));

    this->setWindowModality(Qt::WindowModal);
}

void HWUploadVideoDialog::showEvent(QShowEvent * event)
{
    QDialog::showEvent(event);

    // set width to the same value as height (otherwise dialog has too small width)
    QSize s = size();
    QPoint p = pos();
    resize(s.height(), s.height());
    move(p.x() - (s.height() - s.width())/2, p.y());
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

    // Documentation is at https://developers.google.com/youtube/2.0/developers_guide_protocol_clientlogin#ClientLogin_Authentication
    QNetworkRequest request;
    request.setUrl(QUrl("https://www.google.com/accounts/ClientLogin"));
    request.setRawHeader("User-Agent", USER_AGENT);
    request.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    QString account(QUrl::toPercentEncoding(leAccount->text()));
    QString pass(QUrl::toPercentEncoding(lePassword->text()));
    QByteArray data = QString("Email=%1&Passwd=%2&service=youtube&source=Hedgewars").arg(account).arg(pass).toUtf8();

    QNetworkReply *reply = netManager->post(request, data);
    connect(reply, SIGNAL(finished()), this, SLOT(authFinished()));
}

static QString XmlEscape(const QString& str)
{
    QString str2 = str;
    // youtube doesn't understand this characters, even when they are properly escaped
    // (either with CDATA or with &lt; &gt;)
    str2.replace('<', ' ').replace('>', ' ');
    return "<![CDATA[" + str2.replace("]]>", "]]]]><![CDATA[>") + "]]>";
}

void HWUploadVideoDialog::authFinished()
{
    QNetworkReply *reply = (QNetworkReply*)sender();
    reply->deleteLater();

    int HttpCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

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
        QString errorStr = QMessageBox::tr("Error while authenticating at google.com:\n");
        if (HttpCode == 403)
            errorStr += QMessageBox::tr("Login or password is incorrect");
        else
            errorStr += reply->errorString();

        QMessageBox deniedMsg(this);
        deniedMsg.setIcon(QMessageBox::Warning);
        deniedMsg.setWindowTitle(QMessageBox::tr("Video upload - Error"));
        deniedMsg.setText(errorStr);
        deniedMsg.setWindowModality(Qt::WindowModal);
        deniedMsg.exec();

        setEditable(true);
        return;
    }

    QByteArray auth = ("GoogleLogin auth=" + authToken).toLatin1();

    // We have authenticated, now we can send metadata and start upload
    // Documentation is here: https://developers.google.com/youtube/2.0/developers_guide_protocol_resumable_uploads#Resumable_uploads
    QByteArray body =
            "<?xml version=\"1.0\"?>"
            "<entry xmlns=\"http://www.w3.org/2005/Atom\" "
                "xmlns:media=\"http://search.yahoo.com/mrss/\" "
                "xmlns:yt=\"http://gdata.youtube.com/schemas/2007\">"
                "<media:group>"
                  //  "<yt:incomplete/>"
                    "<media:category "
                        "scheme=\"http://gdata.youtube.com/schemas/2007/categories.cat\">Games"
                    "</media:category>"
                    "<media:title type=\"plain\">"
                        + XmlEscape(leTitle->text()).toUtf8() +
                    "</media:title>"
                    "<media:description type=\"plain\">"
                        + XmlEscape(teDescription->toPlainText()).toUtf8() +
                    "</media:description>"
                    "<media:keywords type=\"plain\">"
                        + XmlEscape(leTags->text()).toUtf8() +
                    "</media:keywords>"
                    + (cbPrivate->isChecked()? "<yt:private/>" : "") +
                "</media:group>"
            "</entry>";

    QNetworkRequest request;
    request.setUrl(QUrl("http://uploads.gdata.youtube.com/resumable/feeds/api/users/default/uploads"));
    request.setRawHeader("User-Agent", USER_AGENT);
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

    location = QString::fromLatin1(reply->rawHeader("Location"));
    if (location.isEmpty())
    {
        QString errorStr = QMessageBox::tr("Error while sending metadata to youtube.com:\n");
        errorStr += reply->errorString();

        QMessageBox deniedMsg(this);
        deniedMsg.setIcon(QMessageBox::Warning);
        deniedMsg.setWindowTitle(QMessageBox::tr("Video upload - Error"));
        deniedMsg.setText(errorStr);
        deniedMsg.setWindowModality(Qt::WindowModal);
        deniedMsg.exec();

        setEditable(true);
        return;
    }

    accept();
}
