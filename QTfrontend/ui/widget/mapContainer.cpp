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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QBitmap>
#include <QBuffer>
#include <QColor>
#include <QDebug>
#include <QFile>
#include <QFileDialog>
#include <QIcon>
#include <QInputDialog>
#include <QLabel>
#include <QLinearGradient>
#include <QLineEdit>
#include <QListView>
#include <QListWidget>
#include <QListWidgetItem>
#include <QMessageBox>
#include <QPainter>
#include <QPushButton>
#include <QSlider>
#include <QStringListModel>
#include <QTextStream>
#include <QUuid>
#include <QVBoxLayout>

#include "hwconsts.h"
#include "mapContainer.h"
#include "themeprompt.h"
#include "seedprompt.h"
#include "igbox.h"
#include "HWApplication.h"
#include "ThemeModel.h"



HWMapContainer::HWMapContainer(QWidget * parent) :
    QWidget(parent),
    mainLayout(this),
    pMap(0),
    mapgen(MAPGEN_REGULAR),
    m_previewSize(256, 128)
{
    // don't show preview anything until first show event
    m_previewEnabled = false;
    m_missionsViewSetup = false;
    m_staticViewSetup = false;
    m_script = QString();
    m_prevMapFeatureSize = 12;
    m_mapFeatureSize = 12;
    m_withoutDLC = false;
    m_missingMap = false;

    hhSmall.load(":/res/hh_small.png");
    hhLimit = 18;
    templateFilter = 0;
    m_master = true;

    linearGradNormal = QLinearGradient(QPoint(128, 0), QPoint(128, 128));
    linearGradNormal.setColorAt(1, QColor(0, 0, 192));
    linearGradNormal.setColorAt(0, QColor(66, 115, 225));

    linearGradLoading = QLinearGradient(QPoint(128, 0), QPoint(128, 128));
    linearGradLoading.setColorAt(1, QColor(58, 58, 137));
    linearGradLoading.setColorAt(0, QColor(90, 109, 153));

    linearGradMapError = QLinearGradient(QPoint(128, 0), QPoint(128, 128));
    linearGradMapError.setColorAt(1, QColor(255, 1, 0));
    linearGradMapError.setColorAt(0, QColor(255, 119, 0));

    linearGradNoPreview = QLinearGradient(QPoint(128, 0), QPoint(128, 128));
    linearGradNoPreview.setColorAt(1, QColor(15, 9, 72));
    linearGradNoPreview.setColorAt(0, QColor(15, 9, 72));

    mainLayout.setContentsMargins(HWApplication::style()->pixelMetric(QStyle::PM_LayoutLeftMargin),
                                  10,
                                  HWApplication::style()->pixelMetric(QStyle::PM_LayoutRightMargin),
                                  HWApplication::style()->pixelMetric(QStyle::PM_LayoutBottomMargin));

    m_staticMapModel = DataManager::instance().staticMapModel();
    m_missionMapModel = DataManager::instance().missionMapModel();
    m_themeModel = DataManager::instance().themeModel();

    /* Layouts */

    QWidget * topWidget = new QWidget();
    QHBoxLayout * topLayout = new QHBoxLayout(topWidget);
    topWidget->setContentsMargins(0, 0, 0, 0);
    topLayout->setContentsMargins(0, 0, 0, 0);

    twoColumnLayout = new QHBoxLayout();
    QVBoxLayout * leftLayout = new QVBoxLayout();
    leftLayout->setAlignment(Qt::AlignLeft);
    QVBoxLayout * rightLayout = new QVBoxLayout();
    twoColumnLayout->addLayout(leftLayout, 0);
    twoColumnLayout->addLayout(rightLayout, 0);
    QVBoxLayout * drawnControls = new QVBoxLayout();

    /* Map type label */

    QLabel* lblMapType = new QLabel(tr("Map type:"));
    topLayout->setSpacing(10);
    topLayout->addWidget(lblMapType, 0);
    m_childWidgets << lblMapType;

    /* Map type combobox */

    cType = new QComboBox(this);
    topLayout->addWidget(cType, 1);
    cType->insertItem(0, tr("Image map"), MapModel::StaticMap);
    cType->insertItem(1, tr("Mission map"), MapModel::MissionMap);
    cType->insertItem(2, tr("Hand-drawn"), MapModel::HandDrawnMap);
    cType->insertItem(3, tr("Randomly generated"), MapModel::GeneratedMap);
    cType->insertItem(4, tr("Random maze"), MapModel::GeneratedMaze);
    cType->insertItem(5, tr("Random perlin"), MapModel::GeneratedPerlin);
    cType->insertItem(6, tr("Forts"), MapModel::FortsMap);
    connect(cType, SIGNAL(currentIndexChanged(int)), this, SLOT(mapTypeChanged(int)));
    m_childWidgets << cType;

    /* Randomize button */

    topLayout->addStretch(1);
    const QIcon& lp = QIcon(":/res/dice.png");
    QSize sz = lp.actualSize(QSize(65535, 65535));
    btnRandomize = new QPushButton();
    btnRandomize->setText(tr("Random"));
    btnRandomize->setIcon(lp);
    btnRandomize->setFixedHeight(30);
    btnRandomize->setIconSize(sz);
    btnRandomize->setFlat(true);
    btnRandomize->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    connect(btnRandomize, SIGNAL(clicked()), this, SLOT(setRandomMap()));

    m_childWidgets << btnRandomize;
    btnRandomize->setStyleSheet("padding: 5px;");
    btnRandomize->setFixedHeight(cType->height());
    topLayout->addWidget(btnRandomize, 1);

    /* Seed button */

    btnSeed = new QPushButton(parentWidget()->parentWidget());
    //: Refers to the "random seed"; the source of randomness in the game
    btnSeed->setText(tr("Seed"));
    btnSeed->setWhatsThis(tr("View and edit the seed, the source of randomness in the game"));
    btnSeed->setStyleSheet("padding: 5px;");
    btnSeed->setFixedHeight(cType->height());
    connect(btnSeed, SIGNAL(clicked()), this, SLOT(showSeedPrompt()));
    topLayout->addWidget(btnSeed, 0);

    /* Map preview label */

    QLabel * lblMapPreviewText = new QLabel(this);
    lblMapPreviewText->setText(tr("Map preview:"));
    leftLayout->addWidget(lblMapPreviewText, 0);
    m_childWidgets << lblMapPreviewText;

    /* Map Preview */

    mapPreview = new QPushButton(this);
    mapPreview->setObjectName("mapPreview");
    mapPreview->setFlat(true);
    mapPreview->setFixedSize(256 + 6, 128 + 6);
    mapPreview->setContentsMargins(0, 0, 0, 0);
    leftLayout->addWidget(mapPreview, 0);
    connect(mapPreview, SIGNAL(clicked()), this, SLOT(previewClicked()));
    m_childWidgets << mapPreview;

    /* Bottom-Left layout */

    QVBoxLayout * bottomLeftLayout = new QVBoxLayout();
    leftLayout->addLayout(bottomLeftLayout, 1);

    /* Map list label */

    lblMapList = new QLabel(this);
    lblMapList->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Minimum);
    lblMapList->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    rightLayout->addWidget(lblMapList, 0);
    m_childWidgets << lblMapList;

    /* Static maps list */

    staticMapList = new QListView(this);
    rightLayout->addWidget(staticMapList, 1);
    m_childWidgets << staticMapList;

    /* Mission maps list */

    missionMapList = new QListView(this);
    rightLayout->addWidget(missionMapList, 1);
    m_childWidgets << missionMapList;

    /* Map name (when not room master) */
    /* We use a QTextEdit instead of QLabel because it is able
       to wrap at any character. */
    teMapName = new QTextEdit(this);
    teMapName->setObjectName("mapName");
    teMapName->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Minimum);
    teMapName->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    /* Boilerplate to emulate a QLabel */
    teMapName->setReadOnly(true);
    teMapName->setAcceptRichText(false);
    teMapName->setFrameStyle(QFrame::NoFrame);
    teMapName->setStyleSheet("background-color: transparent");

    teMapName->setLineWrapMode(QTextEdit::WidgetWidth);
    teMapName->setWordWrapMode(QTextOption::WrapAtWordBoundaryOrAnywhere);

    rightLayout->addWidget(teMapName, 1);
    m_childWidgets << teMapName;

    /* Map load and edit buttons */

    drawnControls->addStretch(1);

    btnLoadMap = new QPushButton(tr("Load map drawing"));
    btnLoadMap->setStyleSheet("padding: 20px;");
    drawnControls->addWidget(btnLoadMap, 0);
    m_childWidgets << btnLoadMap;
    connect(btnLoadMap, SIGNAL(clicked()), this, SLOT(loadDrawing()));

    btnEditMap = new QPushButton(tr("Edit map drawing"));
    btnEditMap->setStyleSheet("padding: 20px;");
    drawnControls->addWidget(btnEditMap, 0);
    m_childWidgets << btnEditMap;
    connect(btnEditMap, SIGNAL(clicked()), this, SIGNAL(drawMapRequested()));

    drawnControls->addStretch(1);

    rightLayout->addLayout(drawnControls);

    /* Generator style list */

    generationStyles = new QListWidget(this);
    new QListWidgetItem(tr("All"), generationStyles);
    new QListWidgetItem(tr("Small"), generationStyles);
    new QListWidgetItem(tr("Medium"), generationStyles);
    new QListWidgetItem(tr("Large"), generationStyles);
    new QListWidgetItem(tr("Cavern"), generationStyles);
    new QListWidgetItem(tr("Wacky"), generationStyles);
    connect(generationStyles, SIGNAL(currentRowChanged(int)), this, SLOT(setTemplateFilter(int)));
    m_childWidgets << generationStyles;
    rightLayout->addWidget(generationStyles, 1);

    /* Maze style list */

    mazeStyles = new QListWidget(this);
    new QListWidgetItem(tr("Small tunnels"), mazeStyles);
    new QListWidgetItem(tr("Medium tunnels"), mazeStyles);
    new QListWidgetItem(tr("Large tunnels"), mazeStyles);
    new QListWidgetItem(tr("Small islands"), mazeStyles);
    new QListWidgetItem(tr("Medium islands"), mazeStyles);
    new QListWidgetItem(tr("Large islands"), mazeStyles);
    connect(mazeStyles, SIGNAL(currentRowChanged(int)), this, SLOT(setMazeSize(int)));
    m_childWidgets << mazeStyles;
    rightLayout->addWidget(mazeStyles, 1);

    mapFeatureSize = new QSlider(Qt::Horizontal, this);
    mapFeatureSize->setObjectName("mapFeatureSize");
    //mapFeatureSize->setTickPosition(QSlider::TicksBelow);
    mapFeatureSize->setMaximum(25);
    mapFeatureSize->setMinimum(1);
    //mapFeatureSize->setFixedWidth(259);
    mapFeatureSize->setValue(m_mapFeatureSize);
    mapFeatureSize->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
    bottomLeftLayout->addWidget(mapFeatureSize, 0);
    connect(mapFeatureSize, SIGNAL(valueChanged(int)), this, SLOT(setFeatureSize(int)));
    m_childWidgets << mapFeatureSize;

    /* Mission description */

    lblDesc = new QLabel();
    lblDesc->setWordWrap(true);
    lblDesc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    lblDesc->setAlignment(Qt::AlignBottom | Qt::AlignLeft);
    lblDesc->setStyleSheet("font: 10px;");
    bottomLeftLayout->addWidget(lblDesc, 100);

    /* Add stretch above theme button */

    bottomLeftLayout->addStretch(1);

    /* Theme chooser */
    QHBoxLayout * themeHBox = new QHBoxLayout();

    btnRandTheme = new QPushButton();
    btnRandTheme->setWhatsThis(tr("Randomize the theme"));
    btnRandTheme->setIcon(lp);
    btnRandTheme->setIconSize(QSize(24, 24));
    btnRandTheme->setFixedHeight(30);
    btnRandTheme->setFixedWidth(30);
    connect(btnRandTheme, SIGNAL(clicked()), this, SLOT(setRandomTheme()));
    m_childWidgets << btnRandTheme;
    themeHBox->addWidget(btnRandTheme, 0);

    btnTheme = new QPushButton(this);
    btnTheme->setWhatsThis(tr("Choose a theme"));
    btnTheme->setFlat(true);
    btnTheme->setIconSize(QSize(30, 30));
    btnTheme->setFixedHeight(30);
    btnTheme->setMaximumWidth(222);
    connect(btnTheme, SIGNAL(clicked()), this, SLOT(showThemePrompt()));
    m_childWidgets << btnTheme;
    themeHBox->addWidget(btnTheme, 1);

    bottomLeftLayout->addLayout(themeHBox);

    /* Add everything to main layout */

    mainLayout.addWidget(topWidget, 0);
    mainLayout.addLayout(twoColumnLayout, 1);

    /* Set defaults */

    setRandomSeed();
    setMazeSize(0);
    setTemplateFilter(0);
    staticMapChanged(m_staticMapModel->index(0, 0));
    missionMapChanged(m_missionMapModel->index(0, 0));
    changeMapType(MapModel::GeneratedMap);
}

