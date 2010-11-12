/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QResizeEvent>
#include <QGroupBox>
#include <QCheckBox>
#include <QGridLayout>
#include <QSpinBox>
#include <QLabel>
#include <QMessageBox>
#include <QTableView>
#include <QPushButton>

#include "gamecfgwidget.h"
#include "igbox.h"
#include "hwconsts.h"
#include "ammoSchemeModel.h"

GameCFGWidget::GameCFGWidget(QWidget* parent, bool externalControl) :
  QGroupBox(parent), mainLayout(this)
{
    mainLayout.setMargin(0);
//  mainLayout.setSizeConstraint(QLayout::SetMinimumSize);

    pMapContainer = new HWMapContainer(this);
    mainLayout.addWidget(pMapContainer, 0, 0);

    IconedGroupBox *GBoxOptions = new IconedGroupBox(this);
    GBoxOptions->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
    mainLayout.addWidget(GBoxOptions);

    QGridLayout *GBoxOptionsLayout = new QGridLayout(GBoxOptions);

    GameSchemes = new QComboBox(GBoxOptions);
    GBoxOptionsLayout->addWidget(GameSchemes, 0, 1);
    connect(GameSchemes, SIGNAL(currentIndexChanged(int)), this, SLOT(schemeChanged(int)));

    GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Game scheme"), GBoxOptions), 0, 0);

    QPixmap pmEdit(":/res/edit.png");
    
    QPushButton * goToSchemePage = new QPushButton(GBoxOptions);
    goToSchemePage->setToolTip(tr("Edit schemes"));
    goToSchemePage->setIconSize(pmEdit.size());
    goToSchemePage->setIcon(pmEdit);
    goToSchemePage->setMaximumWidth(pmEdit.width() + 6);
    GBoxOptionsLayout->addWidget(goToSchemePage, 0, 2);
    connect(goToSchemePage, SIGNAL(clicked()), this, SIGNAL(goToSchemes()));

    GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Weapons"), GBoxOptions), 1, 0);

    WeaponsName = new QComboBox(GBoxOptions);
    GBoxOptionsLayout->addWidget(WeaponsName, 1, 1);

    connect(WeaponsName, SIGNAL(currentIndexChanged(int)), this, SLOT(ammoChanged(int)));

    QPushButton * goToWeaponPage = new QPushButton(GBoxOptions);
    goToWeaponPage->setToolTip(tr("Edit weapons"));
    goToWeaponPage->setIconSize(pmEdit.size());
    goToWeaponPage->setIcon(pmEdit);
    goToWeaponPage->setMaximumWidth(pmEdit.width() + 6);
    GBoxOptionsLayout->addWidget(goToWeaponPage, 1, 2);

    connect(goToWeaponPage, SIGNAL(clicked()), this, SLOT(jumpToWeapons()));

    GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Bind schemes and weapons"), GBoxOptions), 2, 0);

    bindEntries = new QCheckBox(GBoxOptions);
    bindEntries->setToolTip(tr("When this option is enabled selecting a game scheme will auto-select a weapon (and viceversa)"));
    bindEntries->setChecked(true);
    GBoxOptionsLayout->addWidget(bindEntries, 2, 2);

    connect(pMapContainer, SIGNAL(seedChanged(const QString &)), this, SLOT(seedChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapChanged(const QString &)), this, SLOT(mapChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapgenChanged(MapGenerator)), this, SLOT(mapgenChanged(MapGenerator)));
    connect(pMapContainer, SIGNAL(maze_sizeChanged(int)), this, SLOT(maze_sizeChanged(int)));
    connect(pMapContainer, SIGNAL(themeChanged(const QString &)), this, SLOT(themeChanged(const QString &)));
    connect(pMapContainer, SIGNAL(newTemplateFilter(int)), this, SLOT(templateFilterChanged(int)));
}

void GameCFGWidget::jumpToWeapons()
{
    emit goToWeapons(WeaponsName->currentText());
}

QVariant GameCFGWidget::schemeData(int column) const
{
    return GameSchemes->model()->data(GameSchemes->model()->index(GameSchemes->currentIndex(), column));
}

