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

 #ifndef UI_HWFORM_H
#define UI_HWFORM_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QCheckBox>
#include <QtGui/QComboBox>
#include <QtGui/QGroupBox>
#include <QtGui/QLabel>
#include <QtGui/QLineEdit>
#include <QtGui/QListWidget>
#include <QtGui/QMainWindow>
#include <QtGui/QPushButton>
#include <QtGui/QStackedWidget>
#include <QtGui/QToolBox>
#include <QtGui/QWidget>
#include <QStackedLayout>

class PageMain;
class PageLocalGame;
class PageEditTeam;
class PageMultiplayer;
class PagePlayDemo;
class PageOptions;
class PageNet;
class PageNetChat;
class PageNetGame;

class Ui_HWForm
{
public:
	QWidget *centralWidget;

	PageMain *pageMain;
	PageLocalGame *pageLocalGame;
	PageEditTeam *pageEditTeam;
	PageMultiplayer *pageMultiplayer;
	PagePlayDemo *pagePlayDemo;
	PageOptions *pageOptions;
	PageNet *pageNet;
	PageNetChat *pageNetChat;
	PageNetGame *pageNetGame;

	QStackedLayout *Pages;
	QFont *font14;

	void setupUi(QMainWindow *HWForm);
	void SetupFonts();
	void SetupPages(QWidget *Parent);
	void SetupPageNetChat(QWidget *Parent);
	void SetupPageNetGame(QWidget *Parent);
};

#endif // UI_HWFORM_H