void HWMapContainer::onImageReceived(const QPixmap &newImage)
{
    // When image received from the engine.
    switch (m_mapInfo.type)
    {
        case MapModel::GeneratedMap:
        case MapModel::GeneratedMaze:
        case MapModel::GeneratedPerlin:
        case MapModel::HandDrawnMap:
        case MapModel::FortsMap:
            setImage(newImage);
            break;
        // Throw away image if we have switched the map mode in the meantime
        default:
            return;
    }
}

void HWMapContainer::setImage(const QPixmap &newImage)
{
    addInfoToPreview(newImage);
    pMap = 0;

    cType->setEnabled(isMaster());
}

void HWMapContainer::setImage(const QPixmap &newImage, const QLinearGradient &linearGrad, bool showHHLimit)
{
    addInfoToPreview(newImage, linearGrad, showHHLimit);

    pMap = 0;

    cType->setEnabled(isMaster());
}


void HWMapContainer::setHHLimit(int newHHLimit)
{
    hhLimit = newHHLimit;
}

void HWMapContainer::addInfoToPreview(const QPixmap &image)
{
    addInfoToPreview(image, linearGradNormal, true);
}

// Should this add text to identify map size?
void HWMapContainer::addInfoToPreview(const QPixmap &image, const QLinearGradient &linearGrad, bool drawHHLimit)
{
    QPixmap finalImage = QPixmap(image.size());
    QPainter p(&finalImage);

    p.fillRect(finalImage.rect(), linearGrad);
    p.drawPixmap(finalImage.rect(), image);

    if (drawHHLimit)
    {
        p.setPen(QColor(0xff,0xcc,0x00));
        p.setBrush(QColor(0, 0, 0));
        p.setFont(QFont("MS Shell Dlg", 10));

        p.drawRect(finalImage.rect().width() - hhSmall.rect().width() - 28, 3, 40, 20);

        QString text = (hhLimit > 0) ? QString::number(hhLimit) : "?";
        p.drawText(finalImage.rect().width() - hhSmall.rect().width() - 14 - (hhLimit > 9 ? 10 : 0), 18, text);
        p.drawPixmap(finalImage.rect().width() - hhSmall.rect().width() - 5, 5, hhSmall.rect().width(), hhSmall.rect().height(), hhSmall);
    }

    // Set the map preview image. Make sure it is always colored the same,
    // no matter if disabled or not.
    QIcon mapPreviewIcon = QIcon();
    mapPreviewIcon.addPixmap(finalImage, QIcon::Normal);
    mapPreviewIcon.addPixmap(finalImage, QIcon::Disabled);
    mapPreview->setIcon(mapPreviewIcon);
    mapPreview->setIconSize(finalImage.size());
}

