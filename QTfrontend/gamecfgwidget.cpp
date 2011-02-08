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
#include "proto.h"

GameCFGWidget::GameCFGWidget(QWidget* parent) :
  QGroupBox(parent)
  , mainLayout(this)
  , seedRegexp("\\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\}")
{
    mainLayout.setMargin(0);
//  mainLayout.setSizeConstraint(QLayout::SetMinimumSize);

    pMapContainer = new HWMapContainer(this);
    mainLayout.addWidget(pMapContainer, 0, 0);

    IconedGroupBox *GBoxOptions = new IconedGroupBox(this);
    GBoxOptions->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
    mainLayout.addWidget(GBoxOptions, 1, 0);

    QGridLayout *GBoxOptionsLayout = new QGridLayout(GBoxOptions);

    GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Gameplay"), GBoxOptions), 0, 0);

    Scripts = new QComboBox(GBoxOptions);
    GBoxOptionsLayout->addWidget(Scripts, 0, 1);

    Scripts->addItem("Normal");
    Scripts->insertSeparator(1);

    for (int i = 0; i < scriptList->size(); ++i) {
        QString script = (*scriptList)[i].remove(".lua", Qt::CaseInsensitive);
        QList<QVariant> scriptInfo;
        scriptInfo.push_back(script);
        QFile scriptCfgFile(QString("%1/Scripts/Multiplayer/%2.cfg").arg(datadir->absolutePath()).arg(script));
        if (scriptCfgFile.exists() && scriptCfgFile.open(QFile::ReadOnly)) {
            QString scheme;
            QString weapons;
            QTextStream input(&scriptCfgFile);
            input >> scheme;
            input >> weapons;
            if (scheme.isEmpty())
                scheme = "locked";
            scheme.replace("_", " ");
            if (weapons.isEmpty())
                weapons = "locked";
            weapons.replace("_", " ");
            scriptInfo.push_back(scheme);
            scriptInfo.push_back(weapons);
            scriptCfgFile.close();
        }
        else
        {
            scriptInfo.push_back("locked");
            scriptInfo.push_back("locked");
        }
        Scripts->addItem(script.replace("_", " "), scriptInfo);
    }

    connect(Scripts, SIGNAL(currentIndexChanged(int)), this, SLOT(scriptChanged(int)));

    QWidget *SchemeWidget = new QWidget(GBoxOptions);
    GBoxOptionsLayout->addWidget(SchemeWidget, 1, 0, 1, 2);

    QGridLayout *SchemeWidgetLayout = new QGridLayout(SchemeWidget);
    SchemeWidgetLayout->setMargin(0);

    GameSchemes = new QComboBox(SchemeWidget);
    SchemeWidgetLayout->addWidget(GameSchemes, 0, 2);
    connect(GameSchemes, SIGNAL(currentIndexChanged(int)), this, SLOT(schemeChanged(int)));

    SchemeWidgetLayout->addWidget(new QLabel(QLabel::tr("Game scheme"), SchemeWidget), 0, 0);

    QPixmap pmEdit(":/res/edit.png");
    
    QPushButton * goToSchemePage = new QPushButton(SchemeWidget);
    goToSchemePage->setToolTip(tr("Edit schemes"));
    goToSchemePage->setIconSize(pmEdit.size());
    goToSchemePage->setIcon(pmEdit);
    goToSchemePage->setMaximumWidth(pmEdit.width() + 6);
    SchemeWidgetLayout->addWidget(goToSchemePage, 0, 3);
    connect(goToSchemePage, SIGNAL(clicked()), this, SLOT(jumpToSchemes()));

    SchemeWidgetLayout->addWidget(new QLabel(QLabel::tr("Weapons"), SchemeWidget), 1, 0);

    WeaponsName = new QComboBox(SchemeWidget);
    SchemeWidgetLayout->addWidget(WeaponsName, 1, 2);

    connect(WeaponsName, SIGNAL(currentIndexChanged(int)), this, SLOT(ammoChanged(int)));

    QPushButton * goToWeaponPage = new QPushButton(SchemeWidget);
    goToWeaponPage->setToolTip(tr("Edit weapons"));
    goToWeaponPage->setIconSize(pmEdit.size());
    goToWeaponPage->setIcon(pmEdit);
    goToWeaponPage->setMaximumWidth(pmEdit.width() + 6);
    SchemeWidgetLayout->addWidget(goToWeaponPage, 1, 3);
    connect(goToWeaponPage, SIGNAL(clicked()), this, SLOT(jumpToWeapons()));

    //GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Bind schemes with weapons"), GBoxOptions), 2, 0);

    bindEntries = new QCheckBox(SchemeWidget);
    bindEntries->setToolTip(tr("When this option is enabled selecting a game scheme will auto-select a weapon"));
    bindEntries->setChecked(true);
    bindEntries->setMaximumWidth(42);
    bindEntries->setStyleSheet( "QCheckBox::indicator:checked   { image: url(\":/res/lock.png\"); }"
                                "QCheckBox::indicator:unchecked { image: url(\":/res/unlock.png\");   }" );
    SchemeWidgetLayout->addWidget(bindEntries, 0, 1, 0, 1, Qt::AlignVCenter);
    //GBoxOptionsLayout->addWidget(bindEntries, 2, 2);

    connect(pMapContainer, SIGNAL(seedChanged(const QString &)), this, SLOT(seedChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapChanged(const QString &)), this, SLOT(mapChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapgenChanged(MapGenerator)), this, SLOT(mapgenChanged(MapGenerator)));
    connect(pMapContainer, SIGNAL(maze_sizeChanged(int)), this, SLOT(maze_sizeChanged(int)));
    connect(pMapContainer, SIGNAL(themeChanged(const QString &)), this, SLOT(themeChanged(const QString &)));
    connect(pMapContainer, SIGNAL(newTemplateFilter(int)), this, SLOT(templateFilterChanged(int)));
    connect(pMapContainer, SIGNAL(drawMapRequested()), this, SIGNAL(goToDrawMap()));
    connect(pMapContainer, SIGNAL(drawnMapChanged(const QByteArray &)), this, SLOT(onDrawnMapChanged(const QByteArray &)));
}

