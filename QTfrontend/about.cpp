/*
 * Hedgewars, a worms-like game
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
#include <QSvgWidget>
#include <QLabel>
#include <QTextBrowser>
#include "about.h"
#include "hwconsts.h"

About::About(QWidget * parent) :
  QWidget(parent)
{
	QGridLayout *mainLayout = new QGridLayout(this);
	QSvgWidget *hedgehog = new QSvgWidget(":/res/Hedgehog.svg", this);
	hedgehog->setFixedSize(300, 329);
	mainLayout->addWidget(hedgehog, 0, 0, 2, 1);

	QLabel *lbl1 = new QLabel(this);

	lbl1->setOpenExternalLinks(true);
	lbl1->setText(
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
	lbl2->setText(  QString("<h2>") +
			QLabel::tr("Developers:") +
			"</h2><p>"
			"Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"Igor Ulyanov &lt;<a href=\"mailto:disinbox@gmail.com\">disinbox@gmail.com</a>&gt;"
			"</p><h2>" +
			
			QLabel::tr("Art:") + "</h2>"
			"<p>All sprites, all themes except for 'Cheese' and 'Volcano': Finn Brice &lt;<a href=\"mailto:tiyuri@gmail.com\">tiyuri@gmail.com</a>&gt;"
			"<br>"
			"Volcano map and theme: Damion Brookes &lt;<a href=\"mailto:nintendo_wii33@hotmail.co.uk\">nintendo_wii33@hotmail.co.uk</a>&gt;"
			"</p><h2>" +
			
			QLabel::tr("Translations:") + "</h2><p>"
			"bulgarian: Svetoslav Stefanov"
			"english: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"italian: Luca Bonora &lt;<a href=\"mailto:bonora.luca@gmail.com\">bonora.luca@gmail.com</a>&gt;<br>"
			 + QString::fromUtf8("polish: Maciej Mroziński &lt;<a href=\"mailto:mynick2@o2.pl\">mynick2@o2.pl</a>&gt;<br>") +
			"russian: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"slovak: Jose Riha"
			"</p><h2>" +
			
			QLabel::tr("Special thanks:") + "</h2><p>"
			"Aleksey Andreev &lt;<a href=\"mailto:blaknayabr@gmail.com\">blaknayabr@gmail.com</a>&gt;<br>"
			"Aleksander Rudalev &lt;<a href=\"mailto:alexv@pomorsu.ru\">alexv@pomorsu.ru</a>&gt;<br>"
			"Natasha Stafeeva &lt;<a href=\"mailto:layout@pisem.net\">layout@pisem.net</a>&gt;<br>"
			"Adam Higerd (aka ahigerd at FreeNode)"
			"</p>"
			);
	mainLayout->addWidget(lbl2, 1, 1);
}
