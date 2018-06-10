/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QResizeEvent>
#include <QGroupBox>
#include <QCheckBox>
#include <QGridLayout>
#include <QSpinBox>
#include <QLabel>
#include <QMessageBox>
#include <QTableView>
#include <QScrollBar>
#include <QTabWidget>
#include <QPushButton>
#include <QDebug>
#include <QList>

#include "gamecfgwidget.h"
#include "igbox.h"
#include "DataManager.h"
#include "hwconsts.h"
#include "gameSchemeModel.h"
#include "proto.h"
#include "GameStyleModel.h"
#include "themeprompt.h"

GameCFGWidget::GameCFGWidget(QWidget* parent, bool randomWithoutDLC) :
    QGroupBox(parent)
    , mainLayout(this)
    , seedRegexp("\\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\}")
{
    mainLayout.setMargin(0);
    setMinimumHeight(310);
    setMaximumHeight(447);
    setMinimumWidth(470);
    setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    m_master = true;

    // Easy containers for the map/game options in either stacked or tabbed mode

    mapContainerFree = new QWidget();
    mapContainerTabbed = new QWidget();
    optionsContainerFree = new QWidget();
    optionsContainerTabbed = new QWidget();
    tabbed = false;

    // Container for when in tabbed mode

    tabs = new QTabWidget(this);
    tabs->setFixedWidth(470);
    tabs->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding);
    tabs->addTab(mapContainerTabbed, tr("Map"));
    tabs->addTab(optionsContainerTabbed, tr("Game options"));
    tabs->setObjectName("gameCfgWidgetTabs");
    mainLayout.addWidget(tabs, 1);
    tabs->setVisible(false);

    // Container for when in stacked mode

    StackContainer = new QWidget();
    StackContainer->setObjectName("gameStackContainer");
    mainLayout.addWidget(StackContainer, 1);
    QVBoxLayout * stackLayout = new QVBoxLayout(StackContainer);

    // Map options

    pMapContainer = new HWMapContainer(mapContainerFree);
    pMapContainer->setRandomWithoutDLC(randomWithoutDLC);
    stackLayout->addWidget(mapContainerFree, 0, Qt::AlignHCenter);
    pMapContainer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    pMapContainer->setFixedSize(width() - 14, 278);
    mapContainerFree->setFixedSize(pMapContainer->width(), pMapContainer->height());

    // Horizontal divider

    QFrame * divider = new QFrame();
    divider->setFrameShape(QFrame::HLine);
    divider->setFrameShadow(QFrame::Plain);
    stackLayout->addWidget(divider, 0, Qt::AlignBottom);
    //stackLayout->setRowMinimumHeight(1, 10);

    // Game options

    optionsContainerTabbed->setContentsMargins(0, 0, 0, 0);
    optionsContainerFree->setFixedSize(width() - 14, 140);
    stackLayout->addWidget(optionsContainerFree, 0, Qt::AlignHCenter);

    OptionsInnerContainer = new QWidget(optionsContainerFree);
    m_childWidgets << OptionsInnerContainer;
    OptionsInnerContainer->setFixedSize(optionsContainerFree->width(), optionsContainerFree->height());
    OptionsInnerContainer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    GBoxOptionsLayout = new QGridLayout(OptionsInnerContainer);

    lblScript = new QLabel(QLabel::tr("Style"), this);
    GBoxOptionsLayout->addWidget(lblScript, 1, 0);

    Scripts = new QComboBox(this);
    Scripts->setMaxVisibleItems(30);
    GBoxOptionsLayout->addWidget(Scripts, 1, 1);
    Scripts->setModel(DataManager::instance().gameStyleModel());
    m_curScript = Scripts->currentText();

    ScriptsLabel = new QLabel(this);
    ScriptsLabel->setHidden(true);
    ScriptsLabel->setTextFormat(Qt::PlainText);
    GBoxOptionsLayout->addWidget(ScriptsLabel, 1, 1);

    connect(Scripts, SIGNAL(currentIndexChanged(int)), this, SLOT(scriptChanged(int)));

    QWidget *SchemeWidget = new QWidget(this);
    GBoxOptionsLayout->addWidget(SchemeWidget, 2, 0, 1, 2);

    QGridLayout *SchemeWidgetLayout = new QGridLayout(SchemeWidget);
    SchemeWidgetLayout->setMargin(0);

    GameSchemes = new QComboBox(SchemeWidget);
    GameSchemes->setMaxVisibleItems(30);
    SchemeWidgetLayout->addWidget(GameSchemes, 0, 2);

    GameSchemesLabel = new QLabel(SchemeWidget);
    GameSchemesLabel->setHidden(true);
    GameSchemesLabel->setTextFormat(Qt::PlainText);
    SchemeWidgetLayout->addWidget(GameSchemesLabel, 0, 2);

    connect(GameSchemes, SIGNAL(currentIndexChanged(int)), this, SLOT(schemeChanged(int)));

    lblScheme = new QLabel(QLabel::tr("Scheme"), SchemeWidget);
    SchemeWidgetLayout->addWidget(lblScheme, 0, 0);

    QPixmap pmEdit(":/res/edit.png");
    QIcon iconEdit = QIcon(pmEdit);

    goToSchemePage = new QPushButton(SchemeWidget);
    goToSchemePage->setWhatsThis(tr("Edit schemes"));
    goToSchemePage->setIconSize(pmEdit.size());
    goToSchemePage->setIcon(iconEdit);
    goToSchemePage->setMaximumWidth(pmEdit.width() + 6);
    SchemeWidgetLayout->addWidget(goToSchemePage, 0, 3);
    connect(goToSchemePage, SIGNAL(clicked()), this, SLOT(jumpToSchemes()));

    lblWeapons = new QLabel(QLabel::tr("Weapons"), SchemeWidget);
    SchemeWidgetLayout->addWidget(lblWeapons, 1, 0);

    WeaponsName = new QComboBox(SchemeWidget);
    WeaponsName->setMaxVisibleItems(30);
    SchemeWidgetLayout->addWidget(WeaponsName, 1, 2);

    WeaponsNameLabel = new QLabel(SchemeWidget);
    WeaponsNameLabel->setHidden(true);
    WeaponsNameLabel->setTextFormat(Qt::PlainText);
    SchemeWidgetLayout->addWidget(WeaponsNameLabel, 1, 2);

    connect(WeaponsName, SIGNAL(currentIndexChanged(int)), this, SLOT(ammoChanged(int)));

    goToWeaponPage = new QPushButton(SchemeWidget);
    goToWeaponPage->setWhatsThis(tr("Edit weapons"));
    goToWeaponPage->setIconSize(pmEdit.size());
    goToWeaponPage->setIcon(pmEdit);
    goToWeaponPage->setMaximumWidth(pmEdit.width() + 6);
    SchemeWidgetLayout->addWidget(goToWeaponPage, 1, 3);
    connect(goToWeaponPage, SIGNAL(clicked()), this, SLOT(jumpToWeapons()));

    bindEntries = new QCheckBox(SchemeWidget);
    bindEntries->setWhatsThis(tr("Game scheme will auto-select a weapon"));
    bindEntries->setChecked(true);
    bindEntries->setMaximumWidth(42);
    bindEntries->setStyleSheet( "QCheckBox::indicator:checked:enabled    { image: url(\":/res/lock.png\"); }"
                                "QCheckBox::indicator:checked:disabled   { image: url(\":/res/lock_disabled.png\"); }"
                                "QCheckBox::indicator:unchecked:enabled  { image: url(\":/res/unlock.png\");   }"
                                "QCheckBox::indicator:unchecked:disabled { image: url(\":/res/unlock_disabled.png\");   }" );
    SchemeWidgetLayout->addWidget(bindEntries, 0, 1, 0, 1, Qt::AlignVCenter);

    connect(pMapContainer, SIGNAL(seedChanged(const QString &)), this, SLOT(seedChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapChanged(const QString &)), this, SLOT(mapChanged(const QString &)));
    connect(pMapContainer, SIGNAL(mapgenChanged(MapGenerator)), this, SLOT(mapgenChanged(MapGenerator)));
    connect(pMapContainer, SIGNAL(mazeSizeChanged(int)), this, SLOT(maze_sizeChanged(int)));
    connect(pMapContainer, SIGNAL(mapFeatureSizeChanged(int)), this, SLOT(slMapFeatureSizeChanged(int)));
    connect(pMapContainer, SIGNAL(themeChanged(const QString &)), this, SLOT(themeChanged(const QString &)));
    connect(pMapContainer, SIGNAL(newTemplateFilter(int)), this, SLOT(templateFilterChanged(int)));
    connect(pMapContainer, SIGNAL(drawMapRequested()), this, SIGNAL(goToDrawMap()));
    connect(pMapContainer, SIGNAL(drawnMapChanged(const QByteArray &)), this, SLOT(onDrawnMapChanged(const QByteArray &)));

    connect(&DataManager::instance(), SIGNAL(updated()), this, SLOT(updateModelViews()));
}

