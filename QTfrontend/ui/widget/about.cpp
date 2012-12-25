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

#include <QGridLayout>
#include <QLabel>
#include <QList>
#include <QUrl>
#include <QRegExp>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDebug>
#include "hwconsts.h"
#include "SDLInteraction.h"

#include "about.h"

About::About(QWidget * parent) :
    QWidget(parent)
{
    QGridLayout *mainLayout = new QGridLayout(this);

    QLabel *imageLabel = new QLabel;
    QImage image(":/res/Hedgehog.png");
    imageLabel->setPixmap(QPixmap::fromImage(image));
    imageLabel->setScaledContents(true);
    imageLabel->setMinimumWidth(2.8);
    imageLabel->setMaximumWidth(280);
    imageLabel->setMinimumHeight(30);
    imageLabel->setMaximumHeight(300);

    mainLayout->addWidget(imageLabel, 0, 0, 2, 1);

    QLabel *lbl1 = new QLabel(this);
    lbl1->setOpenExternalLinks(true);
    lbl1->setText(
        "<style type=\"text/css\">"
        "a { color: #ffcc00; }"
//            "a:hover { color: yellow; }"
        "</style>"
        "<div align=\"center\"><h1>Hedgewars</h1>"
        "<h3>" + QLabel::tr("Version") + " " + *cVersionString + "</h3>"
        "<p><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p><br>" +
        QLabel::tr("This program is distributed under the GNU General Public License v2") +
        "</div>"
    );
    lbl1->setWordWrap(true);
    mainLayout->addWidget(lbl1, 0, 1);

    lbl2 = new QTextBrowser(this);
    lbl2->setOpenExternalLinks(true);
    QUrl localpage = QUrl::fromLocalFile(":/res/html/about.html");
    lbl2->setSource(localpage); //sets the source of the label from the file above
    mainLayout->addWidget(lbl2, 1, 1);

    setAcceptDrops(true);
}

void About::dragEnterEvent(QDragEnterEvent * event)
{
    if (event->mimeData()->hasUrls())
    {
        QList<QUrl> urls = event->mimeData()->urls();
        QString url = urls[0].toString();
        if (urls.count() == 1)
            if (url.contains(QRegExp("^file://.*\\.ogg$")))
                event->acceptProposedAction();
    }
}

void About::dropEvent(QDropEvent * event)
{
    QString file =
        event->mimeData()->urls()[0].toString().remove(QRegExp("^file://"));

    SDLInteraction::instance().setMusicTrack(file);

    event->acceptProposedAction();
}
