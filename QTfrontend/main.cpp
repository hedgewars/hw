/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QMessageBox>
#include <QFileInfo>
#include <QDateTime>
#include "hwform.h"
#include "hwconsts.h"

QDir * bindir;
QDir * cfgdir;
QDir * datadir;

bool checkForDir(const QString & dir)
{
	QDir tmpdir;
	if (!tmpdir.exists(dir))
		if (!tmpdir.mkdir(dir))
		{
			QMessageBox::critical(0,
					QObject::tr("Error"),
					QObject::tr("Cannot create directory %1").arg(dir),
					QObject::tr("OK"));
			return false;
		}
	return true;
}

int main(int argc, char *argv[])
{
	QApplication app(argc, argv);

	QDateTime now = QDateTime::currentDateTime();
	QDateTime zero;
	srand(now.secsTo(zero));

	Q_INIT_RESOURCE(hedgewars);

	QTranslator Translator;
	Translator.load(":/translations/hedgewars_" + QLocale::system().name());
	app.installTranslator(&Translator);

	QDir mydir("/home/igor/sources/hedgewars");
	mydir.cd("bin");

	bindir = new QDir(mydir);
	cfgdir = new QDir();

	cfgdir->setPath(cfgdir->homePath());
	if (checkForDir(cfgdir->absolutePath() + "/.hedgewars"))
	{
		checkForDir(cfgdir->absolutePath() + "/.hedgewars/Demos");
	}
	cfgdir->cd(".hedgewars");

	datadir = new QDir(mydir);
	datadir->cd("../share/hedgewars/Data");

	HWForm *Form = new HWForm();
	Form->show();
	return app.exec();
}