void GameCFGWidget::setTabbed(bool tabbed)
{
    if (tabbed && !this->tabbed)
    { // Make tabbed
        tabs->setCurrentIndex(0);
        StackContainer->setVisible(false);
        tabs->setVisible(true);
        pMapContainer->setParent(mapContainerTabbed);
        OptionsInnerContainer->setParent(optionsContainerTabbed);
        pMapContainer->setVisible(true);
        setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding);
        this->tabbed = true;
    }
    else if (!tabbed && this->tabbed)
    { // Make stacked
        pMapContainer->setParent(mapContainerFree);
        OptionsInnerContainer->setParent(optionsContainerFree);
        tabs->setVisible(false);
        StackContainer->setVisible(true);
        pMapContainer->setVisible(true);
        setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        this->tabbed = false;
    }

    // Restore scrollbar palettes, since Qt seems to forget them easily when switching parents
    QList<QScrollBar *> allSBars = findChildren<QScrollBar *>();
    QPalette pal = palette();
    pal.setColor(QPalette::WindowText, QColor(0xff, 0xcc, 0x00));
    pal.setColor(QPalette::Button, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Base, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));

    for (int i = 0; i < allSBars.size(); ++i)
        allSBars.at(i)->setPalette(pal);
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
    if (schemeData(24).toBool())
        result |= 0x02000000;       // tag team
    if (schemeData(25).toBool())
        result |= 0x04000000;       // bottom

    return result;
}