void HWMapContainer::askForGeneratedPreview()
{
    pMap = new HWMap(this);
    connect(pMap, SIGNAL(ImageReceived(QPixmap)), this, SLOT(onImageReceived(const QPixmap)));
    connect(pMap, SIGNAL(HHLimitReceived(int)), this, SLOT(setHHLimit(int)));
    connect(pMap, SIGNAL(destroyed(QObject *)), this, SLOT(onPreviewMapDestroyed(QObject *)));
    pMap->getImage(m_seed,
                   getTemplateFilter(),
                   get_mapgen(),
                   getMazeSize(),
                   getDrawnMapData(),
                   m_script,
                   m_scriptparam,
		           m_mapFeatureSize
                  );

    setHHLimit(0);

    QPixmap waitImage(m_previewSize);
    waitImage.fill(Qt::transparent);

    QPainter p(&waitImage);
    const QPixmap waitIcon(":/res/iconTime.png");
    int x = (waitImage.width() - waitIcon.width()) / 2;
    int y = (waitImage.height() - waitIcon.height()) / 2;
    p.drawPixmap(QPoint(x, y), waitIcon);

    setImage(waitImage, linearGradLoading, false);

    cType->setEnabled(false);
}

void HWMapContainer::previewClicked()
{
    if (isMaster()) // should only perform these if master, but disabling the button when not, causes an unattractive preview.
        switch (m_mapInfo.type)
        {
            case MapModel::HandDrawnMap:
                emit drawMapRequested();
                break;
            default:
                setRandomMap();
                break;
        }
}