quint32 GameCFGWidget::getGameFlags() const
{
    quint32 result = 0;

    if (schemeData(1).toBool())
        result |= 0x00001000;       // fort
    if (schemeData(2).toBool())
        result |= 0x00000010;       // divide teams
    if (schemeData(3).toBool())
        result |= 0x00000004;       // solid land
    if (schemeData(4).toBool())
        result |= 0x00000008;       // border
    if (schemeData(5).toBool())
        result |= 0x00000020;       // low gravity
    if (schemeData(6).toBool())
        result |= 0x00000040;       // laser sight
    if (schemeData(7).toBool())
        result |= 0x00000080;       // invulnerable
    if (schemeData(8).toBool())
        result |= 0x00000100;       // mines
    if (schemeData(9).toBool())
        result |= 0x00000200;       // vampirism
    if (schemeData(10).toBool())
        result |= 0x00000400;       // karma
    if (schemeData(11).toBool())
        result |= 0x00000800;       // artillery
    if (schemeData(12).toBool())
        result |= 0x00002000;       // random
    if (schemeData(13).toBool())
        result |= 0x00004000;       // king
    if (schemeData(14).toBool())
        result |= 0x00008000;       // place hogs
    if (schemeData(15).toBool())
        result |= 0x00010000;       // shared ammo
    if (schemeData(16).toBool())
        result |= 0x00020000;       // disable girders
    if (schemeData(17).toBool())
        result |= 0x00040000;       // disable land obj
    if (schemeData(18).toBool())
        result |= 0x00080000;       // ai survival
    if (schemeData(19).toBool())
        result |= 0x00100000;       // infinite attacks
    if (schemeData(20).toBool())
        result |= 0x00200000;       // reset weaps
    if (schemeData(21).toBool())
        result |= 0x00400000;       // per hog ammo
    if (schemeData(22).toBool())
        result |= 0x00800000;       // no wind

    return result;
}

quint32 GameCFGWidget::getInitHealth() const
{
    return schemeData(25).toInt();
}

QStringList GameCFGWidget::getFullConfig() const
{
    QStringList sl;
    sl.append("eseed " + pMapContainer->getCurrentSeed());
    sl.append(QString("e$gmflags %1").arg(getGameFlags()));
    sl.append(QString("e$damagepct %1").arg(schemeData(23).toInt()));
    sl.append(QString("e$turntime %1").arg(schemeData(24).toInt() * 1000));
    sl.append(QString("e$sd_turns %1").arg(schemeData(26).toInt()));
    sl.append(QString("e$casefreq %1").arg(schemeData(27).toInt()));
    sl.append(QString("e$minestime %1").arg(schemeData(28).toInt()));
    sl.append(QString("e$minesnum %1").arg(schemeData(29).toInt()));
    sl.append(QString("e$minedudpct %1").arg(schemeData(30).toInt()));
    sl.append(QString("e$explosives %1").arg(schemeData(31).toInt()));
    sl.append(QString("e$healthprob %1").arg(schemeData(32).toInt()));
    sl.append(QString("e$hcaseamount %1").arg(schemeData(33).toInt()));
    sl.append(QString("e$waterrise %1").arg(schemeData(34).toInt()));
    sl.append(QString("e$healthdec %1").arg(schemeData(35).toInt()));
    sl.append(QString("e$template_filter %1").arg(pMapContainer->getTemplateFilter()));
    sl.append(QString("e$mapgen %1").arg(pMapContainer->get_mapgen()));
    sl.append(QString("e$maze_size %1").arg(pMapContainer->get_maze_size()));

    QString currentMap = pMapContainer->getCurrentMap();
    if (currentMap.size() > 0)
    {
        sl.append("emap " + currentMap);
        if(pMapContainer->getCurrentIsMission())
            sl.append(QString("escript Maps/%1/map.lua")
                .arg(currentMap));
    }
    sl.append("etheme " + pMapContainer->getCurrentTheme());
    return sl;
}

void GameCFGWidget::setNetAmmo(const QString& name, const QString& ammo)
{
    bool illegal = ammo.size() != cDefaultAmmoStore->size();
    if (illegal)
        QMessageBox::critical(this, tr("Error"), tr("Illegal ammo scheme"));

    int pos = WeaponsName->findText(name);
    if ((pos == -1) || illegal) { // prevent from overriding schemes with bad ones
        WeaponsName->addItem(name, ammo);
        WeaponsName->setCurrentIndex(WeaponsName->count() - 1);
    } else {
        WeaponsName->setItemData(pos, ammo);
        WeaponsName->setCurrentIndex(pos);
    }
}