quint32 GameCFGWidget::getInitHealth() const
{
    return schemeData(28).toInt();
}

QByteArray GameCFGWidget::getFullConfig() const
{
    QList<QByteArray> bcfg;
    int mapgen = pMapContainer->get_mapgen();
    if (Scripts->currentIndex() > 0)
    {
        bcfg << QString("escript Scripts/Multiplayer/%1.lua").arg(Scripts->itemData(Scripts->currentIndex(), GameStyleModel::ScriptRole).toString()).toUtf8();
    }

    QString currentMap = pMapContainer->getCurrentMap();
    if (currentMap.size() > 0)
    {
        bcfg << QString("emap " + currentMap).toUtf8();

// engine should figure it out on its own
//        if(pMapContainer->getCurrentIsMission())
//            bcfg << QString("escript Maps/%1/map.lua").arg(currentMap).toUtf8();
    }
    bcfg << QString("etheme " + pMapContainer->getCurrentTheme()).toUtf8();

    bcfg << QString("eseed " + pMapContainer->getCurrentSeed()).toUtf8();
    bcfg << QString("e$gmflags %1").arg(getGameFlags()).toUtf8();
    bcfg << QString("e$damagepct %1").arg(schemeData(26).toInt()).toUtf8();
    bcfg << QString("e$turntime %1").arg(schemeData(27).toInt() * 1000).toUtf8();
    bcfg << QString("e$sd_turns %1").arg(schemeData(29).toInt()).toUtf8();
    bcfg << QString("e$casefreq %1").arg(schemeData(30).toInt()).toUtf8();
    bcfg << QString("e$minestime %1").arg(schemeData(31).toInt() * 1000).toUtf8();
    bcfg << QString("e$minesnum %1").arg(schemeData(32).toInt()).toUtf8();
    bcfg << QString("e$minedudpct %1").arg(schemeData(33).toInt()).toUtf8();
    bcfg << QString("e$explosives %1").arg(schemeData(34).toInt()).toUtf8();
    bcfg << QString("e$airmines %1").arg(schemeData(35).toInt()).toUtf8();
    bcfg << QString("e$healthprob %1").arg(schemeData(36).toInt()).toUtf8();
    bcfg << QString("e$hcaseamount %1").arg(schemeData(37).toInt()).toUtf8();
    bcfg << QString("e$waterrise %1").arg(schemeData(38).toInt()).toUtf8();
    bcfg << QString("e$healthdec %1").arg(schemeData(39).toInt()).toUtf8();
    bcfg << QString("e$ropepct %1").arg(schemeData(40).toInt()).toUtf8();
    bcfg << QString("e$getawaytime %1").arg(schemeData(41).toInt()).toUtf8();
    bcfg << QString("e$worldedge %1").arg(schemeData(42).toInt()).toUtf8();
    bcfg << QString("e$template_filter %1").arg(pMapContainer->getTemplateFilter()).toUtf8();
    bcfg << QString("e$feature_size %1").arg(pMapContainer->getFeatureSize()).toUtf8();
    bcfg << QString("e$mapgen %1").arg(mapgen).toUtf8();
    if(!schemeData(43).isNull())
        bcfg << QString("e$scriptparam %1").arg(schemeData(43).toString()).toUtf8();
    else
        bcfg << QString("e$scriptparam ").toUtf8();


    switch (mapgen)
    {
        case MAPGEN_MAZE:
        case MAPGEN_PERLIN:
            bcfg << QString("e$maze_size %1").arg(pMapContainer->getMazeSize()).toUtf8();
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
        default:
            ;
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
    {
        QMessageBox illegalMsg(parentWidget());
        illegalMsg.setIcon(QMessageBox::Warning);
        illegalMsg.setWindowTitle(QMessageBox::tr("Error"));
        illegalMsg.setText(QMessageBox::tr("Cannot use the weapon scheme '%1'!").arg(name));
        illegalMsg.setWindowModality(Qt::WindowModal);
        illegalMsg.exec();
    }

    int pos = WeaponsName->findText(name);
    if ((pos == -1) || illegal)   // prevent from overriding schemes with bad ones
    {
        WeaponsName->addItem(name, ammo);
        WeaponsName->setCurrentIndex(WeaponsName->count() - 1);
    }
    else
    {
        WeaponsName->setItemData(pos, ammo);
        WeaponsName->setCurrentIndex(pos);
    }
}

void GameCFGWidget::fullNetConfig()
{
    ammoChanged(WeaponsName->currentIndex());

    seedChanged(pMapContainer->getCurrentSeed());
    templateFilterChanged(pMapContainer->getTemplateFilter());

    QString t = pMapContainer->getCurrentTheme();
    if(!t.isEmpty())
        themeChanged(t);

    schemeChanged(GameSchemes->currentIndex());
    scriptChanged(Scripts->currentIndex());

    mapgenChanged(pMapContainer->get_mapgen());
    maze_sizeChanged(pMapContainer->getMazeSize());
    slMapFeatureSizeChanged(pMapContainer->getFeatureSize());

    if(pMapContainer->get_mapgen() == 2)
        onDrawnMapChanged(pMapContainer->getDrawnMapData());

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
        if (param == "MAP")
        {
            pMapContainer->setMap(value);
            return;
        }
        if (param == "SEED")
        {
            pMapContainer->setSeed(value);
            return;
        }
        if (param == "THEME")
        {
            pMapContainer->setTheme(value);
            return;
        }
        if (param == "TEMPLATE")
        {
            pMapContainer->setTemplateFilter(value.toUInt());
            return;
        }
        if (param == "MAPGEN")
        {
            pMapContainer->setMapgen((MapGenerator)value.toUInt());
            return;
        }
        if (param == "FEATURE_SIZE")
        {
            pMapContainer->setFeatureSize(value.toUInt());
            return;
        }
        if (param == "MAZE_SIZE")
        {
            pMapContainer->setMazeSize(value.toUInt());
            return;
        }
        if (param == "SCRIPT")
        {
            int in = Scripts->findText(value);
            Scripts->setCurrentIndex(in);
            ScriptsLabel->setText(value);
            pMapContainer->setScript(Scripts->itemData(Scripts->currentIndex(), GameStyleModel::ScriptRole).toString().toUtf8(), schemeData(43).toString());
            return;
        }
        if (param == "DRAWNMAP")
        {
            pMapContainer->setDrawnMapData(qUncompress(QByteArray::fromBase64(slValue[0].toLatin1())));
            return;
        }
    }

    if (slValue.size() == 2)
    {
        if (param == "AMMO")
        {
            setNetAmmo(slValue[0], slValue[1]);
            return;
        }
    }

    if (slValue.size() == 6)
    {
        if (param == "FULLMAPCONFIG")
        {
            QString seed = slValue[4];

            pMapContainer->setAllMapParameters(
                slValue[1],
                (MapGenerator)slValue[2].toUInt(),
                slValue[3].toUInt(),
                seed,
                slValue[5].toUInt(),
                slValue[0].toUInt()
            );
            return;
        }
    }

    qWarning("Got bad config param from net");
}