QString HWMapContainer::getCurrentSeed() const
{
    return m_seed;
}

QString HWMapContainer::getCurrentMap() const
{
    switch (m_mapInfo.type)
    {
        case MapModel::StaticMap:
        case MapModel::MissionMap:
            return m_curMap;
        default:
            return QString();
    }
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
    return generationStyles->currentRow();
}

quint32 HWMapContainer::getFeatureSize() const
{
    return m_mapFeatureSize;
}

void HWMapContainer::resizeEvent ( QResizeEvent * event )
{
    Q_UNUSED(event);
}

void HWMapContainer::intSetSeed(const QString & seed)
{
    m_seed = seed;
}

void HWMapContainer::setSeed(const QString & seed)
{
    intSetSeed(seed);
    if ((m_mapInfo.type == MapModel::GeneratedMap)
            || (m_mapInfo.type == MapModel::GeneratedMaze)
            || (m_mapInfo.type == MapModel::GeneratedPerlin))
        updatePreview();
}

void HWMapContainer::setScript(const QString & script, const QString & scriptparam)
{
    m_script = script;
    m_scriptparam = scriptparam;
    if ((m_mapInfo.type == MapModel::GeneratedMap)
            || (m_mapInfo.type == MapModel::GeneratedMaze)
            || (m_mapInfo.type == MapModel::GeneratedPerlin)
            || (m_mapInfo.type == MapModel::HandDrawnMap))
        updatePreview();
}

void HWMapContainer::intSetMap(const QString & map)
{
    if (map == "+rnd+")
    {
        //changeMapType(MapModel::GeneratedMap);
    }
    else if (map == "+maze+")
    {
        //changeMapType(MapModel::GeneratedMaze);
    }
    else if (map == "+perlin+")
    {
        //changeMapType(MapModel::GeneratedPerlin);
    }
    else if (map == "+drawn+")
    {
        //changeMapType(MapModel::HandDrawnMap);
    }
    else if (map == "+forts+")
    {
        //nuffin
    }
    else if (m_staticMapModel->mapExists(map))
    {
        m_missingMap = false;
        changeMapType(MapModel::StaticMap, m_staticMapModel->index(m_staticMapModel->findMap(map), 0));
    }
    else if (m_missionMapModel->mapExists(map))
    {
        m_missingMap = false;
        changeMapType(MapModel::MissionMap, m_missionMapModel->index(m_missionMapModel->findMap(map), 0));
    } else
    {
        qDebug() << "HWMapContainer::intSetMap: Map doesn't exist: " << map;
        m_missingMap = true;
        m_curMap = map;
        m_mapInfo.name = map;
        setMapNameLabel(map, false);
        if (m_mapInfo.type == MapModel::StaticMap)
            setupStaticMapsView(m_curMap);
        else if (m_mapInfo.type == MapModel::MissionMap)
            setupMissionMapsView(m_curMap);
        else
        {
            m_mapInfo.type = MapModel::StaticMap;
            setupStaticMapsView(m_curMap);
            changeMapType(m_mapInfo.type, QModelIndex());
        }
        updatePreview();
    }
}

void HWMapContainer::setMap(const QString & map)
{
    if ((m_mapInfo.type == MapModel::Invalid) || (map != m_mapInfo.name) || m_missingMap)
        intSetMap(map);
}

void HWMapContainer::setTheme(const QString & theme)
{
    QModelIndexList mdl = m_themeModel->match(m_themeModel->index(0), ThemeModel::ActualNameRole, theme);

    if(mdl.size())
        updateTheme(mdl.at(0));
    else
        setMissingTheme(theme);
}

void HWMapContainer::setRandomMap()
{
    if (!m_master) return;

    setRandomSeed();

    QSortFilterProxyModel * mmodel = NULL;

    switch(m_mapInfo.type)
    {
        case MapModel::GeneratedMap:
        case MapModel::GeneratedMaze:
        case MapModel::GeneratedPerlin:
        case MapModel::FortsMap:
            setRandomTheme();
            break;
        case MapModel::MissionMap:
            if (m_withoutDLC)
            {
                mmodel = m_missionMapModel->withoutDLC();
                missionMapChanged(mmodel->mapToSource(mmodel->index(rand() % mmodel->rowCount(),0)));
            }
            else
                missionMapChanged(m_missionMapModel->index(rand() % m_missionMapModel->rowCount(),0));
            break;
        case MapModel::StaticMap:
            if (m_withoutDLC)
            {
                mmodel = m_staticMapModel->withoutDLC();
                staticMapChanged(mmodel->mapToSource(mmodel->index(rand() % mmodel->rowCount(),0)));
            }
            else
                staticMapChanged(m_staticMapModel->index(rand() % m_staticMapModel->rowCount(),0));
            break;
        default:
            break;
    }
}

