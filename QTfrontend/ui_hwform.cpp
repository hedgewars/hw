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

#include <QVBoxLayout>
#include <QGridLayout>
#include <QMainWindow>
#include <QStackedLayout>

#include "ui_hwform.h"
#include "hwform.h"
#include "pages.h"
#include "statsPage.h"
#include "playrecordpage.h"
#include "hwconsts.h"

void Ui_HWForm::setupUi(HWForm *HWForm)
{
	SetupFonts();

	HWForm->setObjectName(QString::fromUtf8("HWForm"));
	HWForm->resize(QSize(640, 480).expandedTo(HWForm->minimumSizeHint()));
	HWForm->setMinimumSize(QSize(720, 450));
	HWForm->setWindowTitle(QMainWindow::tr("Hedgewars %1").arg(*cVersionString));
	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	SetupPages(centralWidget, HWForm);

	HWForm->setCentralWidget(centralWidget);

	Pages->setCurrentIndex(0);

	QMetaObject::connectSlotsByName(HWForm);
}

void Ui_HWForm::SetupFonts()
{
	font14 = new QFont("MS Shell Dlg", 14);
}

void Ui_HWForm::SetupPages(QWidget *Parent, HWForm *HWForm)
{
	Pages = new QStackedLayout(Parent);

	pageEditTeam = new PageEditTeam(Parent, HWForm->sdli);
	Pages->addWidget(pageEditTeam);

	pageOptions = new PageOptions();
	Pages->addWidget(pageOptions);

	pageMultiplayer = new PageMultiplayer();
	Pages->addWidget(pageMultiplayer);

	pagePlayDemo = new PagePlayDemo();
	Pages->addWidget(pagePlayDemo);

	pageNet = new PageNet();
	Pages->addWidget(pageNet);

	pageNetGame = new PageNetGame();
	Pages->addWidget(pageNetGame);

	pageInfo = new PageInfo();
	Pages->addWidget(pageInfo);

	pageMain = new PageMain();
	Pages->addWidget(pageMain);

	pageGameStats = new PageGameStats();
	Pages->addWidget(pageGameStats);

	pageSinglePlayer = new PageSinglePlayer();
	Pages->addWidget(pageSinglePlayer);

	pageTraining = new PageTraining();
	Pages->addWidget(pageTraining);

	pageSelectWeapon = new PageSelectWeapon();
	Pages->addWidget(pageSelectWeapon);

	pageNetServer = new PageNetServer();
	Pages->addWidget(pageNetServer);

	pageInGame = new PageInGame();
	Pages->addWidget(pageInGame);

	pageRoomsList = new PageRoomsList();
	Pages->addWidget(pageRoomsList);

	pageConnecting = new PageConnecting();
	Pages->addWidget(pageConnecting);

	pageScheme = new PageScheme();
	Pages->addWidget(pageScheme);

	pageAdmin = new PageAdmin();
	Pages->addWidget(pageAdmin);

	pageNetType = new PageNetType();
	Pages->addWidget(pageNetType);
}
