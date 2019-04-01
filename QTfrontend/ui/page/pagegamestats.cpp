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

#include <QLabel>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QGraphicsScene>
#include <QGroupBox>
#include <QSizePolicy>

#include "pagegamestats.h"
#include "team.h"

FitGraphicsView::FitGraphicsView(QWidget* parent) : QGraphicsView(parent)
{

}

void FitGraphicsView::resizeEvent(QResizeEvent * event)
{
    Q_UNUSED(event);

    fitInView(sceneRect());
}

QLayout * PageGameStats::bodyLayoutDefinition()
{
    kindOfPoints = QString("");
    defaultGraphTitle = true;
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setSpacing(20);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(1, 20);
    //pageLayout->setRowStretch(1, -1); this should work but there is unnecessary empty space betwin lines if used
    pageLayout->setContentsMargins(7, 7, 7, 0);

    QGroupBox * gb = new QGroupBox(this);
    QVBoxLayout * gbl = new QVBoxLayout;

    // details
    labelGameStats = new QLabel(this);
    QLabel * l = new QLabel(this);
    l->setTextFormat(Qt::RichText);
    l->setText("<h1><img src=\":/res/StatsD.png\"> " + PageGameStats::tr("Details") + "</h1>");
    l->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    labelGameStats->setTextFormat(Qt::RichText);
    labelGameStats->setAlignment(Qt::AlignTop);
    labelGameStats->setWordWrap(true);
    gbl->addWidget(l);
    gbl->addWidget(labelGameStats);
    gb->setLayout(gbl);
    pageLayout->addWidget(gb, 1, 1);

    // graph
    graphic = new FitGraphicsView(gb);
    graphic->setObjectName("gameStatsView");
    labelGraphTitle = new QLabel(this);
    labelGraphTitle->setTextFormat(Qt::RichText);
    labelGraphTitle->setText("<br><h1><img src=\":/res/StatsH.png\"> " + PageGameStats::tr("Health graph") + "</h1>");
    labelGraphTitle->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    gbl->addWidget(labelGraphTitle);
    gbl->addWidget(graphic);
    graphic->scale(1.0, -1.0);
    graphic->setBackgroundBrush(QBrush(Qt::black));
    graphic->setRenderHint(QPainter::Antialiasing, true);

    labelGameWin = new QLabel(this);
    labelGameWin->setTextFormat(Qt::RichText);
    pageLayout->addWidget(labelGameWin, 0, 0, 1, 2);

    // ranking box
    gb = new QGroupBox(this);
    gbl = new QVBoxLayout;
    labelGameRank = new QLabel(gb);
    l = new QLabel(this);
    l->setTextFormat(Qt::RichText);
    l->setText("<h1><img src=\":/res/StatsR.png\"> " + PageGameStats::tr("Ranking") + "</h1>");
    l->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    gbl->addWidget(l);
    gbl->addWidget(labelGameRank);
    gb->setLayout(gbl);

    labelGameRank->setTextFormat(Qt::RichText);
    labelGameRank->setAlignment(Qt::AlignTop);
    pageLayout->addWidget(gb, 1, 0);

    return pageLayout;
}

//TODO button placement, image etc
QLayout * PageGameStats::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    mainNote = new QLabel(this);
    mainNote->setAlignment(Qt::AlignHCenter | Qt::AlignVCenter);
    mainNote->setWordWrap(true);

    bottomLayout->addWidget(mainNote, 0);
    bottomLayout->setStretch(0,1);

    btnRestart = addButton(":/res/Start.png", bottomLayout, 1, true);
    btnRestart->setWhatsThis(tr("Play again"));
    btnRestart->setFixedWidth(58);
    btnRestart->setFixedHeight(81);
    btnRestart->setStyleSheet("QPushButton{margin-top:24px}");
    btnSave = addButton(":/res/Save.png", bottomLayout, 2, true);
    btnSave->setWhatsThis(tr("Save"));
    btnSave->setStyleSheet("QPushButton{margin: 24px 0 0 0;}");

    return bottomLayout;
}

void PageGameStats::connectSignals()
{
    connect(this, SIGNAL(pageEnter()), this, SLOT(renderStats()));
    connect(btnSave, SIGNAL(clicked()), this, SIGNAL(saveDemoRequested()));
    connect(btnRestart, SIGNAL(clicked()), this, SIGNAL(restartGameRequested()));
}