void GameCFGWidget::ammoChanged(int index)
{
    if (index >= 0)
    {
        WeaponsNameLabel->setText(WeaponsName->currentText());
        emit paramChanged(
            "AMMO",
            QStringList() << WeaponsName->itemText(index) << WeaponsName->itemData(index).toString()
        );
    }
    else
    {
        WeaponsNameLabel->setText("");
    }
}

void GameCFGWidget::mapChanged(const QString & value)
{
    if(isEnabled() && pMapContainer->getCurrentIsMission())
    {
        Scripts->setEnabled(false);
        lblScript->setEnabled(false);
        Scripts->setCurrentIndex(0);

        if (pMapContainer->getCurrentScheme() == "locked")
        {
            GameSchemes->setEnabled(false);
            goToSchemePage->setEnabled(false);
            lblScheme->setEnabled(false);
            GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }
        else
        {
            GameSchemes->setEnabled(true);
            goToSchemePage->setEnabled(true);
            lblScheme->setEnabled(true);
            int num = GameSchemes->findText(pMapContainer->getCurrentScheme());
            if (num != -1)
                GameSchemes->setCurrentIndex(num);
            //else
            //    GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }

        if (pMapContainer->getCurrentWeapons() == "locked")
        {
            WeaponsName->setEnabled(false);
            goToWeaponPage->setEnabled(false);
            lblWeapons->setEnabled(false);
            WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }
        else
        {
            WeaponsName->setEnabled(true);
            goToWeaponPage->setEnabled(true);
            lblWeapons->setEnabled(true);
            int num = WeaponsName->findText(pMapContainer->getCurrentWeapons());
            if (num != -1)
                WeaponsName->setCurrentIndex(num);
            //else
            //    WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }

        if (pMapContainer->getCurrentScheme() != "locked" && pMapContainer->getCurrentWeapons() != "locked")
            bindEntries->setEnabled(true);
        else
            bindEntries->setEnabled(false);
    }
    else
    {
        Scripts->setEnabled(true);
        lblScript->setEnabled(true);
        GameSchemes->setEnabled(true);
        goToSchemePage->setEnabled(true);
        lblScheme->setEnabled(true);
        WeaponsName->setEnabled(true);
        goToWeaponPage->setEnabled(true);
        lblWeapons->setEnabled(true);
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

    if (sl.size() >= 42)
    {
        sl[sl.size()-1].prepend('!');
        emit paramChanged("SCHEME", sl);  // this is a stupid hack for the fact that SCHEME is being sent once, empty. Still need to find out why.
    }

    if (isEnabled() && bindEntries->isEnabled() && bindEntries->isChecked())
    {
        QString schemeName = GameSchemes->itemText(index);
        for (int i = 0; i < WeaponsName->count(); i++)
        {
            QString weapName = WeaponsName->itemText(i);
            int res = QString::compare(weapName, schemeName, Qt::CaseSensitive);
            if (0 == res)
            {
                WeaponsName->setCurrentIndex(i);
                emit ammoChanged(i);
                break;
            }
        }
    }

    if(index == -1)
        GameSchemesLabel->setText("");
    else
        GameSchemesLabel->setText(GameSchemes->currentText());

    pMapContainer->setScript(Scripts->itemData(Scripts->currentIndex(), GameStyleModel::ScriptRole).toString().toUtf8(), schemeData(43).toString());
}

void GameCFGWidget::scriptChanged(int index)
{
    const QString & name = Scripts->itemText(index);
    m_curScript = name;

    if(isEnabled() && index > 0)
    {
        QString scheme = Scripts->itemData(index, GameStyleModel::SchemeRole).toString();
        QString weapons = Scripts->itemData(index, GameStyleModel::WeaponsRole).toString();

        if (scheme == "locked")
        {
            GameSchemes->setEnabled(false);
            goToSchemePage->setEnabled(false);
            lblScheme->setEnabled(false);
            GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }
        else if (m_master)
        {
            GameSchemes->setEnabled(true);
            goToSchemePage->setEnabled(true);
            lblScheme->setEnabled(true);
            int num = GameSchemes->findText(scheme);
            if (num != -1)
                GameSchemes->setCurrentIndex(num);
            //else
            //    GameSchemes->setCurrentIndex(GameSchemes->findText("Default"));
        }

        if (weapons == "locked")
        {
            WeaponsName->setEnabled(false);
            goToWeaponPage->setEnabled(false);
            lblWeapons->setEnabled(false);
            WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }
        else if (m_master)
        {
            WeaponsName->setEnabled(true);
            goToWeaponPage->setEnabled(true);
            lblWeapons->setEnabled(true);
            int num = WeaponsName->findText(weapons);
            if (num != -1)
                WeaponsName->setCurrentIndex(num);
            //else
            //    WeaponsName->setCurrentIndex(WeaponsName->findText("Default"));
        }

        if (scheme != "locked" && weapons != "locked")
            bindEntries->setEnabled(true);
        else
            bindEntries->setEnabled(false);
    }
    else
    {
        GameSchemes->setEnabled(true);
        goToSchemePage->setEnabled(true);
        lblScheme->setEnabled(true);
        WeaponsName->setEnabled(true);
        goToWeaponPage->setEnabled(true);
        lblWeapons->setEnabled(true);
        bindEntries->setEnabled(true);
    }
    if (index == -1)
    {
        pMapContainer->setScript(QString(""), QString(""));
        ScriptsLabel->setStyleSheet("color: #b50000;");
    }
    else
    {
        pMapContainer->setScript(Scripts->itemData(index, GameStyleModel::ScriptRole).toString().toUtf8(), schemeData(43).toString());
        ScriptsLabel->setText(Scripts->currentText());
        ScriptsLabel->setStyleSheet("");
    }

    emit paramChanged("SCRIPT", QStringList(name));
}

void GameCFGWidget::mapgenChanged(MapGenerator m)
{
    emit paramChanged("MAPGEN", QStringList(QString::number(m)));
}

void GameCFGWidget::maze_sizeChanged(int s)
{
    emit paramChanged("MAZE_SIZE", QStringList(QString::number(s)));
}

void GameCFGWidget::slMapFeatureSizeChanged(int s)
{
    emit paramChanged("FEATURE_SIZE", QStringList(QString::number(s)));
}

void GameCFGWidget::resendSchemeData()
{
    schemeChanged(GameSchemes->currentIndex());
}

void GameCFGWidget::resendAmmoData()
{
    ammoChanged(WeaponsName->currentIndex());
}

void GameCFGWidget::onDrawnMapChanged(const QByteArray & data)
{
    emit paramChanged("DRAWNMAP", QStringList(qCompress(data, 9).toBase64()));
}


void GameCFGWidget::updateModelViews()
{
    // restore game-style selection
    if (!m_curScript.isEmpty())
    {
        int idx = Scripts->findText(m_curScript);
        if (idx >= 0)
            Scripts->setCurrentIndex(idx);
        else
            Scripts->setCurrentIndex(0);
    }
}

bool GameCFGWidget::isMaster()
{
    return m_master;
}

void GameCFGWidget::setMaster(bool master)
{
    if (master == m_master) return;
    m_master = master;

    if (master)
    {
        // Reset script if not found
        if (Scripts->currentIndex() == -1)
        {
            Scripts->setCurrentIndex(Scripts->findText("Normal"));
        }
    }

    pMapContainer->setMaster(master);

    GameSchemes->setHidden(!master);
    WeaponsName->setHidden(!master);
    Scripts->setHidden(!master);
    goToSchemePage->setHidden(!master);
    goToWeaponPage->setHidden(!master);
    bindEntries->setHidden(!master);

    GameSchemesLabel->setHidden(master);
    WeaponsNameLabel->setHidden(master);
    ScriptsLabel->setHidden(master);

    foreach (QWidget *widget, m_childWidgets)
        widget->setEnabled(master);
}