void HWMapContainer::setRandomSeed()
{
    setSeed(QUuid::createUuid().toString());
    emit seedChanged(m_seed);
}

void HWMapContainer::setRandomWithoutDLC(bool withoutDLC)
{
    m_withoutDLC = withoutDLC;
}

void HWMapContainer::setRandomTheme()
{
    QAbstractItemModel * tmodel;

    if (m_withoutDLC)
        tmodel = m_themeModel->withoutDLCOrHidden();
    else
        tmodel = m_themeModel->withoutHidden();

    if(!tmodel->rowCount()) return;
    quint32 themeNum = rand() % tmodel->rowCount();
    updateTheme(tmodel->index(themeNum,0));
    emit themeChanged(m_theme);
}

void HWMapContainer::intSetTemplateFilter(int filter)
{
    generationStyles->setCurrentRow(filter);
    emit newTemplateFilter(filter);
}

void HWMapContainer::setTemplateFilter(int filter)
{
    intSetTemplateFilter(filter);
    if (m_mapInfo.type == MapModel::GeneratedMap)
        updatePreview();
}

MapGenerator HWMapContainer::get_mapgen(void) const
{
    return mapgen;
}

int HWMapContainer::getMazeSize(void) const
{
    return mazeStyles->currentRow();
}

void HWMapContainer::intSetMazeSize(int size)
{
    mazeStyles->setCurrentRow(size);
    emit mazeSizeChanged(size);
}

void HWMapContainer::setMazeSize(int size)
{
    intSetMazeSize(size);
    if (m_mapInfo.type == MapModel::GeneratedMaze)
        updatePreview();
}

void HWMapContainer::intSetMapgen(MapGenerator m)
{
    if (mapgen != m)
    {
        mapgen = m;

        bool f = false;
        switch (m)
        {
            case MAPGEN_REGULAR:
                m_mapInfo.type = MapModel::GeneratedMap;
                f = true;
                break;
            case MAPGEN_MAZE:
                m_mapInfo.type = MapModel::GeneratedMaze;
                f = true;
                break;
            case MAPGEN_PERLIN:
                m_mapInfo.type = MapModel::GeneratedPerlin;
                f = true;
                break;
            case MAPGEN_DRAWN:
                m_mapInfo.type = MapModel::HandDrawnMap;
                f = true;
                break;
            case MAPGEN_FORTS:
                m_mapInfo.type = MapModel::FortsMap;
                f = true;
                break;
            case MAPGEN_MAP:
                switch (m_mapInfo.type)
                {
                    case MapModel::GeneratedMap:
                    case MapModel::GeneratedMaze:
                    case MapModel::GeneratedPerlin:
                    case MapModel::HandDrawnMap:
                    case MapModel::FortsMap:
                        m_mapInfo.type = MapModel::Invalid;
                    default:
                        break;
                }
                break;
        }

        if(f)
            changeMapType(m_mapInfo.type, QModelIndex());
    }
}

