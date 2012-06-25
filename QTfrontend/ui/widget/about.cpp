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
    lbl2->setText(
        "<style type=\"text/css\">"
        "a { color: #ffcc00; }"
//            "a:hover { color: yellow; }"
        "</style>" +
        QString("<h2>") +
        QLabel::tr("Developers:") +
        "</h2><p>"
        "Engine, frontend, net server: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
        "Many frontend improvements: Igor Ulyanov &lt;<a href=\"mailto:disinbox@gmail.com\">disinbox@gmail.com</a>&gt;<br>"
        "Many engine and frontend improvements: Derek Pomery &lt;<a href=\"mailto:nemo@m8y.org\">nemo@m8y.org</a>&gt;<br>"
        "Drill rocket, Ballgun, RC Plane weapons: Martin Boze &lt;<a href=\"mailto:afffect@gmail.com\">afffect@gmail.com</a>&gt;<br>"
        "Mine number and time game settings: David A. Cuadrado &lt;<a href=\"mailto:krawek@gmail.com\">krawek@gmail.com</a>&gt;<br>"
        "Frontend improvements: Martin Minarik &lt;<a href=\"mailto:ttsmj@pokec.sk\">ttsmj@pokec.sk</a>&gt;<br>"
        "Frontend improvements: Kristian Lehmann &lt;<a href=\"mailto:email@thexception.net\">email@thexception.net</a>&gt;<br>"
        "Mac OS X/iPhone port, OpenGL-ES conversion: Vittorio Giovara &lt;<a href=\"mailto:vittorio.giovara@gmail.com\">vittorio.giovara@gmail.com</a>&gt;<br>"
        "Many engine and frontend improvements (and bugs): Richard Karolyi &lt;<a href=\"mailto:sheepluva@" "ercatec.net\">sheepluva@" "ercatec.net</a>&gt;<br>"
        "Gamepad and Lua integration: Mario Liebisch &lt;<a href=\"mailto:mario.liebisch@gmail.com\">mario.liebisch@gmail.com</a>&gt;<br>"
        "Many engine improvements and graphics: Carlos Vives &lt;<a href=\"mailto:mail@carlosvives.es\">mail@carlosvives.es</a>&gt;<br>"
        "Maze maps: Henning K&uuml;hn &lt;<a href=\"mailto:prg@cooco.de\">prg@cooco.de</a>&gt;<br>"
        "Engine and frontend improvements: Henrik Rostedt &lt;<a href=\"mailto:henrik.rostedt@gmail.com\">henrik.rostedt@gmail.com</a>&gt;<br>"
        "Lua game modes and missions: John Lambert &lt;<a href=\"mailto:redgrinner@gmail.com\">redgrinner@gmail.com</a>&gt;<br>"
        "Frontend improvements: Mayur Pawashe &lt;<a href=\"mailto:zorgiepoo@gmail.com\">zorgiepoo@gmail.com</a>&gt;<br>"
        "Android port: Richard Deurwaarder &lt;<a href=\"mailto:xeli@xelification.com\">xeli@xelification.com</a>&gt;<br>"
        "</p><h2>" +

        QLabel::tr("Art:") + "</h2>"
        + QString::fromUtf8(
            "<p>John Dum &lt;<a href=\"mailto:fizzy@gmail.com\">fizzy@gmail.com</a>&gt;"
            "<br>"
            "Joshua Frese &lt;<a href=\"mailto:joshfrese@gmail.com\">joshfrese@gmail.com</a>&gt;"
            "<br>"
            "Stanko Tadić &lt;<a href=\"mailto:stanko@mfhinc.net\">stanko@mfhinc.net</a>&gt;"
            "<br>"
            "Julien Koesten &lt;<a href=\"mailto:julienkoesten@aol.com\">julienkoesten@aol.com</a>&gt;"
            "<br>"
            "Joshua O'Sullivan &lt;<a href=\"mailto:coheedftw@hotmail.co.uk\">coheedftw@hotmail.co.uk</a>&gt;"
            "<br>"
            "Nils Lück &lt;<a href=\"mailto:nils.luck.design@gmail.com\">nils.luck.design@gmail.com</a>&gt;"
            "<br>"
            "Guillaume Englert &lt;<a href=\"mailto:genglert@hybird.org\">genglert@hybird.org</a>&gt;"
            "<br>"
            "Hats: Trey Perry &lt;<a href=\"mailto:tx.perry.j@gmail.com\">tx.perry.j@gmail.com</a>&gt;"
            "</p><h2>") +
        QLabel::tr("Sounds:") + "</h2>"
        "Hedgehogs voice: Stephen Alexander &lt;<a href=\"mailto:ArmagonNo1@gmail.com\">ArmagonNo1@gmail.com</a>&gt;"
        "<br>"
        "John Dum &lt;<a href=\"mailto:fizzy@gmail.com\">fizzy@gmail.com</a>&gt;"
        "<br>"
        "Jonatan Nilsson &lt;<a href=\"mailto:jonatanfan@gmail.com\">jonatanfan@gmail.com</a>&gt;"
        "<br>"
        "Daniel Martin &lt;<a href=\"mailto:elhombresinremedio@gmail.com\">elhombresinremedio@gmail.com</a>&gt;"
        "</p><h2>" +

        QLabel::tr("Translations:") + "</h2><p>"
        + QString::fromUtf8(
            "Brazilian Portuguese: Romulo Fernandes Machado &lt;<a href=\"mailto:abra185@gmail.com\">abra185@gmail.com</a>&gt;<br>"
            "Bulgarian: Svetoslav Stefanov<br>"
            "Czech: Petr Řezáček &lt;<a href=\"mailto:rezacek@gmail.com\">rezacek@gmail.com</a>&gt;<br>"
            "Chinese: Jie Luo &lt;<a href=\"mailto:lililjlj@gmail.com\">lililjlj@gmail.com</a>&gt;<br>"
            "English: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
            "Finnish: Nina Kuisma &lt;<a href=\"mailto:ninnnu@gmail.com\">ninnnu@gmail.com</a>&gt;<br>"
            "French: Antoine Turmel &lt;<a href=\"mailto:geekshadow@gmail.com\">geekshadow@gmail.com</a>&gt;<br>"
            "German: Peter Hüwe &lt;<a href=\"mailto:PeterHuewe@gmx.de\">PeterHuewe@gmx.de</a>&gt;, Mario Liebisch &lt;<a href=\"mailto:mario.liebisch@gmail.com\">mario.liebisch@gmail.com</a>&gt;, Richard Karolyi &lt;<a href=\"mailto:sheepluva@" "ercatec.net\">sheepluva@" "ercatec.net</a>&gt;<br>"
            "Greek: &lt;<a href=\"mailto:talos_kriti@yahoo.gr\">talos_kriti@yahoo.gr</a>&gt;<br>"
            "Italian: Luca Bonora &lt;<a href=\"mailto:bonora.luca@gmail.com\">bonora.luca@gmail.com</a>&gt;, Marco Bresciani<br>"
            "Japanese: ADAM Etienne &lt;<a href=\"mailto:etienne.adam@gmail.com\">etienne.adam@gmail.com</a>&gt;<br>"
            "Korean: Anthony Bellew &lt;<a href=\"mailto:anthonyreflected@gmail.com\">anthonyreflected@gmail.com</a>&gt;<br>"
            "Lithuanian: Lukas Urbonas &lt;<a href=\"mailto:lukasu08@gmail.com\">lukasu08@gmail.com</a>&gt;<br>"
            "Polish: Maciej Mroziński &lt;<a href=\"mailto:mynick2@o2.pl\">mynick2@o2.pl</a>&gt;, Wojciech Latkowski &lt;<a href=\"mailto:magik17l@gmail.com\">magik17l@gmail.com</a>&gt;, Piotr Mitana, Maciej Górny<br>"
            "Portuguese: Fábio Canário &lt;<a href=\"mailto:inufabie@gmail.com\">inufabie@gmail.com</a>&gt;<br>"
            "Russian: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
            "Slovak: Jose Riha<br>"
            "Spanish: Carlos Vives &lt;<a href=\"mailto:mail@carlosvives.es\">mail@carlosvives.es</a>&gt;<br>"
            "Swedish: Niklas Grahn &lt;<a href=\"mailto:raewolusjoon@yaoo.com\">raewolusjoon@yaoo.com</a>&gt;, Henrik Rostedt &lt;<a href=\"mailto:henrik.rostedt@gmail.com\">henrik.rostedt@gmail.com</a>&gt;<br>"
            "Ukrainian: Eugene V. Lyubimkin &lt;<a href=\"mailto:jackyf.devel@gmail.com\">jackyf.devel@gmail.com</a>&gt;, Igor Paliychuk &lt;<a href=\"mailto:mansonigor@gmail.com\">mansonigor@gmail.com</a>&gt;, Eugene Sakara &lt;<a href=\"mailto:eresid@gmail.com\">eresid@gmail.com</a>&gt;"
            "</p><h2>") +

        QLabel::tr("Special thanks:") + "</h2><p>"
        "Aleksey Andreev &lt;<a href=\"mailto:blaknayabr@gmail.com\">blaknayabr@gmail.com</a>&gt;<br>"
        "Aleksander Rudalev &lt;<a href=\"mailto:alexv@pomorsu.ru\">alexv@pomorsu.ru</a>&gt;<br>"
        "Natasha Korotaeva &lt;<a href=\"mailto:layout@pisem.net\">layout@pisem.net</a>&gt;<br>"
        "Adam Higerd (aka ahigerd at FreeNode)"
        "</p>"
    );
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
