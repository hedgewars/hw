/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
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

#include <QPushButton>
#include <QBuffer>
#include <QUuid>
#include <QBitmap>
#include <QPainter>
#include <QLinearGradient>
#include <QColor>
#include <QTextStream>
#include <QApplication>
#include <QLabel>
#include <QListWidget>
#include <QVBoxLayout>
#include <QIcon>

#include "hwconsts.h"
#include "mapContainer.h"
#include "igbox.h"

HWMapContainer::HWMapContainer(QWidget * parent) :
	QWidget(parent),
	mainLayout(this),
	pMap(0)
{
#if QT_VERSION >= 0x040300
  mainLayout.setContentsMargins(QApplication::style()->pixelMetric(QStyle::PM_LayoutLeftMargin),
                1,
                QApplication::style()->pixelMetric(QStyle::PM_LayoutRightMargin),
                QApplication::style()->pixelMetric(QStyle::PM_LayoutBottomMargin));
#endif
  imageButt = new QPushButton(this);
  imageButt->setObjectName("imageButt");
  imageButt->setFixedSize(256 + 6, 128 + 6);
  imageButt->setFlat(true);
  imageButt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);//QSizePolicy::Minimum, QSizePolicy::Minimum);
  mainLayout.addWidget(imageButt, 0, 0, 1, 2);
  connect(imageButt, SIGNAL(clicked()), this, SLOT(setRandomSeed()));
  connect(imageButt, SIGNAL(clicked()), this, SLOT(setRandomTheme()));

  chooseMap = new QComboBox(this);
  chooseMap->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
  chooseMap->addItem(QComboBox::tr("generated map..."));
  chooseMap->addItems(*mapList);
  connect(chooseMap, SIGNAL(activated(int)), this, SLOT(mapChanged(int)));
  mainLayout.addWidget(chooseMap, 1, 1);

  QLabel * lblMap = new QLabel(tr("Map"), this);
  mainLayout.addWidget(lblMap, 1, 0);

	gbThemes = new IconedGroupBox(this);
	gbThemes->setTitleTextPadding(60);
	gbThemes->setTitle(tr("Themes"));

	//gbThemes->setStyleSheet("padding: 0px"); // doesn't work - stylesheet is set with icon
	mainLayout.addWidget(gbThemes, 0, 2, 2, 1);
	
	QVBoxLayout * gbTLayout = new QVBoxLayout(gbThemes);
	gbTLayout->setContentsMargins(0, 0, 0 ,0);
	gbTLayout->setSpacing(0);
	lwThemes = new QListWidget(this);
	lwThemes->setMinimumHeight(30);
	lwThemes->setFixedWidth(120);
	for (int i = 0; i < Themes->size(); ++i) {
		QListWidgetItem * lwi = new QListWidgetItem();
		lwi->setText(Themes->at(i));
		lwi->setTextAlignment(Qt::AlignHCenter);
		lwThemes->addItem(lwi);
	}
	connect(lwThemes, SIGNAL(currentRowChanged(int)), this, SLOT(themeSelected(int)));
	
	gbTLayout->addWidget(lwThemes);
	lwThemes->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Minimum);
	
  mainLayout.setSizeConstraint(QLayout::SetFixedSize);//SetMinimumSize

  setRandomSeed();
  setRandomTheme();
}

void HWMapContainer::setImage(const QImage newImage)
{
  QPixmap px(256, 128);
  QPixmap pxres(256, 128);
  QPainter p(&pxres);

  px.fill(Qt::yellow);
  QBitmap bm = QBitmap::fromImage(newImage);
  px.setMask(bm);

  QLinearGradient linearGrad(QPoint(128, 0), QPoint(128, 128));
  linearGrad.setColorAt(1, QColor(0, 0, 192));
  linearGrad.setColorAt(0, QColor(66, 115, 225));
  p.fillRect(QRect(0, 0, 256, 128), linearGrad);
  p.drawPixmap(QPoint(0, 0), px);

  imageButt->setIcon(pxres);
  imageButt->setIconSize(QSize(256, 128));
  chooseMap->setCurrentIndex(0);
  pMap = 0;
}

void HWMapContainer::mapChanged(int index)
{
  if(!index) {
    changeImage();
    emit mapChanged("+rnd+");
    return;
  }

  loadMap(index);

  emit mapChanged(chooseMap->currentText());
}

void HWMapContainer::loadMap(int index)
{
  QPixmap mapImage;
  if(!mapImage.load(datadir->absolutePath() + "/Maps/" + chooseMap->currentText() + "/preview.png")) {
    changeImage();
    chooseMap->setCurrentIndex(0);
    return;
  }
  imageButt->setIcon(mapImage);
  QFile mapCfgFile(datadir->absolutePath() + "/Maps/" + chooseMap->currentText() + "/map.cfg");
  if (mapCfgFile.open(QFile::ReadOnly)) {
    QTextStream input(&mapCfgFile);
    input >> theme;
    mapCfgFile.close();
  }
}

void HWMapContainer::changeImage()
{
	pMap = new HWMap();
	connect(pMap, SIGNAL(ImageReceived(const QImage)), this, SLOT(setImage(const QImage)));
	pMap->getImage(m_seed.toStdString());
}

void HWMapContainer::themeSelected(int currentRow)
{
	theme = Themes->at(currentRow);
	gbThemes->setIcon(QIcon(QString("%1/Themes/%2/icon.png").arg(datadir->absolutePath()).arg(theme)));
	emit themeChanged(theme);
}

QString HWMapContainer::getCurrentSeed() const
{
  return m_seed;
}

QString HWMapContainer::getCurrentMap() const
{
  if(!chooseMap->currentIndex()) return QString();
  return chooseMap->currentText();
}

QString HWMapContainer::getCurrentTheme() const
{
	return theme;
}

void HWMapContainer::resizeEvent ( QResizeEvent * event )
{
  //imageButt->setIconSize(imageButt->size());
}

void HWMapContainer::setSeed(const QString & seed)
{
	m_seed = seed;
	changeImage();
}

void HWMapContainer::setMap(const QString & map)
{
	if(map == "+rnd+")
	{
		changeImage();
		return;
	}
	
	int id = chooseMap->findText(map);
	if(id > 0) {
		chooseMap->setCurrentIndex(id);
		loadMap(id);
		if (pMap)
			disconnect(pMap, 0, this, SLOT(setImage(const QImage)));
	}
}

void HWMapContainer::setTheme(const QString & theme)
{
	QList<QListWidgetItem *> items = lwThemes->findItems(theme, Qt::MatchExactly);
	if(items.size())
		lwThemes->setCurrentItem(items.at(0));
}

void HWMapContainer::setRandomSeed()
{
  m_seed = QUuid::createUuid().toString();
  emit seedChanged(m_seed);
  changeImage();
}

void HWMapContainer::setRandomTheme()
{
	if(!Themes->size()) return;
	quint32 themeNum = rand() % Themes->size();
	lwThemes->setCurrentRow(themeNum);
}
