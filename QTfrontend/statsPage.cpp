/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QLabel>
#include <QGridLayout>

#include "statsPage.h"

PageGameStats::PageGameStats(QWidget* parent) : AbstractPage(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);

	labelGameStats = new QLabel(this);
	labelGameStats->setTextFormat(Qt::RichText);
	pageLayout->addWidget(labelGameStats, 0, 0, 1, 3);
}
