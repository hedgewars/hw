/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2012 Igor Ulyanov <iulyanov@gmail.com>
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
#include <QLabel>
#include <QListView>
#include <QVBoxLayout>
#include <QIcon>
#include <QLineEdit>
#include <QMessageBox>
#include <QStringListModel>

#include "hwconsts.h"
#include "mapContainer.h"
#include "igbox.h"
#include "HWApplication.h"

HWMapContainer::HWMapContainer(QWidget * parent) :
    QWidget(parent),
    mainLayout(this),
    pMap(0),
    mapgen(MAPGEN_REGULAR)
{
    hhSmall.load(":/res/hh_small.png");
    hhLimit = 18;
    templateFilter = 0;

    mainLayout.setContentsMargins(HWApplication::style()->pixelMetric(QStyle::PM_LayoutLeftMargin),
                                  1,
                                  HWApplication::style()->pixelMetric(QStyle::PM_LayoutRightMargin),
                                  HWApplication::style()->pixelMetric(QStyle::PM_LayoutBottomMargin));

    QWidget* mapWidget = new QWidget(this);
    mainLayout.addWidget(mapWidget, 0, 0, Qt::AlignHCenter);

    QGridLayout* mapLayout = new QGridLayout(mapWidget);
    mapLayout->setMargin(0);

    imageButt = new QPushButton(mapWidget);
    imageButt->setObjectName("imageButt");
    imageButt->setFixedSize(256 + 6, 128 + 6);
    imageButt->setFlat(true);
    imageButt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);//QSizePolicy::Minimum, QSizePolicy::Minimum);
    mapLayout->addWidget(imageButt, 0, 0, 1, 2);
    connect(imageButt, SIGNAL(clicked()), this, SLOT(setRandomMap()));

    chooseMap = new QComboBox(mapWidget);
    chooseMap->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    m_mapModel = DataManager::instance().mapModel();
    chooseMap->setEditable(false);
    chooseMap->setModel(m_mapModel);

    // update model views after model changes (to e.g. re-adjust separators)
    connect(&DataManager::instance(), SIGNAL(updated()), this, SLOT(updateModelViews()));

    mapLayout->addWidget(chooseMap, 1, 1);

    QLabel * lblMap = new QLabel(tr("Map"), mapWidget);
    mapLayout->addWidget(lblMap, 1, 0);

    lblFilter = new QLabel(tr("Filter"), mapWidget);
    mapLayout->addWidget(lblFilter, 2, 0);

    cbTemplateFilter = new QComboBox(mapWidget);
    cbTemplateFilter->addItem(tr("All"), 0);
    cbTemplateFilter->addItem(tr("Small"), 1);
    cbTemplateFilter->addItem(tr("Medium"), 2);
    cbTemplateFilter->addItem(tr("Large"), 3);
    cbTemplateFilter->addItem(tr("Cavern"), 4);
    cbTemplateFilter->addItem(tr("Wacky"), 5);
    mapLayout->addWidget(cbTemplateFilter, 2, 1);

    connect(cbTemplateFilter, SIGNAL(activated(int)), this, SLOT(setTemplateFilter(int)));

    maze_size_label = new QLabel(tr("Type"), mapWidget);
    mapLayout->addWidget(maze_size_label, 2, 0);
    maze_size_label->hide();
    cbMazeSize = new QComboBox(mapWidget);
    cbMazeSize->addItem(tr("Small tunnels"), 0);
    cbMazeSize->addItem(tr("Medium tunnels"), 1);
    cbMazeSize->addItem(tr("Large tunnels"), 2);
    cbMazeSize->addItem(tr("Small floating islands"), 3);
    cbMazeSize->addItem(tr("Medium floating islands"), 4);
    cbMazeSize->addItem(tr("Large floating islands"), 5);
    cbMazeSize->setCurrentIndex(1);

    mapLayout->addWidget(cbMazeSize, 2, 1);
    cbMazeSize->hide();
    connect(cbMazeSize, SIGNAL(activated(int)), this, SLOT(setMazeSize(int)));

    gbThemes = new IconedGroupBox(mapWidget);
    gbThemes->setTitleTextPadding(80);
    gbThemes->setContentTopPadding(15);
    gbThemes->setTitle(tr("Themes"));

    //gbThemes->setStyleSheet("padding: 0px"); // doesn't work - stylesheet is set with icon
    mapLayout->addWidget(gbThemes, 0, 2, 3, 1);
    // disallow row to be collapsed (so it can't get ignored when Qt applies rowSpan of gbThemes)
    mapLayout->setRowMinimumHeight(2, 13);
    QVBoxLayout * gbTLayout = new QVBoxLayout(gbThemes);
    gbTLayout->setContentsMargins(0, 0, 0 ,0);
    gbTLayout->setSpacing(0);
    lvThemes = new QListView(mapWidget);
    lvThemes->setMinimumHeight(30);
    lvThemes->setFixedWidth(140);
    m_themeModel = DataManager::instance().themeModel();
    lvThemes->setModel(m_themeModel);
    lvThemes->setIconSize(QSize(16, 16));
    lvThemes->setEditTriggers(QListView::NoEditTriggers);

    connect(lvThemes->selectionModel(), SIGNAL(currentRowChanged( const QModelIndex &, const QModelIndex &)), this, SLOT(themeSelected( const QModelIndex &, const QModelIndex &)));

    // override default style to tighten up theme scroller
    lvThemes->setStyleSheet(QString(
                                "QListView{"
                                "border: solid;"
                                "border-width: 0px;"
                                "border-radius: 0px;"
                                "border-color: transparent;"
                                "background-color: #0d0544;"
                                "color: #ffcc00;"
                                "font: bold 13px;"
                                "}"
                            )
                           );

    gbTLayout->addWidget(lvThemes);
    lvThemes->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Minimum);

    mapLayout->setSizeConstraint(QLayout::SetFixedSize);

    QWidget* seedWidget = new QWidget(this);
    mainLayout.addWidget(seedWidget, 1, 0);

    QGridLayout* seedLayout = new QGridLayout(seedWidget);
    seedLayout->setMargin(0);

    seedLabel = new QLabel(tr("Seed"), seedWidget);
    seedLayout->addWidget(seedLabel, 3, 0);
    seedEdit = new QLineEdit(seedWidget);
    seedEdit->setMaxLength(54);
    connect(seedEdit, SIGNAL(returnPressed()), this, SLOT(seedEdited()));
    seedLayout->addWidget(seedEdit, 3, 1);
    seedLayout->setColumnStretch(1, 5);
    seedSet = new QPushButton(seedWidget);
    seedSet->setText(QPushButton::tr("more"));
    connect(seedSet, SIGNAL(clicked()), this, SLOT(seedEdited()));
    seedLayout->setColumnStretch(2, 1);
    seedLayout->addWidget(seedSet, 3, 2);

    seedLabel->setVisible(false);
    seedEdit->setVisible(false);

    setRandomSeed();
    setRandomTheme();

    chooseMap->setCurrentIndex(0);
    mapChanged(0);
    connect(chooseMap, SIGNAL(activated(int)), this, SLOT(mapChanged(int)));

    updateModelViews();
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

    addInfoToPreview(pxres);
    //chooseMap->setCurrentIndex(mapgen);
    pMap = 0;
}

