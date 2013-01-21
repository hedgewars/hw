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

#include <QDialog>
#include <QVBoxLayout>
#include <QScrollArea>
#include <QPushButton>
#include <QToolButton>
#include <QWidgetItem>
#include <QModelIndex>
#include <QLabel>

#include "flowlayout.h"
#include "DataManager.h"
#include "ThemeModel.h"
#include "themeprompt.h"

ThemePrompt::ThemePrompt(QWidget* parent) : QDialog(parent)
{
	setModal(true);
	setWindowFlags(Qt::Sheet);
	setWindowModality(Qt::WindowModal);
	setMinimumSize(550, 430);
	resize(550, 430);
	setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);

	// Grid
	QVBoxLayout * dialogLayout = new QVBoxLayout(this);
	dialogLayout->setSpacing(0);

	// Help/prompt message at top
	QLabel * lblDesc = new QLabel(tr("Select a theme for this map"));
    lblDesc->setStyleSheet("color: #130F2A; background: #F6CB1C; border: solid 4px #F6CB1C; border-top-left-radius: 10px; border-top-right-radius: 10px; padding: auto 20px;");
    lblDesc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    lblDesc->setFixedHeight(24);
    lblDesc->setMinimumWidth(0);

	// Scroll area and container for theme icons
	QWidget * themesContainer = new QWidget();
	FlowLayout * themesGrid = new FlowLayout();
	themesContainer->setLayout(themesGrid);
	QScrollArea * scrollArea = new QScrollArea();
    scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    scrollArea->setObjectName("scrollArea");
    scrollArea->setStyleSheet("QScrollBar, #scrollArea { background-color: #130F2A; } #scrollArea { border-color: #F6CB1C; border-width: 3px; border-top-width: 0; border-style: solid; border-bottom-left-radius: 10px; border-bottom-right-radius: 10px; }");
    scrollArea->setWidgetResizable(true);
    scrollArea->setFrameShape(QFrame::NoFrame);
    scrollArea->setWidget(themesContainer);

	// Cancel button (closes dialog)
	QPushButton * btnCancel = new QPushButton(tr("Cancel"));
	btnCancel->setStyleSheet("padding: 5px; margin-top: 10px;");
	connect(btnCancel, SIGNAL(clicked()), this, SLOT(reject()));

	// Add elements to layouts
	dialogLayout->addWidget(lblDesc, 0);
	dialogLayout->addWidget(scrollArea, 1);
	dialogLayout->addWidget(btnCancel, 0, Qt::AlignLeft);

	// Tooltip label for theme name
	lblToolTip = new QLabel(this);

	// Add theme buttons
	ThemeModel * themes = DataManager::instance().themeModel();
	for (int i = 0; i < themes->rowCount(); i++)
	{
		QModelIndex index = themes->index(i, 0);
		QToolButton * btn = new QToolButton();
		bool dlc = themes->data(index, Qt::UserRole + 2).toBool();
		btn->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
		btn->setIcon(qVariantValue<QIcon>(themes->data(index, Qt::UserRole)));
		btn->setText((dlc ? "*" : "") + themes->data(index, Qt::DisplayRole).toString());
		btn->setIconSize(QSize(60, 60));
		btn->setProperty("themeID", QVariant(i));
		btn->setStyleSheet("padding: 2px;");
		connect(btn, SIGNAL(clicked()), this, SLOT(themeClicked()));
		themesGrid->addWidget(btn);
	}
}

// When a theme is selected
void ThemePrompt::themeClicked()
{
	QWidget * btn = (QWidget*)sender();
	done(btn->property("themeID").toInt() + 1); // Since returning 0 means canceled
}
