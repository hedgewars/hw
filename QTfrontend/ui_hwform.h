/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef UI_HWFORM_H
#define UI_HWFORM_H

class PageMain;
class PageEditTeam;
class PageMultiplayer;
class PagePlayDemo;
class PageOptions;
class PageNet;
class PageNetServer;
class PageNetChat;
class PageNetGame;
class PageInfo;
class PageGameStats;
class PageSinglePlayer;
class PageTraining;
class PageCampaign;
class PageSelectWeapon;
class PageInGame;
class PageRoomsList;
class PageConnecting;
class PageScheme;
class PageAdmin;
class PageNetType;
class PageDrawMap;
class QStackedLayout;
class QFont;
class QWidget;
class QMainWindow;
class HWForm;

class Ui_HWForm
{
public:
    QWidget *centralWidget;

    PageMain *pageMain;
    PageEditTeam *pageEditTeam;
    PageMultiplayer *pageMultiplayer;
    PagePlayDemo *pagePlayDemo;
    PageOptions *pageOptions;
    PageNet *pageNet;
    PageNetServer * pageNetServer;
    PageNetChat *pageNetChat;
    PageNetGame *pageNetGame;
    PageInfo *pageInfo;
    PageGameStats *pageGameStats;
    PageSinglePlayer *pageSinglePlayer;
    PageTraining *pageTraining;
    PageSelectWeapon *pageSelectWeapon;
    PageInGame *pageInGame;
    PageRoomsList *pageRoomsList;
    PageConnecting *pageConnecting;
    PageScheme *pageScheme;
    PageAdmin *pageAdmin;
    PageNetType *pageNetType;
    PageCampaign *pageCampaign;
    PageDrawMap *pageDrawMap;

    QStackedLayout *Pages;
    QFont *font14;

    void setupUi(HWForm *HWForm);
    void SetupFonts();
    void SetupPages(QWidget *Parent, HWForm *HWForm);
};

#endif // UI_HWFORM_H