PageGameStats::PageGameStats(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageGameStats::AddStatText(const QString & msg)
{
    labelGameStats->setText(labelGameStats->text() + msg);
}

void PageGameStats::clear()
{
    labelGameStats->setText("");
    healthPoints.clear();
    labelGameRank->setText("");
    labelGameWin->setText("");
    playerPosition = 0;
    scriptPlayerPosition = 0;
    lastColor = 0;
}

void PageGameStats::restartBtnVisible(bool visible)
{
    btnRestart->setVisible(visible);
}

void PageGameStats::renderStats()
{
    if(defaultGraphTitle) {
        labelGraphTitle->setText("<br><h1><img src=\":/res/StatsH.png\"> " + PageGameStats::tr("Health graph") + "</h1>");
    } else {
        defaultGraphTitle = true;
    }
    // if not health data sent
    if(healthPoints.size() == 0) {
        labelGraphTitle->hide();
        graphic->hide();
    } else {
        graphic->setScene(Q_NULLPTR);
        m_scene.reset(new QGraphicsScene(this));

        // min and max value across the entire chart
        qint32 minValue = 0;
        qint32 maxValue = 0;
        bool minMaxValuesInitialized = false;

        // max data points per clan
        int maxDataPoints = 0;
        for(QMap<qint32, QVector<qint32> >::const_iterator i = healthPoints.constBegin(); i != healthPoints.constEnd(); ++i)
        {
            maxDataPoints = qMax(maxDataPoints, i.value().size());
        }

        /* There must be at least 2 data points for any clan,
           otherwise there's not much to look at. ;-) */
        if(maxDataPoints < 2) {
            labelGraphTitle->hide();
            graphic->hide();
            return;
        }

        QMap<qint32, QVector<qint32> >::const_iterator i = healthPoints.constBegin();
        while (i != healthPoints.constEnd())
        {
            qint32 c = i.key();
            const QVector<qint32>& hps = i.value();

            QPainterPath path;

            if (hps.size()) {
                path.moveTo(0, hps[0]);
                if(minMaxValuesInitialized) {
                    minValue = qMin(minValue, hps[0]);
                    maxValue = qMax(maxValue, hps[0]);
                } else {
                    minValue = hps[0];
                    maxValue = hps[0];
                    minMaxValuesInitialized = true;
                }
            }

            for(int t = 0; t < hps.size(); ++t) {
                path.lineTo(t, hps[t]);
                maxValue = qMax(maxValue, hps[t]);
                minValue = qMin(minValue, hps[t]);
            }

            // Draw clan health/score graph lines
            QColor col = QColor(c);

            // Special pen for very dark clan colors
            if (!(col.red() >= cInvertTextColorAt || col.green() >= cInvertTextColorAt || col.blue() >= cInvertTextColorAt))
            {
                QPen pen_marker(QColor(255, 255, 255));
                pen_marker.setWidth(3);
                pen_marker.setStyle(Qt::DotLine);
                pen_marker.setCosmetic(true);
                m_scene->addPath(path, pen_marker);
            }

            // Regular pen
            QPen pen(col);
            pen.setWidth(2);
            pen.setCosmetic(true);
            m_scene->addPath(path, pen);

            ++i;
        }

        graphic->setScene(m_scene.data());

        // Calculate the bounding box of the final chart
        qint32 sceneMinY = minValue;
        qint32 sceneMaxY = maxValue;
        // If all values are 0 or greater, make sure to include 0 at the bottom.
        if(sceneMinY >= 0 && sceneMaxY >= 0)
            sceneMinY = 0;
        // If all values are equal, we must increase sceneMaxY, otherwise the scene rect
        // would have a height of 0 and will screw up
        if(sceneMinY == sceneMaxY)
            sceneMaxY++;
        graphic->setSceneRect(0, sceneMinY, maxDataPoints-1, sceneMaxY - sceneMinY);

        graphic->fitInView(graphic->sceneRect());

        graphic->show();
        labelGraphTitle->show();
    }
}

void PageGameStats::GameStats(char type, const QString & info)
{
    switch(type)
    {
        case 'r' :
        {
            labelGameWin->setText(QString("<h1 align=\"center\">%1</h1>").arg(info));
            break;
        }
        case 'D' :
        {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsBestShot.png\"> " + PageGameStats::tr("The best shot award was won by <b>%1</b> with <b>%2</b> pts.", "", num).arg(info.mid(i + 1), info.left(i)) + "</p>";
            AddStatText(message);
            break;
        }
        case 'k' :
        {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsBestKiller.png\"> " + PageGameStats::tr("The best killer is <b>%1</b> with <b>%2</b> kills in a turn.", "", num).arg(info.mid(i + 1), info.left(i)) + "</p>";
            AddStatText(message);
            break;
        }
        case 'K' :
        {
            int num = info.toInt();
            QString message = "<p><img src=\":/res/StatsHedgehogsKilled.png\"> " +  PageGameStats::tr("A total of <b>%1</b> hedgehog(s) were killed during this round.", "", num).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'H' :
        {
            int i = info.indexOf(' ');
            quint32 clan = info.left(i).toInt();
            qint32 hp = info.mid(i + 1).toInt();
            healthPoints[clan].append(hp);
            break;
        }
        case 'g' :
        {
            // TODO: change default picture or add change pic capability
            defaultGraphTitle = false;
            labelGraphTitle->setText("<br><h1><img src=\":/res/StatsR.png\"> " + info + "</h1>");
            break;
        }
        case 'T':   // local team stats
        {
            // unused
            break;
        }
        case 'p' :
        {
            kindOfPoints = info;
            break;
        }
        case 'P' :
        {
            int i = info.indexOf(' ');
            playerPosition++;
            QString color = info.left(i);
            quint32 c = color.toInt();
            QColor clanColor = QColor(qRgb((c >> 16) & 255, (c >> 8) & 255, c & 255));

            QString playerinfo = info.mid(i + 1);

            i = playerinfo.indexOf(' ');

            QString killsString = playerinfo.left(i);
            int kills = killsString.toInt();
            QString playername = playerinfo.mid(i + 1);
            QString image;

            if (lastColor == c) playerPosition--;
            lastColor = c;

            unsigned int realPlayerPosition;
            if(scriptPlayerPosition == 0)
                realPlayerPosition = playerPosition;
            else
                realPlayerPosition = scriptPlayerPosition;

            switch (realPlayerPosition)
            {
                case 1:
                    image = "<img src=\":/res/StatsMedal1.png\">";
                    break;
                case 2:
                    image = "<img src=\":/res/StatsMedal2.png\">";
                    break;
                case 3:
                    image = "<img src=\":/res/StatsMedal3.png\">";
                    break;
                default:
                    image = "<img src=\":/res/StatsMedal4.png\">";
                    break;
            }

            QString message;
            QString killstring;
            if(kindOfPoints.isEmpty()) {
                //: Number of kills in stats screen, written after the team name
                killstring = PageGameStats::tr("(%1 kill)", "", kills).arg(kills);
            } else if (kindOfPoints == "!POINTS") {
                //: Number of points in stats screen, written after the team name
                killstring = PageGameStats::tr("(%1 point(s))", "", kills).arg(kills);
            } else if (kindOfPoints == "!TIME") {
                //: Time in seconds
                killstring = PageGameStats::tr("(%L1 second(s))", "", kills).arg((double) kills/1000, 0, 'f', 3);
            } else if (kindOfPoints.startsWith("!TIME") && kindOfPoints.length() == 6) {
                int len = kindOfPoints.at(6).digitValue();
                if(len != -1)
                    killstring = PageGameStats::tr("(%L1 second(s))", "", kills).arg((double) kills/1000, 0, 'f', len);
                else
                    qWarning("SendStat: siPointType received with !TIME and invalid number length!");
            } else if (kindOfPoints == "!CRATES") {
                killstring = PageGameStats::tr("(%1 crate(s))", "", kills).arg(kills);
            } else if (kindOfPoints == "!EMPTY") {
                killstring = QString("");
            } else {
                //: For custom number of points in the stats screen, written after the team name. %1 is the number, %2 is the word. Example: “4 points”
                killstring = PageGameStats::tr("(%1 %2)", "", kills).arg(kills).arg(kindOfPoints);
            }
            kindOfPoints = QString("");

            message = QString("<p><h2>%1 %2. <font color=\"%4\">%3</font> ").arg(image, QString::number(realPlayerPosition), playername, clanColor.name()) + killstring + "</h2></p>";

            labelGameRank->setText(labelGameRank->text() + message);
            scriptPlayerPosition = 0;
            break;
        }
        case 's' :
        {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsMostSelfDamage.png\"> " + PageGameStats::tr("<b>%1</b> thought it's good to shoot their own hedgehogs for <b>%2</b> pts.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'S' :
        {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsSelfKilled.png\"> " + PageGameStats::tr("<b>%1</b> killed <b>%2</b> of their own hedgehogs.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'B' :
        {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsSkipped.png\"> " + PageGameStats::tr("<b>%1</b> was scared and skipped turn <b>%2</b> times.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'c' :
        {
            QString message = "<p><img src=\":/res/StatsCustomAchievement.png\"> "+info+" </p>";
            AddStatText(message);
            break;
        }
        case 'R' :
        {
            scriptPlayerPosition = info.toInt();
            break;
        }
        case 'h' :
        {
            QString message = "<p><img src=\":/res/StatsEverAfter.png\"> " + PageGameStats::tr("With everyone having the same clan color, there was no reason to fight. And so the hedgehogs happily lived in peace ever after.") + "</p>";
            AddStatText(message);
            break;
        }
    }
}
