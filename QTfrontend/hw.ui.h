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

#include <qmessagebox.h>
#include <qdir.h>
#include <qtextstream.h>
#include <qregexp.h>
#include "hwconsts.h"
#include "game.h"
#include "sdlkeys.h"

class QHostAddress;
class QDir;
class QMessageBox;
class QFile;
class QTextStream;
class QStream;
class QPixmap;


void HWForm::ButtonLGame_clicked()
{
	engineprocess->clearArguments();
	engineprocess->addArgument("hw");
	engineprocess->addArgument(resolutions[0][ CBResolutions->currentItem() ]);
	engineprocess->addArgument(resolutions[1][ CBResolutions->currentItem() ]);
	engineprocess->addArgument("avematan");
	engineprocess->addArgument("46631");
	engineprocess->addArgument("=seed=");
	engineprocess->addArgument("1");
	if (!engineprocess->start()) 
	{
		QMessageBox::critical( this,
				tr("Fatal error"),
				tr("Could not start engine."),
				tr("Quit"));
	}
}


void HWForm::init()
{
	QHostAddress addr((Q_UINT32)0x7f000001);
	ipcserv = new IPCServer(addr, 46631, this);
	
	engineprocess = new QProcess;
	
	cfgdir.setPath(cfgdir.homeDirPath());
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
	
	QFile settings(cfgdir.absPath() + "/options");
	if (!settings.open(IO_ReadOnly))
	{
		return ;
	}
	QTextStream stream(&settings);
	stream.setEncoding(QTextStream::Unicode);	
	QString str;
	
	while (!stream.atEnd())
	{
		str = stream.readLine();
		if (str.startsWith(";")) continue;
		if (str.startsWith("resolution "))
		{
			str.remove(0, 11);
			CBResolutions->setCurrentItem(str.toLong());
		} else
		if (str.startsWith("fullscreen "))
		{
			str.remove(0, 11);
			CBFullscreen->setChecked(str.toLong());
		}
	}
	settings.close();
	
	QDir tmpdir;
	tmpdir.cd("../hedgewars/Data/Forts");
	tmpdir.setFilter(QDir::Files);
	CBForts->insertStringList(tmpdir.entryList("*L.png").gres(QRegExp("^(.*)L.png"), "\\1"));
	CBForts->setCurrentItem(0);
	
	tmpdir.cd("../Graphics/Graves");
	QStringList list = tmpdir.entryList("*.png");
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		QPixmap pix("Data/Graphics/Graves/" + *it);
		pix.resize(32, 32);
		CBGraves->insertItem(pix, (*it).replace(QRegExp("^(.*).png"), "\\1"));
	}
	
	QStringList binds;
	for(int i = 0; strlen(keys[i][1]) > 0; i++)
	{
		binds << keys[i][1];
	}
	CBindUp    ->insertStringList( binds );
	CBindLeft  ->insertStringList( binds );
	CBindRight ->insertStringList( binds );
	CBindDown  ->insertStringList( binds );
	CBindLJump ->insertStringList( binds );
	CBindHJump ->insertStringList( binds );
	CBindAttack->insertStringList( binds );
	CBindSwitch->insertStringList( binds );
	
}

void HWForm::destroy()
{
}


void HWForm::GoPageOptions()
{
	Pages->raiseWidget(PageOptions);
}


void HWForm::GoPageMain()
{
	Pages->raiseWidget(PageMain);
}


void HWForm::SaveSettings()
{
	QFile settings(cfgdir.absPath() + "/options");
	if (!settings.open(IO_WriteOnly))
	{
		QMessageBox::critical(this, 
				tr("Error"),
				tr("Cannot save options to file %s").arg(settings.name()),
				tr("Quit"));
		return ;
	}
	QTextStream stream(&settings);
	stream.setEncoding(QTextStream::Unicode);
	stream << "; Generated by Hedgewars, do not modify" << endl;
	stream << "resolution " << CBResolutions->currentItem() << endl;
	stream << "fullscreen " << CBFullscreen->isOn() << endl;
	settings.close();
}

void HWForm::ButtonNetGame_clicked()
{
	Pages->raiseWidget(PageNetGame);
}


void HWForm::GoPageTeamSettings()
{
	Pages->raiseWidget(PageTeamSettings);
}

void HWForm::ButtonDemos_clicked()
{
    Pages->raiseWidget(PageDemos);
}

void HWForm::NewTeam()
{
	HWTeam tmpTeam;
	tmpTeam.ToPage( this );
}


void HWForm::EditTeam()
{
	HWTeam tmpTeam;
	tmpTeam.LoadFromFile(cfgdir.absPath() + "/team.cfg");
	tmpTeam.ToPage( this );
}


void HWForm::SaveTeamFromPage()
{
	HWTeam tmpTeam;
	tmpTeam.FromPage( this );
	tmpTeam.SaveToFile(cfgdir.absPath() + "/team.cfg");
}


void HWForm::CBForts_activated( const QString & fortname)
{
	QPixmap pix("Data/Forts/" + fortname + "L.png");
	FortPreview->setPixmap(pix);
}