void HWMapContainer::setHHLimit(int newHHLimit)
{
    hhLimit = newHHLimit;
}

void HWMapContainer::mapChanged(int index)
{
    Q_ASSERT(chooseMap->itemData(index, Qt::UserRole + 1).canConvert<MapModel::MapInfo>());
    m_mapInfo = chooseMap->itemData(chooseMap->currentIndex(), Qt::UserRole + 1).value<MapModel::MapInfo>();

    switch(m_mapInfo.type)
    {
        case MapModel::GeneratedMap:
            mapgen = MAPGEN_REGULAR;
            updatePreview();
            gbThemes->show();
            lblFilter->show();
            cbTemplateFilter->show();
            maze_size_label->hide();
            cbMazeSize->hide();
            break;
        case MapModel::GeneratedMaze:
            mapgen = MAPGEN_MAZE;
            updatePreview();
            gbThemes->show();
            lblFilter->hide();
            cbTemplateFilter->hide();
            maze_size_label->show();
            cbMazeSize->show();
            break;
        case MapModel::HandDrawnMap:
            mapgen = MAPGEN_DRAWN;
            updatePreview();
            gbThemes->show();
            lblFilter->hide();
            cbTemplateFilter->hide();
            maze_size_label->hide();
            cbMazeSize->hide();
            break;
        default:
            mapgen = MAPGEN_MAP;
            updatePreview();
            gbThemes->hide();
            lblFilter->hide();
            cbTemplateFilter->hide();
            maze_size_label->hide();
            cbMazeSize->hide();
            m_theme = m_mapInfo.theme;
    }

    // the map has no pre-defined theme, so let's use the selected one
    if (m_mapInfo.theme.isEmpty())
    {
        m_theme = lvThemes->currentIndex().data().toString();
        emit themeChanged(m_theme);
    }
    emit mapChanged(m_mapInfo.name);
    emit mapgenChanged(mapgen);
}

