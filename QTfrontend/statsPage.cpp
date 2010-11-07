/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QLabel>
#include <QGridLayout>
#include <QGraphicsScene>
#include <QGroupBox>
#include <QSizePolicy>
#include "statsPage.h"
#include "team.h"

FitGraphicsView::FitGraphicsView(QWidget* parent) : QGraphicsView(parent)
{

}

void FitGraphicsView::resizeEvent(QResizeEvent * event)
{
    fitInView(sceneRect());
}

PageGameStats::PageGameStats(QWidget* parent) : AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setSpacing(20);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);

    BtnBack = addButton(":/res/Exit.png", pageLayout, 3, 0, true);
    BtnBack->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);

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
    gbl->addWidget(l);
    gbl->addWidget(labelGameStats);
    gb->setLayout(gbl);
    pageLayout->addWidget(gb, 1, 1);
    
    // graph
    graphic = new FitGraphicsView(gb);
    l = new QLabel(this);
    l->setTextFormat(Qt::RichText);
    l->setText("<br><h1><img src=\":/res/StatsH.png\"> " + PageGameStats::tr("Health graph") + "</h1>");
    l->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    gbl->addWidget(l);
    gbl->addWidget(graphic);
    graphic->scale(1.0, -1.0);
    graphic->setBackgroundBrush(QBrush(Qt::black));
    
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
    playerPosition = 0;
    lastColor = 0;
}

void PageGameStats::renderStats()
{
    QGraphicsScene * scene = new QGraphicsScene();

    QMap<quint32, QVector<quint32> >::const_iterator i = healthPoints.constBegin();
    while (i != healthPoints.constEnd())
    {
        quint32 c = i.key();
        QColor clanColor = QColor(qRgb((c >> 16) & 255, (c >> 8) & 255, c & 255));
        QVector<quint32> hps = i.value();

        QPainterPath path;
        if (hps.size())
            path.moveTo(0, hps[0]);

        for(int t = 1; t < hps.size(); ++t)
            path.lineTo(t, hps[t]);

        scene->addPath(path, QPen(c));
        ++i;
    }

    graphic->setScene(scene);
    graphic->fitInView(graphic->sceneRect());
}

void PageGameStats::GameStats(char type, const QString & info)
{
    switch(type) {
        case 'r' : {
            labelGameWin->setText(QString("<h1 align=\"center\">%1</h1>").arg(info));
            break;
        }
        case 'D' : {
            int i = info.indexOf(' ');
            QString message = "<p><img src=\":/res/StatsBestShot.png\"> " + PageGameStats::tr("The best shot award was won by <b>%1</b> with <b>%2</b> pts.").arg(info.mid(i + 1), info.left(i)) + "</p>";
            AddStatText(message);
            break;
        }
        case 'k' : {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsBestKiller.png\"> " + PageGameStats::tr("The best killer is <b>%1</b> with <b>%2</b> kills in a turn.", "", num).arg(info.mid(i + 1), info.left(i)) + "</p>";
            AddStatText(message);
            break;
        }
        case 'K' : {
            int num = info.toInt();
            QString message = "<p><img src=\":/res/StatsHedgehogsKilled.png\"> " +  PageGameStats::tr("A total of <b>%1</b> hedgehog(s) were killed during this round.", "", num).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'H' : {
            int i = info.indexOf(' ');
            quint32 clan = info.left(i).toInt();
            quint32 hp = info.mid(i + 1).toUInt();
            healthPoints[clan].append(hp);
            break;
        }
        case 'T': { // local team stats
            //AddStatText("<p>local team: " + info + "</p>");
            QStringList infol = info.split(":");
            HWTeam team(infol[0]);
            if(team.FileExists()) // do some better test to avoid influence from scripted/predefined teams?
            {
                team.LoadFromFile();
                team.Rounds++;
                if(infol[1].toInt() > 0) // might require some better test for winning condition (or changed flag) ... WIP!
                    team.Wins++; // should draws count as wins?
                //team.SaveToFile(); // don't save yet
            }
            break;
            }

        case 'P' : {
            int i = info.indexOf(' ');
            playerPosition++;
            QString color = info.left(i);
            quint32 c = color.toInt();
            QColor clanColor = QColor(qRgb((c >> 16) & 255, (c >> 8) & 255, c & 255));

            QString playerinfo = info.mid(i + 1);

            i = playerinfo.indexOf(' ');

            int kills = playerinfo.left(i).toInt();
            QString playername = playerinfo.mid(i + 1);
            QString image;

            if (lastColor == c && playerPosition <= 2) playerPosition = 1;
            lastColor = c;

            switch (playerPosition)
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
            QString killstring = PageGameStats::tr("(%1 kill)", "", kills).arg(kills);

            message = QString("<p><h2>%1 %2. <font color=\"%4\">%3</font> ").arg(image, QString::number(playerPosition), playername, clanColor.name()) + killstring + "</h2></p>";

            labelGameRank->setText(labelGameRank->text() + message);
                break;
        }
        case 's' : {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsMostSelfDamage.png\"> " + PageGameStats::tr("<b>%1</b> thought it's good to shoot his own hedgehogs with <b>%2</b> pts.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'S' : {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsSelfKilled.png\"> " + PageGameStats::tr("<b>%1</b> killed <b>%2</b> of his own hedgehogs.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }
        case 'B' : {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = "<p><img src=\":/res/StatsSkipped.png\"> " + PageGameStats::tr("<b>%1</b> was scared and skipped turn <b>%2</b> times.", "", num).arg(info.mid(i + 1)).arg(num) + "</p>";
            AddStatText(message);
            break;
        }

    }
}