void HWMapContainer::setMapgen(MapGenerator m)
{
    intSetMapgen(m);
    if(m != MAPGEN_MAP)
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

void HWMapContainer::setNewSeed(const QString & newSeed)
{
    setSeed(newSeed);
    emit seedChanged(newSeed);
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

void HWMapContainer::showEvent(QShowEvent * event)
{
    if (!m_previewEnabled)
    {
        m_previewEnabled = true;
        setRandomTheme();
        updatePreview();
    }
    QWidget::showEvent(event);
}

void HWMapContainer::updatePreview()
{
    // abort if the widget isn't supposed to show anything yet
    if (!m_previewEnabled)
        return;

    if (pMap)
    {
        disconnect(pMap, 0, this, SLOT(onImageReceived(const QPixmap)));
        disconnect(pMap, 0, this, SLOT(setHHLimit(int)));
        disconnect(pMap, 0, this, SLOT(onPreviewMapDestroyed(QObject *)));
        pMap = 0;
    }

    QPixmap failPixmap;
    QIcon failIcon;

    switch(m_mapInfo.type)
    {
        case MapModel::Invalid:
            // Map error image
            failPixmap = QPixmap(":/res/missingMap.png");
            setImage(failPixmap, linearGradMapError, false);
            lblDesc->clear();
            break;
        case MapModel::GeneratedMap:
        case MapModel::GeneratedMaze:
        case MapModel::GeneratedPerlin:
        case MapModel::HandDrawnMap:
        case MapModel::FortsMap:
            askForGeneratedPreview();
            break;
        default:
            // For maps loaded from image
            if(m_missingMap)
            {
                // Map error image due to missing map
                failPixmap = QPixmap(":/res/missingMap.png");
                setImage(failPixmap, linearGradMapError, false);
                lblDesc->clear();
                break;
            }
            else
            {
                // Draw map preview
                QPixmap mapImage;
                bool success = mapImage.load("physfs://Maps/" + m_mapInfo.name + "/preview.png");

                setHHLimit(m_mapInfo.limit);
                if(!success)
                {
                    // Missing preview image
                    QPixmap empty = QPixmap(m_previewSize);
                    empty.fill(Qt::transparent);
                    setImage(empty, linearGradNoPreview, true);
                    return;
                }
                setImage(mapImage);
            }
    }
}

void HWMapContainer::setAllMapParameters(const QString &map, MapGenerator m, int mazesize, const QString &seed, int tmpl, int featureSize)
{
    intSetMapgen(m);
    intSetMazeSize(mazesize);
    intSetSeed(seed);
    intSetTemplateFilter(tmpl);
    // this one last because it will refresh the preview
    intSetMap(map);
    intSetMazeSize(mazesize);
    intSetFeatureSize(featureSize);
}

void HWMapContainer::updateModelViews()
{
    // restore theme selection
    // do this before map selection restore, because map may overwrite theme
    if (!m_theme.isNull() && !m_theme.isEmpty())
    {
        QModelIndexList mdl = m_themeModel->match(m_themeModel->index(0), Qt::DisplayRole, m_theme);
        if (mdl.size() > 0)
            updateTheme(mdl.at(0));
        else
            setRandomTheme();
    }

    // restore map selection
    if (!m_curMap.isNull() && !m_curMap.isEmpty())
        intSetMap(m_curMap);
    else
        updatePreview();
}


void HWMapContainer::onPreviewMapDestroyed(QObject * map)
{
    if (map == pMap)
        pMap = 0;
}

void HWMapContainer::mapTypeChanged(int index)
{
    changeMapType((MapModel::MapType)cType->itemData(index).toInt());
}

void HWMapContainer::updateHelpTexts(MapModel::MapType type)
{
    QString randomAll = tr("Randomize the map, theme and seed");
    QString randomNoMap = tr("Randomize the theme and seed");
    QString randomSeed = tr("Randomize the seed");
    QString randomAllPrev = tr("Click to randomize the map, theme and seed");
    QString randomNoMapPrev = tr("Click to randomize the theme and seed");
    QString mfsComplex = QString(tr("Adjust the complexity of the generated map"));
    QString mfsFortsDistance = QString(tr("Adjust the distance between forts"));
    switch (type)
    {
        case MapModel::GeneratedMap:
        case MapModel::GeneratedPerlin:
        case MapModel::GeneratedMaze:
            mapPreview->setWhatsThis(randomAllPrev);
            mapFeatureSize->setWhatsThis(mfsComplex);
            btnRandomize->setWhatsThis(randomAll);
            break;
        case MapModel::MissionMap:
        case MapModel::StaticMap:
            mapPreview->setWhatsThis(randomAllPrev);
            btnRandomize->setWhatsThis(randomAll);
            break;
        case MapModel::HandDrawnMap:
            mapPreview->setWhatsThis(tr("Click to edit"));
            btnRandomize->setWhatsThis(randomSeed);
            break;
        case MapModel::FortsMap:
            mapPreview->setWhatsThis(randomNoMapPrev);
            mapFeatureSize->setWhatsThis(mfsFortsDistance);
            btnRandomize->setWhatsThis(randomNoMap);
            break;
        default:
            break;
    }
}
 

void HWMapContainer::changeMapType(MapModel::MapType type, const QModelIndex & newMap)
{
    staticMapList->hide();
    missionMapList->hide();
    teMapName->hide();
    lblMapList->hide();
    generationStyles->hide();
    mazeStyles->hide();
    lblDesc->hide();
    btnLoadMap->hide();
    btnEditMap->hide();
    mapFeatureSize->show();

    switch (type)
    {
        case MapModel::GeneratedMap:
            mapgen = MAPGEN_REGULAR;
            setMapInfo(MapModel::MapInfoRandom);
            lblMapList->setText(tr("Map size:"));
            lblMapList->show();
            generationStyles->show();
            break;
        case MapModel::GeneratedMaze:
            mapgen = MAPGEN_MAZE;
            setMapInfo(MapModel::MapInfoMaze);
            lblMapList->setText(tr("Maze style:"));
            lblMapList->show();
            mazeStyles->show();
            break;
        case MapModel::GeneratedPerlin:
            mapgen = MAPGEN_PERLIN;
            setMapInfo(MapModel::MapInfoPerlin);
            lblMapList->setText(tr("Style:"));
            lblMapList->show();
            mazeStyles->show();
            break;
        case MapModel::HandDrawnMap:
            mapgen = MAPGEN_DRAWN;
            setMapInfo(MapModel::MapInfoDrawn);
            btnLoadMap->show();
            mapFeatureSize->hide();
            btnEditMap->show();
            break;
        case MapModel::MissionMap:
            setupMissionMapsView();
            mapgen = MAPGEN_MAP;
            missionMapChanged(newMap.isValid() ? newMap : missionMapList->currentIndex());
            lblMapList->setText(tr("Mission:"));
            lblMapList->show();
            setMapNameLabel(m_curMap, !m_missingMap);
            if(m_master)
            {
                missionMapList->show();
            }
            else
            {
                teMapName->show();
            }
            mapFeatureSize->hide();
            lblDesc->setText(m_mapInfo.desc);
            lblDesc->show();
            emit mapChanged(m_curMap);
            break;
        case MapModel::StaticMap:
            setupStaticMapsView();
            mapgen = MAPGEN_MAP;
            staticMapChanged(newMap.isValid() ? newMap : staticMapList->currentIndex());
            lblMapList->setText(tr("Map:"));
            lblMapList->show();
            setMapNameLabel(m_curMap, !m_missingMap);
            if(m_master)
            {
                staticMapList->show();
            }
            else
            {
                teMapName->show();
            }
            mapFeatureSize->hide();
            emit mapChanged(m_curMap);
            break;
        case MapModel::FortsMap:
            mapgen = MAPGEN_FORTS;
            setMapInfo(MapModel::MapInfoForts);
            lblMapList->hide();
            break;
        default:
            break;
    }

    // Update theme button size
    updateThemeButtonSize();

    // Update “What's This?” help texts
    updateHelpTexts(type);

    // Update cType combobox
    for (int i = 0; i < cType->count(); i++)
    {
        if ((MapModel::MapType)cType->itemData(i).toInt() == type)
        {
            cType->setCurrentIndex(i);
            break;
        }
    }

    repaint();

    emit mapgenChanged(mapgen);
}

void HWMapContainer::intSetFeatureSize(int val)
{
    mapFeatureSize->setValue(val);    
    updateHelpTexts((MapModel::MapType)cType->itemData(cType->currentIndex()).toInt());
    emit mapFeatureSizeChanged(val);
}
void HWMapContainer::setFeatureSize(int val)
{
    m_mapFeatureSize = val;
    intSetFeatureSize(val);
    //m_mapFeatureSize = val>>2<<2;
    //if (qAbs(m_prevMapFeatureSize-m_mapFeatureSize) > 4)
    {
        m_prevMapFeatureSize = m_mapFeatureSize;
        updatePreview();
    }
}

// unused because I needed the space for the slider
void HWMapContainer::updateThemeButtonSize()
{
    if (m_mapInfo.type != MapModel::StaticMap && m_mapInfo.type != MapModel::HandDrawnMap)
    {
        btnTheme->setIconSize(QSize(30, 30));
        btnTheme->setFixedHeight(30);
        btnRandTheme->setFixedHeight(30);
        btnRandTheme->setIconSize(QSize(24, 24));
    }
    else
    {
        QSize iconSize = btnTheme->icon().actualSize(QSize(65535, 65535));
        btnRandTheme->setFixedHeight(64);
        btnTheme->setFixedHeight(64);
        btnTheme->setIconSize(iconSize);
        btnRandTheme->setIconSize(QSize(32, 32));
    }

    repaint();
}

void HWMapContainer::showThemePrompt()
{
    ThemePrompt prompt(m_themeID, this);
    int theme = prompt.exec() - 1; // Since 0 means canceled, so all indexes are +1'd
    if (theme < 0) return;

    QModelIndex current = m_themeModel->index(theme, 0);
    updateTheme(current);
    emit themeChanged(m_theme);
}

void HWMapContainer::updateTheme(const QModelIndex & current)
{
    m_theme = selectedTheme = current.data(ThemeModel::ActualNameRole).toString();
    m_themeID = current.row();
    QIcon icon = current.data(Qt::DecorationRole).value<QIcon>();
    btnTheme->setIcon(icon);
    QString themeLabel = tr("Theme: %1").arg(current.data(Qt::DisplayRole).toString());
    btnTheme->setText(themeLabel);
    updateThemeButtonSize();
}

void HWMapContainer::staticMapChanged(const QModelIndex & map, const QModelIndex & old)
{
    mapChanged(map, 0, old);
}

void HWMapContainer::missionMapChanged(const QModelIndex & map, const QModelIndex & old)
{
    mapChanged(map, 1, old);
}

// Type: 0 = static, 1 = mission
void HWMapContainer::mapChanged(const QModelIndex & map, int type, const QModelIndex & old)
{
    QListView * mapList;

    if (type == 0)
    {
        mapList = staticMapList;
        m_mapInfo.type = MapModel::StaticMap;
    }
    else if (type == 1)
    {
        mapList = missionMapList;
        m_mapInfo.type = MapModel::MissionMap;
    }
    else
        return;

    // Make sure it is a valid index
    if (!map.isValid())
    {
        // Make sure there's always a valid selection in the map list
        if (old.isValid())
        {
            mapList->setCurrentIndex(old);
            mapList->scrollTo(old);
        }
        m_mapInfo.type = MapModel::Invalid;
        m_missingMap = true;
        updatePreview();
        return;
    }

    // If map changed, update list selection
    if (mapList->currentIndex() != map)
    {
        mapList->setCurrentIndex(map);
        mapList->scrollTo(map);
    }
    if (m_missingMap)
    {
        m_missingMap = false;
        updatePreview();
    }

    Q_ASSERT(map.data(Qt::UserRole + 1).canConvert<MapModel::MapInfo>()); // Houston, we have a problem.
    setMapInfo(map.data(Qt::UserRole + 1).value<MapModel::MapInfo>());
}

void HWMapContainer::setMapInfo(MapModel::MapInfo mapInfo)
{
    m_mapInfo = mapInfo;
    m_curMap = m_mapInfo.name;

    // the map has no pre-defined theme, so let's use the selected one
    if (m_mapInfo.theme.isNull() || m_mapInfo.theme.isEmpty())
    {
        if (!selectedTheme.isNull() && !selectedTheme.isEmpty())
        {
            setTheme(selectedTheme);
            emit themeChanged(selectedTheme);
        }
    }
    else
    {
        setTheme(m_mapInfo.theme);
        emit themeChanged(m_mapInfo.theme);
    }

    lblDesc->setText(mapInfo.desc);

    updatePreview();
    emit mapChanged(m_curMap);
}

void HWMapContainer::loadDrawing()
{
    QString loadDir = QDir(cfgdir->absolutePath() + "/DrawnMaps").absolutePath();
    QString fileName = QFileDialog::getOpenFileName(this, tr("Load drawn map"), loadDir, tr("Drawn Maps") + " (*.hwmap);;" + tr("All files") + " (*)");

    if(fileName.isEmpty()) return;

    QFile f(fileName);

    if(!f.open(QIODevice::ReadOnly))
    {
        QMessageBox errorMsg(parentWidget());
        errorMsg.setIcon(QMessageBox::Warning);
        errorMsg.setWindowTitle(QMessageBox::tr("File error"));
        errorMsg.setText(QMessageBox::tr("Cannot open '%1' for reading").arg(fileName));
        errorMsg.setWindowModality(Qt::WindowModal);
        errorMsg.exec();
    }
    else
    {
        drawMapScene.decode(qUncompress(QByteArray::fromBase64(f.readAll())));
        mapDrawingFinished();
    }
}

void HWMapContainer::showSeedPrompt()
{
    SeedPrompt prompt(parentWidget()->parentWidget(), getCurrentSeed(), isMaster());
    connect(&prompt, SIGNAL(seedSelected(const QString &)), this, SLOT(setNewSeed(const QString &)));
    prompt.exec();
}

bool HWMapContainer::isMaster()
{
    return m_master;
}

void HWMapContainer::setMaster(bool master)
{
    if (master == m_master) return;
    m_master = master;

    foreach (QWidget *widget, m_childWidgets)
        widget->setEnabled(master);

    if(m_mapInfo.type == MapModel::StaticMap)
    {
        teMapName->setHidden(master);
        staticMapList->setVisible(master);
    }
    else if(m_mapInfo.type == MapModel::MissionMap)
    {
        teMapName->setHidden(master);
        missionMapList->setVisible(master);
    }

    if(master)
    {
        // Room delegation cleanup if we get room control.

        if(m_missingMap)
        {
            // Reset map if we don't have the host's map
            m_missingMap = false;
            if(m_mapInfo.type == MapModel::MissionMap)
            {
                missionMapList->selectionModel()->setCurrentIndex(m_missionMapModel->index(0, 0), QItemSelectionModel::Clear | QItemSelectionModel::SelectCurrent);
            }
            else
            {
                if(m_mapInfo.type != MapModel::StaticMap)
                {
                    changeMapType(MapModel::StaticMap);
                }
                staticMapList->selectionModel()->setCurrentIndex(m_staticMapModel->index(0, 0), QItemSelectionModel::Clear | QItemSelectionModel::SelectCurrent);
            }
        }
        else
        {
            // Set random theme if we don't have it
            QModelIndexList mdl = m_themeModel->match(m_themeModel->index(0), ThemeModel::ActualNameRole, m_theme);
            if(!mdl.size())
                setRandomTheme();
        }
    }
    else
    {
        setMapNameLabel(m_curMap, true);
    }
}

void HWMapContainer::setMissingTheme(const QString & name)
{
    if (name.isNull() || name.isEmpty()) return;

    m_theme = name;
    QPixmap pixMissing = QPixmap(":/res/missingTheme@2x.png");
    QIcon iconMissing  = QIcon();
    iconMissing.addPixmap(pixMissing, QIcon::Normal);
    iconMissing.addPixmap(pixMissing, QIcon::Disabled);
    btnTheme->setIcon(iconMissing);
    // Question mark in front of theme name denotes it's missing
    btnTheme->setText(tr("Theme: %1").arg("?" + name));
    updateThemeButtonSize();
}

void HWMapContainer::setupMissionMapsView(const QString & initialMap)
{
    if(m_missionsViewSetup) return;
    m_missionsViewSetup = true;

    m_missionMapModel->loadMaps();
    missionMapList->setModel(m_missionMapModel);
    missionMapList->setEditTriggers(QAbstractItemView::NoEditTriggers);
    QItemSelectionModel * missionSelectionModel = missionMapList->selectionModel();
    connect(missionSelectionModel,
            SIGNAL(currentRowChanged(const QModelIndex &, const QModelIndex &)),
            this,
            SLOT(missionMapChanged(const QModelIndex &, const QModelIndex &)));
    int m = 0;
    if(!initialMap.isNull())
        m = m_missionMapModel->findMap(initialMap);
    missionSelectionModel->setCurrentIndex(m_missionMapModel->index(m, 0), QItemSelectionModel::Clear | QItemSelectionModel::SelectCurrent);
}

void HWMapContainer::setupStaticMapsView(const QString & initialMap)
{
    if(m_staticViewSetup) return;
    m_staticViewSetup = true;

    m_staticMapModel->loadMaps();
    staticMapList->setModel(m_staticMapModel);
    staticMapList->setEditTriggers(QAbstractItemView::NoEditTriggers);
    QItemSelectionModel * staticSelectionModel = staticMapList->selectionModel();
    connect(staticSelectionModel,
            SIGNAL(currentRowChanged(const QModelIndex &, const QModelIndex &)),
            this,
            SLOT(staticMapChanged(const QModelIndex &, const QModelIndex &)));
    int m = 0;
    if(!initialMap.isNull())
        m = m_staticMapModel->findMap(initialMap);
    staticSelectionModel->setCurrentIndex(m_staticMapModel->index(m, 0), QItemSelectionModel::Clear | QItemSelectionModel::SelectCurrent);
}

// Call this function instead of setting the text of the map name label
// directly.
void HWMapContainer::setMapNameLabel(QString mapName, bool validMap)
{
    // Cut off insanely long names to be displayed
    if(mapName.length() >= 90)
    {
        mapName.truncate(84);
        mapName.append(" (...)");
    }
    teMapName->setPlainText(mapName);
    if(validMap)
        teMapName->setStyleSheet("background-color: transparent;");
    else
        teMapName->setStyleSheet("background-color: transparent; color: #b50000;");
}
