/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <QGridLayout>
#include <QDir>
#include <QPushButton>
#include <QGroupBox>
#include <QComboBox>
#include <QLabel>
#include <QToolBox>
#include <QLineEdit>
#include <QListWidget>

#include "pages.h"
#include "sdlkeys.h"
#include "hwconsts.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "gamecfgwidget.h"

PageMain::PageMain(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	BtnSinglePlayer = new QPushButton(this);
	BtnSinglePlayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnSinglePlayer->setFont(*font14);
	BtnSinglePlayer->setText(QPushButton::tr("Single Player"));
	pageLayout->addWidget(BtnSinglePlayer, 1, 1);

	BtnMultiplayer = new QPushButton(this);
	BtnMultiplayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnMultiplayer->setFont(*font14);
	BtnMultiplayer->setText(QPushButton::tr("Multiplayer"));
	pageLayout->addWidget(BtnMultiplayer, 2, 1);

	BtnNet = new QPushButton(this);
	BtnNet->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnNet->setFont(*font14);
	BtnNet->setText(QPushButton::tr("Net game"));
	pageLayout->addWidget(BtnNet, 3, 1);

	BtnDemos = new QPushButton(this);
	BtnDemos->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnDemos->setFont(*font14);
	BtnDemos->setText(QPushButton::tr("Demos"));
	pageLayout->addWidget(BtnDemos, 4, 1);

	BtnSetup = new QPushButton(this);
	BtnSetup->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnSetup->setFont(*font14);
	BtnSetup->setText(QPushButton::tr("Setup"));
	pageLayout->addWidget(BtnSetup, 5, 1);

	BtnExit = new QPushButton(parent);
	BtnExit->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnExit->setFont(*font14);
	BtnExit->setText(QPushButton::tr("Exit"));
	pageLayout->addWidget(BtnExit, 6, 1);
}

PageLocalGame::PageLocalGame(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	BtnBack =	new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);
	BtnSimpleGame = new	QPushButton(this);
	BtnSimpleGame->setFont(*font14);
	BtnSimpleGame->setText(QPushButton::tr("Simple Game"));
	pageLayout->addWidget(BtnSimpleGame, 1, 3);
	gameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(gameCFG, 0, 0, 1, 2);
}

