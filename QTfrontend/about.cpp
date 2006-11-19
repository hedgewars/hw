/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QScrollArea>
#include "about.h"

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
			"<div align=\"center\"><h1>Hedgewars</h1>" +
			QLabel::tr("<h3>Version 0.8</h3>") +
			"<p><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p><br>" +
			QLabel::tr("This program is distributed under the GNU General Public License") +
			"</div>"
			);
	lbl1->setWordWrap(true);
	mainLayout->addWidget(lbl1, 0, 1);

	QScrollArea *sa = new QScrollArea(this);
	sa->setWidgetResizable(true);
	sa->setFrameStyle(QFrame::NoFrame);
	QLabel *lbl2 = new QLabel(this);

	lbl2->setOpenExternalLinks(true);
	lbl2->setText(
			QLabel::tr("<h2>Developers:</h2>") +
			"<p>"
			"Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"Igor Ulyanov &lt;<a href=\"mailto:iulyanov@gmail.com\">iulyanov@gmail.com</a>&gt;"
			"</p>" +
			QLabel::tr("<h2>Translations:</h2><p>") +
			"english: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;<br>"
			"russian: Andrey Korotaev &lt;<a href=\"mailto:unC0Rr@gmail.com\">unC0Rr@gmail.com</a>&gt;"
			"</p>" +
			QLabel::tr("<h2>Special thanks:</h2><p>") +
			"Aleksey Andreev &lt;<a href=\"mailto:blaknayabr@gmail.com\">blaknayabr@gmail.com</a>&gt;<br>"
			"Natasha Stafeeva &lt;<a href=\"mailto:layout@pisem.net\">layout@pisem.net</a>&gt;"
			"</p>" +
			QLabel::tr("<h2></h2><p></p>")
			);
	lbl2->setWordWrap(true);
	sa->setWidget(lbl2);
	mainLayout->addWidget(sa, 1, 1);
}
