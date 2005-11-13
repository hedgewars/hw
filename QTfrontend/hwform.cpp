/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QtGui>
#include <QStringList>
#include <QProcess>
#include <QDir>
#include <QPixmap>
#include <QRegExp>
#include <QIcon>
#include <QFile>
#include <QTextStream>

#include "hwform.h"
#include "sdlkeys.h"
#include "hwconsts.h"

HWForm::HWForm(QWidget *parent)
	: QMainWindow(parent)
{
	ui.setupUi(this);
	TeamNameEdit = new QLineEdit(ui.GBoxTeam);
	TeamNameEdit->setGeometry(QRect(10, 20, 141, 20));
	TeamNameEdit->setMaxLength(15);
	for(int i = 0; i < 8; i++)
	{
		HHNameEdit[i] = new QLineEdit(ui.GBoxHedgehogs);
		HHNameEdit[i]->setGeometry(QRect(10, 20 + i * 30, 141, 20));
		HHNameEdit[i]->setMaxLength(15);
	}
	
	QStringList binds;
	for(int i = 0; strlen(sdlkeys[i][1]) > 0; i++)
	{
		binds << sdlkeys[i][1];
	}
	
	for(int i = 0; i < BINDS_NUMBER; i++)
	{
		LBind[i] = new QLabel(ui.GBoxBinds);
		LBind[i]->setGeometry(QRect(10, 23 + i * 30, 60, 20));
		LBind[i]->setText(cbinds[i].name);
		LBind[i]->setAlignment(Qt::AlignRight);
		CBBind[i] = new QComboBox(ui.GBoxBinds);
		CBBind[i]->setGeometry(QRect(80, 20 + i * 30, 80, 20));
		CBBind[i]->addItems(binds);
	}
	
	QDir tmpdir;
	tmpdir.cd(DATA_PATH);
	tmpdir.cd("Forts");
	tmpdir.setFilter(QDir::Files);
	
	ui.CBFort->addItems(tmpdir.entryList(QStringList("*L.png")).replaceInStrings(QRegExp("^(.*)L.png"), "\\1"));
	
	tmpdir.cd("../Graphics/Graves");
	QStringList list = tmpdir.entryList(QStringList("*.png"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		ui.CBGrave->addItem((*it).replace(QRegExp("^(.*).png"), "\\1"));
	}

	cfgdir.setPath(cfgdir.homePath());
	if (!cfgdir.exists(".hedgewars"))
	{
		if (!cfgdir.mkdir(".hedgewars"))
		{
			QMessageBox::critical(this, 
					tr("Error"),
					tr("Cannot create directory %s").arg("/.hedgewars"),
					tr("Quit"));
		}
		return ;
	}
	cfgdir.cd(".hedgewars");
	
	list = cfgdir.entryList(QStringList("*.cfg"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		ui.CBTeamName->addItem((*it).replace(QRegExp("^(.*).cfg"), "\\1"));
	}
	
	
	QFile settings(cfgdir.absolutePath() + "/options");
	if (!settings.open(QIODevice::ReadOnly))
	{
		return ;
	}
	QTextStream stream(&settings);
	stream.setCodec("UTF-8");	
	QString str;
	
	while (!stream.atEnd())
	{
		str = stream.readLine();
		if (str.startsWith(";")) continue;
		if (str.startsWith("resolution "))
		{
			str.remove(0, 11);
			ui.CBResolution->setCurrentIndex(str.toLong());
		} else
		if (str.startsWith("fullscreen "))
		{
			str.remove(0, 11);
			ui.CBFullscreen->setChecked(str.toLong());
		}
	}
	settings.close();
	connect(ui.BtnSPBack, SIGNAL(clicked()), this, SLOT(GoToMain()));
	connect(ui.BtnSetupBack, SIGNAL(clicked()), this, SLOT(GoToMain()));
	connect(ui.BtnSinglePlayer, SIGNAL(clicked()), this, SLOT(GoToSinglePlayer()));
	connect(ui.BtnSetup, SIGNAL(clicked()), this, SLOT(GoToSetup()));
	connect(ui.BtnNewTeam, SIGNAL(clicked()), this, SLOT(NewTeam()));
	connect(ui.BtnEditTeam, SIGNAL(clicked()), this, SLOT(EditTeam()));
	connect(ui.BtnTeamSave, SIGNAL(clicked()), this, SLOT(TeamSave()));
	connect(ui.BtnTeamDiscard, SIGNAL(clicked()), this, SLOT(TeamDiscard()));
	connect(ui.BtnSimpleGame, SIGNAL(clicked()), this, SLOT(SimpleGame()));
	connect(ui.BtnSaveOptions, SIGNAL(clicked()), this, SLOT(SaveOptions()));
	connect(ui.CBGrave, SIGNAL(activated(const QString &)), this, SLOT(CBGrave_activated(const QString &)));
	connect(ui.CBFort, SIGNAL(activated(const QString &)), this, SLOT(CBFort_activated(const QString &)));
	ui.Pages->setCurrentIndex(ID_PAGE_MAIN);
}

void HWForm::GoToMain()
{
	ui.Pages->setCurrentIndex(ID_PAGE_MAIN);
}

void HWForm::GoToSinglePlayer()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SINGLEPLAYER);
}

void HWForm::GoToSetup()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::NewTeam()
{
	tmpTeam = new HWTeam();
	tmpTeam->SetCfgDir(cfgdir.absolutePath());
	tmpTeam->SetToPage(this);
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP_TEAM);
}

void HWForm::EditTeam()
{
	tmpTeam = new HWTeam();
	tmpTeam->SetCfgDir(cfgdir.absolutePath());
	tmpTeam->LoadFromFile();
	tmpTeam->SetToPage(this);
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP_TEAM);
}

void HWForm::TeamSave()
{
	tmpTeam = new HWTeam();
	tmpTeam->GetFromPage(this);
	tmpTeam->SaveToFile();
	delete tmpTeam;
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::TeamDiscard()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::SimpleGame()
{
	game = new HWGame();
	game->AddTeam(cfgdir.absolutePath() + "/team.cfg");
	game->AddTeam(cfgdir.absolutePath() + "/team.cfg");
	game->Start(ui.CBResolution->currentIndex(), ui.CBFullscreen->isChecked());
}

void HWForm::CBGrave_activated(const QString & gravename)
{
	QPixmap pix(QString(DATA_PATH) + "/Graphics/Graves/" + gravename + ".png");
	ui.GravePreview->setPixmap(pix.copy(0, 0, 32, 32));
}

void HWForm::CBFort_activated(const QString & fortname)
{
	QPixmap pix(QString(DATA_PATH) + "/Forts/" + fortname + "L.png");
	ui.FortPreview->setPixmap(pix);
}

void HWForm::SaveOptions()
{
	QFile settings(cfgdir.absolutePath() + "/options");
	if (!settings.open(QIODevice::WriteOnly))
	{
		QMessageBox::critical(this, 
				tr("Error"),
				tr("Cannot save options to file %s").arg(settings.fileName()),
				tr("Quit"));
		return ;
	}
	QTextStream stream(&settings);
	stream.setCodec("UTF-8");
	stream << "; Generated by Hedgewars, do not modify" << endl;
	stream << "resolution " << ui.CBResolution->currentIndex() << endl;
	stream << "fullscreen " << ui.CBFullscreen->isChecked() << endl;
	settings.close();
}