PageEditTeam::PageEditTeam(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	GBoxHedgehogs = new	QGroupBox(this);
	GBoxHedgehogs->setGeometry(QRect(20, 70, 161, 261));
	GBoxHedgehogs->setTitle(QGroupBox::tr("Team Members"));
	GBoxTeam = new QGroupBox(this);
	GBoxTeam->setGeometry(QRect(20, 10,	161, 51));
	GBoxTeam->setTitle(QGroupBox::tr("Team"));
	GBoxFort = new QGroupBox(this);
	GBoxFort->setGeometry(QRect(420, 110, 181, 221));
	GBoxFort->setTitle(QGroupBox::tr("Fort"));
	CBFort = new QComboBox(GBoxFort);
	CBFort->setGeometry(QRect(10, 20, 161, 21));
	CBFort->setMaxCount(65535);
	FortPreview	= new QLabel(GBoxFort);
	FortPreview->setGeometry(QRect(10, 50, 161,	161));
	FortPreview->setPixmap(QPixmap());
	FortPreview->setScaledContents(true);
	GBoxGrave =	new QGroupBox(this);
	GBoxGrave->setGeometry(QRect(420, 10, 181, 91));
	GBoxGrave->setTitle(QGroupBox::tr("Grave"));
	CBGrave = new QComboBox(GBoxGrave);
	CBGrave->setGeometry(QRect(10, 20, 161, 21));
	CBGrave->setMaxCount(65535);
	GravePreview = new QLabel(GBoxGrave);
	GravePreview->setGeometry(QRect(80,	50, 32,	32));
	GravePreview->setScaledContents(true);
	GBoxBinds =	new QGroupBox(this);
	GBoxBinds->setGeometry(QRect(200, 10, 201, 431));
	GBoxBinds->setTitle(QGroupBox::tr("Key binds"));
	BindsBox = new QToolBox(GBoxBinds);
	BindsBox->setGeometry(QRect(10, 20,	181, 401));
	BindsBox->setLineWidth(0);
	page_A = new QWidget();
	page_A->setGeometry(QRect(0, 0, 96,	26));
	BindsBox->addItem(page_A, QToolBox::tr("Actions"));
	page_W = new QWidget();
	BindsBox->addItem(page_W, QToolBox::tr("Weapons"));
	page_WP = new QWidget();
	BindsBox->addItem(page_WP, QToolBox::tr("Weapon properties"));
	page_O = new QWidget();
	page_O->setGeometry(QRect(0, 0, 96,	26));
	BindsBox->addItem(page_O, QToolBox::tr("Other"));
	BtnTeamDiscard = new QPushButton(this);
	BtnTeamDiscard->setGeometry(QRect(440, 380,	161, 41));
	BtnTeamDiscard->setFont(*font14);
	BtnTeamDiscard->setText(QPushButton::tr("Discard"));
	BtnTeamSave	= new QPushButton(this);
	BtnTeamSave->setGeometry(QRect(20, 380, 161, 41));
	BtnTeamSave->setFont(*font14);
	BtnTeamSave->setText(QPushButton::tr("Save"));

	TeamNameEdit = new QLineEdit(GBoxTeam);
	TeamNameEdit->setGeometry(QRect(10, 20, 141, 20));
	TeamNameEdit->setMaxLength(15);
	for(int i = 0; i < 8; i++)
	{
		HHNameEdit[i] = new QLineEdit(GBoxHedgehogs);
		HHNameEdit[i]->setGeometry(QRect(10, 20 + i * 30, 141, 20));
		HHNameEdit[i]->setMaxLength(15);
	}

	QStringList binds;
	for(int i = 0; strlen(sdlkeys[i][1]) > 0; i++)
	{
		binds << sdlkeys[i][1];
	}

	quint16 widind = 0, top = 0;
	for(quint8 i = 0; i < BINDS_NUMBER; i++)
	{
		LBind[i] = new QLabel(BindsBox->widget(widind));
		LBind[i]->setGeometry(QRect(10, top + 3, 70, 20));
		LBind[i]->setText(tr(cbinds[i].name));
		LBind[i]->setAlignment(Qt::AlignRight);
		CBBind[i] = new QComboBox(BindsBox->widget(widind));
		CBBind[i]->setGeometry(QRect(90, top, 80, 20));
		CBBind[i]->addItems(binds);
		if (cbinds[i].chwidget)
		{
			top = 0;
			widind++;
		} else
		{
			top += 28;
		}
	}

	QDir tmpdir;
	tmpdir.cd(DATA_PATH);
	tmpdir.cd("Forts");
	tmpdir.setFilter(QDir::Files);

	CBFort->addItems(tmpdir.entryList(QStringList("*L.png")).replaceInStrings(QRegExp("^(.*)L.png"), "\\1"));
	tmpdir.cd("../Graphics/Graves");
	QStringList list = tmpdir.entryList(QStringList("*.png"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		CBGrave->addItem((*it).replace(QRegExp("^(.*).png"), "\\1"));
	}

	connect(CBGrave, SIGNAL(activated(const QString &)), this, SLOT(CBGrave_activated(const QString &)));
	connect(CBFort, SIGNAL(activated(const QString &)), this, SLOT(CBFort_activated(const QString &)));
}

void PageEditTeam::CBGrave_activated(const QString & gravename)
{
	QPixmap pix(QString(DATA_PATH) + "/Graphics/Graves/" + gravename + ".png");
	GravePreview->setPixmap(pix.copy(0, 0, 32, 32));
}

void PageEditTeam::CBFort_activated(const QString & fortname)
{
	QPixmap pix(QString(DATA_PATH) + "/Forts/" + fortname + "L.png");
	FortPreview->setPixmap(pix);
}

PageMultiplayer::PageMultiplayer(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);
	gameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(gameCFG, 0, 0, 1, 2);
	teamsSelect = new TeamSelWidget(this);
	pageLayout->addWidget(teamsSelect, 0, 2, 1, 2);
}

PagePlayDemo::PagePlayDemo(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);

	BtnPlayDemo	= new QPushButton(this);
	BtnPlayDemo->setGeometry(QRect(240,	330, 161, 41));
	BtnPlayDemo->setFont(*font14);
	BtnPlayDemo->setText(QPushButton::tr("Play demo"));
	pageLayout->addWidget(BtnPlayDemo, 1, 2);

	DemosList =	new QListWidget(this);
	DemosList->setGeometry(QRect(170, 10, 311, 311));
	pageLayout->addWidget(DemosList, 0, 1);
}

