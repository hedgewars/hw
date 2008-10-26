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
#include <QPlastiqueStyle>

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

	app.setStyle(new QPlastiqueStyle);
	
	QDateTime now = QDateTime::currentDateTime();
	QDateTime zero;
	srand(now.secsTo(zero));
	rand();

	Q_INIT_RESOURCE(hedgewars);

	qApp->setStyleSheet
		(QString(
			"HWForm,QDialog{"
				"background-image: url(\":/res/Background.png\");"
				"background-position: bottom center;"
				"background-repeat: repeat-x;"
				"background-color: #870c8f;"
				"}"

			"QPushButton{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 10px;"
				"border-color: #ffcc00;"
				"background-origin: margin;"
				"background-position: top left;"
				"background-color: #00351d;"
				"color: #ffcc00;"
				"}"
				"QPushButton:hover{"
				"border-color: yellow;"
				"}"
				"QPushButton:pressed{"
				"border-color: white;"
				"}"

			"QLineEdit{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 12px;"
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			"QLineEdit:hover{"
				"border-color: yellow;"
				"}"

			"QLabel{"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"

			"QListWidget,QTableView{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 12px;"
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
//				"alternate-background-color: #2f213a;" //what's it?
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			"QListWidget:hover{"
				"border-color: yellow;"
				"}"

			"QTextBrowser{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 12px;"
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"

			"QSpinBox{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 12px;"
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			"QSpinBox:hover{"
				"border-color: yellow;"
				"}"
			"QSpinBox::up-button{"
				"background: transparent;"
				"width: 16px;"
				"height: 10px;"
				"}"
			"QSpinBox::up-arrow{"
				"image: url(\":/res/spin_up.png\");"
				//"width: 5px;"
				//"height: 5px;"
				"}"
			"QSpinBox::down-button{"
				"background: transparent;"
				"width: 16px;"
				"height: 10px;"
				"}"
			"QSpinBox::down-arrow{"
				"image: url(\":/res/spin_down.png\");"
				"}"

			"QToolBox{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 12px;"
				"border-color: #ffcc00;"
				//"background-color: #0d0544;"
			"}"
			"QToolBox::tab{"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			"QToolBox:hover{"
				"border-color: yellow;"
				"}"

			"QComboBox{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 15px;"
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
				"color: #ffcc00;"
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
				"border-width: 3px;"
				//"border-radius: 12px;" -- bad corners look
				"border-color: #ffcc00;"
				"background-color: #0d0544;"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"

			"IconedGroupBox{"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 16px;"
				"border-color: #ffcc00;"
				"background-color: #130f2c;"
				"color: #ffcc00;"
				"font: bold 14px;"
				"padding: 2px;"
				"}"
			".QGroupBox,GameCFGWidget,TeamSelWidget{"
				"background-image: url(\":/res/panelbg.png\");"
				"background-position: bottom center;"
				"background-repeat: repeat-x;"
				"border: solid;"
				"border-width: 3px;"
				"border-radius: 16px;"
				"border-color: #ffcc00;"
				"background-color: #040200;"
				"padding: 6px;"
				"color: #ffcc00;"
				"font: bold 14px;"
				//"margin-top: 24px;"
				"}"
			".QGroupBox::title{"
				"subcontrol-origin: margin;"
				"subcontrol-position: top left;"
				//"padding-left: 82px;"
				//"padding-top: 26px;"
				"text-align: left;"
				"}"

			"QCheckBox{"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			"QCheckBox::indicator:checked{"
				"image: url(\":/res/checked.png\");"
				"}"
			"QCheckBox::indicator:unchecked{"
				"image: url(\":/res/unchecked.png\");"
				"}"
			
			"QRadioButton{"
				"color: #ffcc00;"
				"font: bold 14px;"
				"}"
			
			".QWidget{"
				"background: transparent;"
				"}"
			".QTabWidget{"
				//"background: transparent;"
				"background-color: #130f2c;"
				"}"

			"QMenu{"
				"background-color: #ffcc00;"
				"margin: 3px;"
				"}"
			"QMenu::item{"
				"background-color: #0d0544;"
				"border: 1px solid transparent;"
				"font: bold;"
				"color: #ffcc00;"
				"padding: 2px 25px 2px 20px;"
				"}"
			"QMenu::item:selected{"
				"border-color: yellow;"
				"background-color: #2d2564;"
				"}"
			"QMenu::indicator{"
				"width: 16px;"
				"height: 16px;"
				"}"
			"QMenu::indicator:non-exclusive:checked{"
				"image: url(\":/res/checked.png\");"
				"}"
			"QMenu::indicator:non-exclusive:unchecked{"
				"image: url(\":/res/unchecked.png\");"
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

	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Maps");
	tmpdir.setFilter(QDir::Dirs | QDir::NoDotAndDotDot);
	mapList = new QStringList(tmpdir.entryList(QStringList("*")));

	HWForm *Form = new HWForm();
	Form->show();
	return app.exec();
}