// Should this add text to identify map size?
void HWMapContainer::addInfoToPreview(QPixmap image)
{
    QPixmap finalImage = QPixmap(image.size());
    finalImage.fill(QColor(0, 0, 0, 0));

    QPainter p(&finalImage);
    p.drawPixmap(image.rect(), image);
    //p.setPen(QColor(0xf4,0x9e,0xe9));
    p.setPen(QColor(0xff,0xcc,0x00));
    p.setBrush(QColor(0, 0, 0));
    p.drawRect(image.rect().width() - hhSmall.rect().width() - 28, 3, 40, 20);
    p.setFont(QFont("MS Shell Dlg", 10));
    p.drawText(image.rect().width() - hhSmall.rect().width() - 14 - (hhLimit > 9 ? 10 : 0), 18, QString::number(hhLimit));
    p.drawPixmap(image.rect().width() - hhSmall.rect().width() - 5, 5, hhSmall.rect().width(), hhSmall.rect().height(), hhSmall);

    imageButt->setIcon(finalImage);
    imageButt->setIconSize(image.size());
}

void HWMapContainer::askForGeneratedPreview()
{
    if (pMap)
    {
        disconnect(pMap, 0, this, SLOT(setImage(const QImage)));
        disconnect(pMap, 0, this, SLOT(setHHLimit(int)));
        pMap = 0;
    }

    pMap = new HWMap();
    connect(pMap, SIGNAL(ImageReceived(const QImage)), this, SLOT(setImage(const QImage)));
    connect(pMap, SIGNAL(HHLimitReceived(int)), this, SLOT(setHHLimit(int)));
    pMap->getImage(m_seed,
                   getTemplateFilter(),
                   get_mapgen(),
                   getMazeSize(),
                   getDrawnMapData()
                  );
}

void HWMapContainer::themeSelected(const QModelIndex & current, const QModelIndex &)
{
    m_theme = current.data().toString();

    gbThemes->setIcon(qVariantValue<QIcon>(current.data(Qt::UserRole)));
    emit themeChanged(m_theme);
}

QString HWMapContainer::getCurrentSeed() const
{
    return m_seed;
}

QString HWMapContainer::getCurrentMap() const
{
    if(chooseMap->currentIndex() < MAPGEN_MAP) return QString();
    return(m_mapInfo.name);
}

QString HWMapContainer::getCurrentTheme() const
{
    return(m_theme);
}

bool HWMapContainer::getCurrentIsMission() const
{
    return(m_mapInfo.type == MapModel::MissionMap);
}

int HWMapContainer::getCurrentHHLimit() const
{
    return hhLimit;
}

QString HWMapContainer::getCurrentScheme() const
{
    return(m_mapInfo.scheme);
}

QString HWMapContainer::getCurrentWeapons() const
{
    return(m_mapInfo.weapons);
}

quint32 HWMapContainer::getTemplateFilter() const
{
    return cbTemplateFilter->itemData(cbTemplateFilter->currentIndex()).toInt();
}

void HWMapContainer::resizeEvent ( QResizeEvent * event )
{
    Q_UNUSED(event);
    //imageButt->setIconSize(imageButt->size());
}

void HWMapContainer::intSetSeed(const QString & seed)
{
    m_seed = seed;
    if (seed != seedEdit->text())
        seedEdit->setText(seed);
}

void HWMapContainer::setSeed(const QString & seed)
{
    intSetSeed(seed);
    if ((m_mapInfo.type == MapModel::GeneratedMap) || (m_mapInfo.type == MapModel::GeneratedMaze))
        updatePreview();
}

void HWMapContainer::intSetMap(const QString & map)
{
    int id = 0;
    for(int i = 0; i < chooseMap->count(); i++)
    {
        // skip separators
        if (chooseMap->itemData(i, Qt::AccessibleDescriptionRole) == QLatin1String("separator"))
            continue;
        Q_ASSERT(chooseMap->itemData(i, Qt::UserRole + 1).canConvert<MapModel::MapInfo>());
        MapModel::MapInfo mapInfo = chooseMap->itemData(i, Qt::UserRole + 1).value<MapModel::MapInfo>();

        if (mapInfo.name == map)
        {
            id = i;
            break;
        }
    }

    if(id > 0)
    {
        if (pMap)
        {
            disconnect(pMap, 0, this, SLOT(setImage(const QImage)));
            disconnect(pMap, 0, this, SLOT(setHHLimit(int)));
            pMap = 0;
        }
        chooseMap->setCurrentIndex(id);
    }
}

void HWMapContainer::setMap(const QString &map)
{
    intSetMap(map);
    updatePreview();
}

void HWMapContainer::setTheme(const QString & theme)
{
    QModelIndexList mdl = m_themeModel->match(m_themeModel->index(0), Qt::DisplayRole, theme);

    if(mdl.size())
        lvThemes->setCurrentIndex(mdl.at(0));
}