PageOptions::PageOptions(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	groupBox = new QGroupBox(this);
	groupBox->setGeometry(QRect(20, 10,	591, 71));
	groupBox->setTitle(QGroupBox::tr("Teams"));

	BtnNewTeam = new QPushButton(groupBox);
	BtnNewTeam->setGeometry(QRect(10, 20, 160, 40));
	BtnNewTeam->setFont(*font14);
	BtnNewTeam->setText(QPushButton::tr("New team"));

	BtnEditTeam	= new QPushButton(groupBox);
	BtnEditTeam->setGeometry(QRect(400,	20, 160, 40));
	BtnEditTeam->setFont(*font14);
	BtnEditTeam->setText(QPushButton::tr("Edit team"));

	CBTeamName = new QComboBox(groupBox);
	CBTeamName->setGeometry(QRect(200, 30, 171,	22));
	CBResolution = new QComboBox(this);
	CBResolution->addItem("640x480");
	CBResolution->addItem("800x600");
	CBResolution->addItem("1024x768");
	CBResolution->addItem("1280x1024");
	CBResolution->setGeometry(QRect(20,	120, 151, 22));

	CBEnableSound = new	QCheckBox(this);
	CBEnableSound->setGeometry(QRect(20, 180, 101, 18));
	CBEnableSound->setText(QCheckBox::tr("Enable sound"));

	CBFullscreen = new QCheckBox(this);
	CBFullscreen->setGeometry(QRect(20,	160, 101, 18));
	CBFullscreen->setText(QCheckBox::tr("Fullscreen"));

	label = new	QLabel(this);
	label->setGeometry(QRect(10, 233, 47, 13));
	label->setText(QLabel::tr("Net nick"));

	editNetNick	= new QLineEdit(this);
	editNetNick->setGeometry(QRect(60, 230, 113, 20));
	editNetNick->setMaxLength(30);
	editNetNick->setText(QLineEdit::tr("unnamed"));

	BtnSaveOptions = new QPushButton(this);
	BtnSaveOptions->setGeometry(QRect(20, 380, 161, 41));
	BtnSaveOptions->setFont(*font14);
	BtnSaveOptions->setText(QPushButton::tr("Save"));

	BtnBack = new QPushButton(this);
	BtnBack->setGeometry(QRect(440, 380, 161, 41));
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
}

PageNet::PageNet(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	BtnNetConnect = new	QPushButton(this);
	BtnNetConnect->setGeometry(QRect(250, 140, 161, 41));
	BtnNetConnect->setFont(*font14);
	BtnNetConnect->setText(QPushButton::tr("Connect"));
	BtnBack = new QPushButton(this);
	BtnBack->setGeometry(QRect(250, 390, 161, 41));
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
}

PageNetChat::PageNetChat(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	BtnDisconnect = new QPushButton(this);
	BtnDisconnect->setGeometry(QRect(460, 390, 161, 41));
	BtnDisconnect->setFont(*font14);
	BtnDisconnect->setText(QPushButton::tr("Disconnect"));
	ChannelsList = new QListWidget(this);
	ChannelsList->setGeometry(QRect(20,	10, 201, 331));
	BtnJoin = new QPushButton(this);
	BtnJoin->setGeometry(QRect(460, 290,	161, 41));
	BtnJoin->setFont(*font14);
	BtnJoin->setText(QPushButton::tr("Join"));
	BtnCreate = new QPushButton(this);
	BtnCreate->setGeometry(QRect(460, 340, 161, 41));
	BtnCreate->setFont(*font14);
	BtnCreate->setText(QPushButton::tr("Create"));
}


PageNetGame::PageNetGame(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	BtnBack = new QPushButton(this);
	BtnBack->setGeometry(QRect(260, 390, 161, 41));
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));

	BtnAddTeam = new QPushButton(this);
	BtnAddTeam->setGeometry(QRect(260, 290, 161, 41));
	BtnAddTeam->setFont(*font14);
	BtnAddTeam->setText(QPushButton::tr("Add Team"));

	BtnGo	= new QPushButton(this);
	BtnGo->setGeometry(QRect(260,	340, 161, 41));
	BtnGo->setFont(*font14);
	BtnGo->setText(QPushButton::tr("Go!"));

	listNetTeams = new QListWidget(this);
	listNetTeams->setGeometry(QRect(270, 30, 120, 80));
}