void GameCFGWidget::jumpToSchemes()
{
    emit goToSchemes(GameSchemes->currentIndex());
}

void GameCFGWidget::jumpToWeapons()
{
    emit goToWeapons(WeaponsName->currentIndex());
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
    if (schemeData(23).toBool())
        result |= 0x01000000;       // more wind

    return result;
}

quint32 GameCFGWidget::getInitHealth() const
{
    return schemeData(26).toInt();
}

QByteArray GameCFGWidget::getFullConfig() const
{
    QList<QByteArray> bcfg;
    int mapgen = pMapContainer->get_mapgen();

    bcfg << QString("eseed " + pMapContainer->getCurrentSeed()).toUtf8();
    bcfg << QString("e$gmflags %1").arg(getGameFlags()).toUtf8();
    bcfg << QString("e$damagepct %1").arg(schemeData(24).toInt()).toUtf8();
    bcfg << QString("e$turntime %1").arg(schemeData(25).toInt() * 1000).toUtf8();
    bcfg << QString("e$sd_turns %1").arg(schemeData(27).toInt()).toUtf8();
    bcfg << QString("e$casefreq %1").arg(schemeData(28).toInt()).toUtf8();
    bcfg << QString("e$minestime %1").arg(schemeData(29).toInt() * 1000).toUtf8();
    bcfg << QString("e$minesnum %1").arg(schemeData(30).toInt()).toUtf8();
    bcfg << QString("e$minedudpct %1").arg(schemeData(31).toInt()).toUtf8();
    bcfg << QString("e$explosives %1").arg(schemeData(32).toInt()).toUtf8();
    bcfg << QString("e$healthprob %1").arg(schemeData(33).toInt()).toUtf8();
    bcfg << QString("e$hcaseamount %1").arg(schemeData(34).toInt()).toUtf8();
    bcfg << QString("e$waterrise %1").arg(schemeData(35).toInt()).toUtf8();
    bcfg << QString("e$healthdec %1").arg(schemeData(36).toInt()).toUtf8();
    bcfg << QString("e$ropepct %1").arg(schemeData(37).toInt()).toUtf8();
    bcfg << QString("e$template_filter %1").arg(pMapContainer->getTemplateFilter()).toUtf8();
    bcfg << QString("e$mapgen %1").arg(mapgen).toUtf8();

    switch (mapgen)
    {
        case MAPGEN_MAZE:
            bcfg << QString("e$maze_size %1").arg(pMapContainer->get_maze_size()).toUtf8();
            break;

        case MAPGEN_DRAWN:
        {
            QByteArray data = pMapContainer->getDrawnMapData();
            while(data.size() > 0)
            {
                QByteArray tmp = data;
                tmp.truncate(200);
                tmp.prepend("edraw ");
                bcfg << tmp;
                data.remove(0, 200);
            }
            break;
        }
        default: ;
    }

    QString currentMap = pMapContainer->getCurrentMap();
    if (currentMap.size() > 0)
    {
        bcfg << QString("emap " + currentMap).toUtf8();
        if(pMapContainer->getCurrentIsMission())
            bcfg << QString("escript Maps/%1/map.lua").arg(currentMap).toUtf8();
    }
    bcfg << QString("etheme " + pMapContainer->getCurrentTheme()).toUtf8();

    if (Scripts->currentIndex() > 0)
    {
        bcfg << QString("escript Scripts/Multiplayer/%1.lua").arg(Scripts->itemData(Scripts->currentIndex()).toList()[0].toString()).toUtf8();
    }

    QByteArray result;

    foreach(QByteArray ba, bcfg)
        HWProto::addByteArrayToBuffer(result, ba);

    return result;
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
    scriptChanged(Scripts->currentIndex());

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
            if (!seedRegexp.exactMatch(value)) {
                pMapContainer->seedEdit->setVisible(true);
                }
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
        if (param == "SCRIPT") {
            Scripts->setCurrentIndex(Scripts->findText(value));
            return;
        }
        if (param == "DRAWNMAP") {
            pMapContainer->setDrawnMapData(qUncompress(QByteArray::fromBase64(slValue[0].toLatin1())));
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

    if (slValue.size() == 3)
    {
        if (param == "FULLGENCFG")
        {
            QString seed = slValue[2];
            if (!seedRegexp.exactMatch(seed))
                pMapContainer->seedEdit->setVisible(true);

            pMapContainer->setMapMapgenSeed(slValue[0], (MapGenerator)slValue[1].toUInt(), seed);
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
    }
}

void GameCFGWidget::mapChanged(const QString & value)
{
    if(isEnabled() && pMapContainer->getCurrentIsMission())
    {
        Scripts->setEnabled(false);
        Scripts->setCurrentIndex(0);

        if (pMapContainer->getCurrentScheme() == "locked")
        {
            GameSchemes->setEnabled(false);
            GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }
        else
        {
            GameSchemes->setEnabled(true);
            int num = GameSchemes->findText(pMapContainer->getCurrentScheme());
            if (num != -1)
                GameSchemes->setCurrentIndex(num);
            else
                GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }

        if (pMapContainer->getCurrentWeapons() == "locked")
        {
            WeaponsName->setEnabled(false);
            WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }
        else
        {
            WeaponsName->setEnabled(true);
            int num = WeaponsName->findText(pMapContainer->getCurrentWeapons());
            if (num != -1)
                WeaponsName->setCurrentIndex(num);
            else
                WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }

        if (pMapContainer->getCurrentScheme() != "locked" && pMapContainer->getCurrentWeapons() != "locked")
            bindEntries->setEnabled(true);
        else
            bindEntries->setEnabled(false);
    }
    else
    {
        Scripts->setEnabled(true);
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

    if (isEnabled() && bindEntries->isEnabled() && bindEntries->isChecked()) {
        QString schemeName = GameSchemes->itemText(index);
        for (int i = 0; i < WeaponsName->count(); i++) {
             QString weapName = WeaponsName->itemText(i);
             int res = QString::compare(weapName, schemeName, Qt::CaseSensitive);
             if (0 == res) {
                 WeaponsName->setCurrentIndex(i);
                 emit ammoChanged(i);
                 break;
             }
        }
    }
}

void GameCFGWidget::scriptChanged(int index)
{
    if(isEnabled() && index > 0)
    {
        QString scheme = Scripts->itemData(Scripts->currentIndex()).toList()[1].toString();
        QString weapons = Scripts->itemData(Scripts->currentIndex()).toList()[2].toString();

        if (scheme == "locked")
        {
            GameSchemes->setEnabled(false);
            GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }
        else
        {
            GameSchemes->setEnabled(true);
            int num = GameSchemes->findText(scheme);
            if (num != -1)
                GameSchemes->setCurrentIndex(num);
            else
                GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }

        if (weapons == "locked")
        {
            WeaponsName->setEnabled(false);
            WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }
        else
        {
            WeaponsName->setEnabled(true);
            int num = WeaponsName->findText(weapons);
            if (num != -1)
                WeaponsName->setCurrentIndex(num);
            else
                WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }

        if (scheme != "locked" && weapons != "locked")
            bindEntries->setEnabled(true);
        else
            bindEntries->setEnabled(false);
    }
    else
    {
        GameSchemes->setEnabled(true);
        WeaponsName->setEnabled(true);
        bindEntries->setEnabled(true);
    }
    emit paramChanged("SCRIPT", QStringList(Scripts->itemText(index)));
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

void GameCFGWidget::onDrawnMapChanged(const QByteArray & data)
{
    emit paramChanged("DRAWNMAP", QStringList(qCompress(data, 9).toBase64()));
}
