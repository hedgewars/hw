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

#include "hwform_ui.h"

#include <QGridLayout>
#include <QMainWindow>
#include <QStackedLayout>
#include <QVBoxLayout>

#include "hwconsts.h"
#include "hwform.h"
#include "pageadmin.h"
#include "pagecampaign.h"
#include "pageconnecting.h"
#include "pagedata.h"
#include "pagedrawmap.h"
#include "pageeditteam.h"
#include "pagegamestats.h"
#include "pageinfo.h"
#include "pageingame.h"
#include "pagemain.h"
#include "pagemultiplayer.h"
#include "pagenet.h"
#include "pagenetgame.h"
#include "pagenetserver.h"
#include "pageoptions.h"
#include "pageplayrecord.h"
#include "pageroomslist.h"
#include "pagescheme.h"
#include "pageselectweapon.h"
#include "pagesingleplayer.h"
#include "pagetraining.h"
#include "pagevideos.h"

void Ui_HWForm::setupUi(HWForm *HWForm)
{
    SetupFonts();

    HWForm->setObjectName(QStringLiteral("HWForm"));
    HWForm->resize(QSize(640, 480).expandedTo(HWForm->minimumSizeHint()));
    HWForm->setMinimumSize(QSize(720, 450));
    QString title = QMainWindow::tr("Hedgewars %1").arg(cVersionString);
#ifdef QT_DEBUG
    title += QStringLiteral("-r%1 (%2)").arg(cRevisionString, cHashString);
#endif
    HWForm->setWindowTitle(title);
    centralWidget = new QWidget(HWForm);
    centralWidget->setObjectName(QStringLiteral("centralWidget"));

    SetupPages(centralWidget);

    HWForm->setCentralWidget(centralWidget);

    Pages->setCurrentIndex(0);

    QMetaObject::connectSlotsByName(HWForm);
}

void Ui_HWForm::SetupFonts()
{
    font14 = new QFont(QStringLiteral("MS Shell Dlg"), 14);
}

void Ui_HWForm::SetupPages(QWidget *Parent)
{
    Pages = new QStackedLayout(Parent);

    pageEditTeam = new PageEditTeam(Parent);
    Pages->addWidget(pageEditTeam);

    pageOptions = new PageOptions();
    Pages->addWidget(pageOptions);

    pageMultiplayer = new PageMultiplayer();
    Pages->addWidget(pageMultiplayer);

    pagePlayDemo = new PagePlayDemo();
    Pages->addWidget(pagePlayDemo);

    pageNet = new PageNet();
    Pages->addWidget(pageNet);

    pageNetGame = new PageNetGame(Parent);
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

    pageRoomsList = new PageRoomsList(Parent);
    Pages->addWidget(pageRoomsList);

    pageConnecting = new PageConnecting();
    Pages->addWidget(pageConnecting);

    pageScheme = new PageScheme();
    Pages->addWidget(pageScheme);

    pageAdmin = new PageAdmin();
    Pages->addWidget(pageAdmin);

    pageCampaign = new PageCampaign();
    Pages->addWidget(pageCampaign);

    pageDrawMap = new PageDrawMap();
    Pages->addWidget(pageDrawMap);

    pageDataDownload = new PageDataDownload();
    Pages->addWidget(pageDataDownload);

    pageVideos = new PageVideos();
    Pages->addWidget(pageVideos);
}