void GameCFGWidget::fullNetConfig()
{
    ammoChanged(WeaponsName->currentIndex());

    seedChanged(pMapContainer->getCurrentSeed());
    templateFilterChanged(pMapContainer->getTemplateFilter());
    themeChanged(pMapContainer->getCurrentTheme());

    schemeChanged(GameSchemes->currentIndex());

    mapgenChanged(pMapContainer->get_mapgen());
    maze_sizeChanged(pMapContainer->get_maze_size());

    // map must be the last
    QString map = pMapContainer->getCurrentMap();
    if (map.size())
        mapChanged(map);
}

void GameCFGWidget::setParam(const QString & param, const QStringList & slValue)
{
    if (slValue.size() == 1)
    {
        QString value = slValue[0];
        if (param == "MAP") {
            pMapContainer->setMap(value);
            return;
        }
        if (param == "SEED") {
            pMapContainer->setSeed(value);
            return;
        }
        if (param == "THEME") {
            pMapContainer->setTheme(value);
            return;
        }
        if (param == "TEMPLATE") {
            pMapContainer->setTemplateFilter(value.toUInt());
            return;
        }
        if (param == "MAPGEN") {
            pMapContainer->setMapgen((MapGenerator)value.toUInt());
            return;
        }
        if (param == "MAZE_SIZE") {
            pMapContainer->setMaze_size(value.toUInt());
            return;
        }
    }

    if (slValue.size() == 2)
    {
        if (param == "AMMO") {
            setNetAmmo(slValue[0], slValue[1]);
            return;
        }
    }

    qWarning("Got bad config param from net");
}

void GameCFGWidget::ammoChanged(int index)
{
    if (index >= 0) {
        emit paramChanged(
            "AMMO",
            QStringList() << WeaponsName->itemText(index) << WeaponsName->itemData(index).toString()
        );
        if (bindEntries->isChecked() == true) {
            QString weapName = WeaponsName->itemText(index);
            for (int i = 0; i < GameSchemes->count(); i++) {
                 QString schemeName = GameSchemes->itemText(i);
                 int res = QString::compare(weapName, schemeName, Qt::CaseSensitive);
                 if (0 == res) {
                     GameSchemes->setCurrentIndex(i);
                     break;
                 }
            }
        }
    }
}

void GameCFGWidget::mapChanged(const QString & value)
{
    if(pMapContainer->getCurrentIsMission())
    {
        GameSchemes->setEnabled(false);
        WeaponsName->setEnabled(false);
        bindEntries->setEnabled(false);
        GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
    }
    else
    {
        GameSchemes->setEnabled(true);
        WeaponsName->setEnabled(true);
        bindEntries->setEnabled(true);
    }
    emit paramChanged("MAP", QStringList(value));
}

void GameCFGWidget::templateFilterChanged(int value)
{
    emit paramChanged("TEMPLATE", QStringList(QString::number(value)));
}

void GameCFGWidget::seedChanged(const QString & value)
{
    emit paramChanged("SEED", QStringList(value));
}

void GameCFGWidget::themeChanged(const QString & value)
{
    emit paramChanged("THEME", QStringList(value));
}

void GameCFGWidget::schemeChanged(int index)
{
    QStringList sl;

    int size = GameSchemes->model()->columnCount();
    for(int i = 0; i < size; ++i)
        sl << schemeData(i).toString();

    emit paramChanged("SCHEME", sl);

    if (bindEntries->isChecked() == true) {
        QString schemeName = GameSchemes->itemText(index);
        for (int i = 0; i < WeaponsName->count(); i++) {
             QString weapName = WeaponsName->itemText(i);
             int res = QString::compare(weapName, schemeName, Qt::CaseSensitive);
             if (0 == res) {
                 WeaponsName->setCurrentIndex(i);
                 break;
             }
        }
    }
}

void GameCFGWidget::mapgenChanged(MapGenerator m)
{
    emit paramChanged("MAPGEN", QStringList(QString::number(m)));
}

void GameCFGWidget::maze_sizeChanged(int s)
{
    emit paramChanged("MAZE_SIZE", QStringList(QString::number(s)));
}

void GameCFGWidget::resendSchemeData()
{
    schemeChanged(GameSchemes->currentIndex());
}
