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

			"QPushButton{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 10px;"
				"border-color: orange;"
				"background-origin: margin;"
				"background-position: top left;"
				"background-color: #00351d;"
				"color: orange;"
				"}"
				"QPushButton:hover{"
				"border-color: yellow;"
				"}"
				"QPushButton:pressed{"
				"border-color: white;"
				"}"

			"QLineEdit{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 12px;"
				"border-color: orange;"
				"background-color: #0d0544;"
				"color: orange;"
				"font: bold 14px;"
				"}"
			"QLineEdit:hover{"
				"border-color: yellow;"
				"}"

			"QLabel{"
				"color: orange;"
				"font: bold 14px;"
				"}"

			"QListWidget{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 12px;"
				"border-color: orange;"
				"background-color: #0d0544;"
				"color: orange;"
				"font: bold 14px;"
				"}"
			"QListWidget:hover{"
				"border-color: yellow;"
				"}"

			"QSpinBox{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 12px;"
				"border-color: orange;"
				"background-color: #0d0544;"
				"color: orange;"
				"font: bold 14px;"
				"}"
			"QSpinBox:hover{"
				"border-color: yellow;"
				"}"

			"QToolBox{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 12px;"
				"border-color: orange;"
				"background-color: #0d0544;"
			"}"
			"QToolBox::tab{"
				"color: orange;"
				"font: bold 14px;"
				"}"
			"QToolBox:hover{"
				"border-color: yellow;"
				"}"

			"QComboBox{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 15px;"
				"border-color: orange;"
				"background-color: #0d0544;"
				"color: orange;"
				"font: bold 14px;"
				"padding: 3px;"
//				"text-align: center;"
				"}"
			"QComboBox:hover{"
				"border-color: yellow;"
				"}"
			"QComboBox:pressed{"
				"border-color: white;"
				"}"
			"QComboBox::drop-down{"
				"border: transparent;"
				"width: 25px;"
				"}"
			"QComboBox::down-arrow {"
				"image: url(\":/res/dropdown.png\");"
				"}"
			"QComboBox QAbstractItemView{"
				"border: solid transparent;"
				"border-width: 4px;"
				//"border-radius: 12px;" -- bad corners look
				"border-color: orange;"
				"background-color: #0d0544;"
				"color: orange;"
				"font: bold 14px;"
				"}"

			"QGroupBox{"
				"border: solid;"
				"border-width: 4px;"
				"border-radius: 16px;"
				"border-color: orange;"
				"background-color: #130f2c;"
				"color: orange;"
				"font: bold 14px;"
				"padding: 3px;"
				"margin-top: 60px;"
				"margin-left: 16px;"
//				"padding-top: 6px;"
				"}"
			"QGroupBox::indicator{"
				"image: url(\":/res/graphicsicon.png\");"
				"}"
			"QGroupBox::title{"
				"subcontrol-origin: margin;"
				"subcontrol-position: top left;"
				"text-align: center;"
				"}"

			"QCheckBox{"
				"color: orange;"
				"font: bold 14px;"
				"}"
			"QCheckBox::indicator:checked{"
				"image: url(\":/res/checked.png\");"
				"}"
			"QCheckBox::indicator:unchecked{"
				"image: url(\":/res/unchecked.png\");"
				"}"
			
			"QRadioButton{"
				"color: orange;"
				"font: bold 14px;"
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