void HWMapContainer::setRandomMap()
{
    setRandomSeed();
    switch(m_mapInfo.type)
    {
        case MapModel::GeneratedMap:
        case MapModel::GeneratedMaze:
            setRandomTheme();
            break;
        case MapModel::HandDrawnMap:
            emit drawMapRequested();
            break;
        case MapModel::MissionMap:
            setRandomMission();
            break;
        case MapModel::StaticMap:
            setRandomStatic();
            break;
        case MapModel::Invalid:
            Q_ASSERT(false);
    }
}

void HWMapContainer::setRandomStatic()
{
    int i = MAPGEN_MAP + 3 + numMissions + rand() % (chooseMap->count() - MAPGEN_MAP - 3 - numMissions);
    chooseMap->setCurrentIndex(i);
    mapChanged(i);
}

void HWMapContainer::setRandomMission()
{
    int i = MAPGEN_MAP + 2 + rand() % numMissions;
    chooseMap->setCurrentIndex(i);
    mapChanged(i);
}

void HWMapContainer::setRandomSeed()
{
    setSeed(QUuid::createUuid().toString());
    emit seedChanged(m_seed);
}

void HWMapContainer::setRandomTheme()
{
    if(!m_themeModel->rowCount()) return;
    quint32 themeNum = rand() % m_themeModel->rowCount();
    lvThemes->setCurrentIndex(m_themeModel->index(themeNum));
}

void HWMapContainer::intSetTemplateFilter(int filter)
{
    cbTemplateFilter->setCurrentIndex(filter);
    emit newTemplateFilter(filter);
}

void HWMapContainer::setTemplateFilter(int filter)
{
    intSetTemplateFilter(filter);
    updatePreview();
}

MapGenerator HWMapContainer::get_mapgen(void) const
{
    return mapgen;
}

int HWMapContainer::getMazeSize(void) const
{
    return cbMazeSize->currentIndex();
}

void HWMapContainer::intSetMazeSize(int size)
{
    cbMazeSize->setCurrentIndex(size);
    emit mazeSizeChanged(size);
}

void HWMapContainer::setMazeSize(int size)
{
    intSetMazeSize(size);
    updatePreview();
}

void HWMapContainer::intSetMapgen(MapGenerator m)
{
    mapgen = m;

    if(m != MAPGEN_MAP)
        chooseMap->setCurrentIndex(m);

    emit mapgenChanged(m);
}

void HWMapContainer::setMapgen(MapGenerator m)
{
    intSetMapgen(m);
    updatePreview();
}

void HWMapContainer::setDrawnMapData(const QByteArray & ar)
{
    drawMapScene.decode(ar);
    updatePreview();
}

QByteArray HWMapContainer::getDrawnMapData()
{
    return drawMapScene.encode();
}

void HWMapContainer::seedEdited()
{
    if (seedLabel->isVisible() == false )
    {
        seedLabel->setVisible(true);
        seedEdit->setVisible(true);
        seedSet->setText(tr("Set"));
        return;
    }

    if (seedEdit->text().isEmpty())
        seedEdit->setText(m_seed);
    else
    {
        setSeed(seedEdit->text());
        emit seedChanged(seedEdit->text());
    }
}

DrawMapScene * HWMapContainer::getDrawMapScene()
{
    return &drawMapScene;
}

void HWMapContainer::mapDrawingFinished()
{
    emit drawnMapChanged(getDrawnMapData());

    updatePreview();
}

void HWMapContainer::updatePreview()
{
    switch(m_mapInfo.type)
    {
        case MapModel::GeneratedMap:
            askForGeneratedPreview();
            break;
        case MapModel::GeneratedMaze:
            askForGeneratedPreview();
            break;
        case MapModel::HandDrawnMap:
            askForGeneratedPreview();
            break;
        default:
            QPixmap mapImage;
            bool success = mapImage.load(
                DataManager::instance().findFileForRead(
                    "Maps/" + m_mapInfo.name + "/preview.png")
            );

            if(!success)
            {
                imageButt->setIcon(QIcon());
                return;
            }

            hhLimit = m_mapInfo.limit;
            addInfoToPreview(mapImage);
    }
}

void HWMapContainer::setAllMapParameters(const QString &map, MapGenerator m, int mazesize, const QString &seed, int tmpl)
{
    intSetMap(map);
    intSetMapgen(m);
    intSetMazeSize(mazesize);
    intSetSeed(seed);
    intSetTemplateFilter(tmpl);

    updatePreview();
}


void HWMapContainer::updateModelViews()
{
    numMissions = m_mapModel->missionCount();

    if (!m_mapInfo.name.isEmpty())
        intSetMap(m_mapInfo.name);
}
