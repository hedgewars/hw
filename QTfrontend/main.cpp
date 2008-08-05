/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QMessageBox>
#include <QFileInfo>
#include <QDateTime>
#include <QTextStream>
#include <QDesktopWidget>

#include "hwform.h"
#include "hwconsts.h"

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

	qApp->setStyleSheet
		(QString(
				".HWForm{"
				"background-image: url(\":/res/Background.png\");"
				"background-position: bottom center;"
				"background-repeat: repeat-x;"
				"background-color: #870c8f;"
				"}"
//				"PageMain > QPushButton{"
				"QPushButton{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 8px;"
				"border-color: orange;"
				"background-origin: content;"
				"}"
//				"PageMain > QPushButton:hover{"
				"QPushButton:hover{"
				"border-color: yellow;"
				"}"
//				"PageMain > QPushButton:pressed{"
				"QPushButton:pressed{"
				"border-color: white;"
				"}"
			)
		);

	bindir->cd("bin"); // workaround over NSIS installer

	cfgdir->setPath(cfgdir->homePath());
	if (checkForDir(cfgdir->absolutePath() + "/.hedgewars"))
	{
		checkForDir(cfgdir->absolutePath() + "/.hedgewars/Demos");
		checkForDir(cfgdir->absolutePath() + "/.hedgewars/Saves");
	}
	cfgdir->cd(".hedgewars");

	datadir->cd(bindir->absolutePath());
	datadir->cd(*cDataDir);
	if(!datadir->cd("hedgewars/Data")) {
		QMessageBox::critical(0, QMessageBox::tr("Error"),
			QMessageBox::tr("Failed to open data directory:\n%1\n"
					"Please check your installation").
					arg(datadir->absolutePath()+"/hedgewars/Data"));
		return 1;
	}

	QTranslator Translator;
	Translator.load(datadir->absolutePath() + "/Locale/hedgewars_" + QLocale::system().name());
	app.installTranslator(&Translator);

	Themes = new QStringList();
	QFile themesfile(datadir->absolutePath() + "/Themes/themes.cfg");
	if (themesfile.open(QIODevice::ReadOnly)) {
		QTextStream stream(&themesfile);
		QString str;
		while (!stream.atEnd())
		{
			Themes->append(stream.readLine());
		}
		themesfile.close();
	} else {
		QMessageBox::critical(0, "Error", "Cannot access themes.cfg", "OK");
	}

	HWForm *Form = new HWForm();
	Form->show();
	return app.exec();
}
