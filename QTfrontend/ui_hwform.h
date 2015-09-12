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
class PageDataDownload;
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
class PageDrawMap;
class PageVideos;
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
        PageDataDownload *pageDataDownload;
        PageGameStats *pageGameStats;
        PageSinglePlayer *pageSinglePlayer;
        PageTraining *pageTraining;
        PageSelectWeapon *pageSelectWeapon;
        PageInGame *pageInGame;
        PageRoomsList *pageRoomsList;
        PageConnecting *pageConnecting;
        PageScheme *pageScheme;
        PageAdmin *pageAdmin;
        PageCampaign *pageCampaign;
        PageDrawMap *pageDrawMap;
        PageVideos *pageVideos;

        QStackedLayout *Pages;
        QFont *font14;

        void setupUi(HWForm *HWForm);
        void SetupFonts();
        void SetupPages(QWidget *Parent);
};

#endif // UI_HWFORM_H
