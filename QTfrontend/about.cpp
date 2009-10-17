/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QTextBrowser>
#include "about.h"
#include "hwconsts.h"

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
			QLabel::tr("This program is distributed under the GNU General Public License") +
			"</div>"
			);
	lbl1->setWordWrap(true);
	mainLayout->addWidget(lbl1, 0, 1);

	QTextBrowser *lbl2 = new QTextBrowser(this);

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
			"Mac OS X port, OpenAL wrapper library: Vittorio Giovara &lt;<a href=\"mailto:vittorio.giovara@gmail.com\">vittorio.giovara@gmail.com</a>&gt;<br>"
			"Gamepad support and additional effects: Mario Liebisch &lt;<a href=\"mailto:mario.liebisch+hw@googlemail.com\">mario.liebisch+hw@googlemail.com</a>&gt;"
			"</p><h2>" +

			QLabel::tr("Art:") + "</h2>"
			+ QString::fromUtf8(
			"<p>Finn Brice &lt;<a href=\"mailto:tiyuri@gmail.com\">tiyuri@gmail.com</a>&gt;"
			"<br>"
			"Joshua Frese &lt;<a href=\"mailto:joshfrese@gmail.com\">joshfrese@gmail.com</a>&gt;"
			"<br>"
			"Stanko Tadić &lt;<a href=\"mailto:stanko@mfhinc.net\">stanko@mfhinc.net</a>&gt;"
			"<br>"
			"Julien Koesten &lt;<a href=\"mailto:julienkoesten@aol.com\">julienkoesten@aol.com</a>&gt;"
			"<br>"
			"Joshua O'Sullivan &lt;<a href=\"mailto:battysausage@hotmail.co.uk\">battysausage@hotmail.co.uk</a>&gt;"
			"<br>"
			"Nils Lück &lt;<a href=\"mailto:nils.luck.design@gmail.com\">nils.luck.design@gmail.com</a>&gt;"
			"<br>"
			"Hats: Trey Perry &lt;<a href=\"mailto:tx.perry.j@gmail.com\">tx.perry.j@gmail.com</a>&gt;"
			"</p><h2>") +
			QLabel::tr("Sounds:") + "</h2>"
			"Hedgehogs voice: Stephen Alexander &lt;<a href=\"mailto:ArmagonNo1@gmail.com\">ArmagonNo1@gmail.com</a>&gt;"
			"<br>"
			"Finn Brice &lt;<a href=\"mailto:tiyuri@gmail.com\">tiyuri@gmail.com</a>&gt;"
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
			"German: Peter Hüwe &lt;<a href=\"mailto:PeterHuewe@gmx.de\">PeterHuewe@gmx.de</a>&gt;<br>"
			"Italian: Luca Bonora &lt;<a href=\"mailto:bonora.luca@gmail.com\">bonora.luca@gmail.com</a>&gt;<br>"
			"Japanese: ADAM Etienne &lt;<a href=\"mailto:etienne.adam@gmail.com\">etienne.adam@gmail.com</a>&gt;<br>"
			"Polish: Maciej Mroziński &lt;<a href=\"mailto:mynick2@o2.pl\">mynick2@o2.pl</a>&gt;, Wojciech Latkowski &lt;<a href=\"mailto:magik_15l@poczta.fm\">magik_15l@poczta.fm</a>&gt;, Maciej Górny<br>"
			"Russian: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"Slovak: Jose Riha<br>"
			"Spanish: Carlos Vives &lt;<a href=\"mailto:mail@carlosvives.es\">mail@carlosvives.es</a>&gt;<br>"
			"Swedish: Niklas Grahn &lt;<a href=\"mailto:raewolusjoon@yaoo.com\">raewolusjoon@yaoo.com</a>&gt;<br>"
			"Ukrainian: Eugene V. Lyubimkin &lt;<a href=\"mailto:jackyf.devel@gmail.com\">jackyf.devel@gmail.com</a>&gt;"
			"</p><h2>") +

			QLabel::tr("Special thanks:") + "</h2><p>"
			"Aleksey Andreev &lt;<a href=\"mailto:blaknayabr@gmail.com\">blaknayabr@gmail.com</a>&gt;<br>"
			"Aleksander Rudalev &lt;<a href=\"mailto:alexv@pomorsu.ru\">alexv@pomorsu.ru</a>&gt;<br>"
			"Natasha Stafeeva &lt;<a href=\"mailto:layout@pisem.net\">layout@pisem.net</a>&gt;<br>"
			"Adam Higerd (aka ahigerd at FreeNode)"
			"</p>"
			);
	mainLayout->addWidget(lbl2, 1, 1);
}
