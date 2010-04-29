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
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    BtnBack = addButton(":/res/Exit.png", pageLayout, 2, 0, true);

    labelGameStats = new QLabel(this);
    labelGameStats->setTextFormat(Qt::RichText);
    pageLayout->addWidget(labelGameStats, 0, 0, 1, 3);

    graphic = new FitGraphicsView(this);
    graphic->scale(1.0, -1.0);
    graphic->setBackgroundBrush(QBrush(Qt::black));
    pageLayout->addWidget(graphic, 1, 0, 1, 3);
}

void PageGameStats::AddStatText(const QString & msg)
{
    labelGameStats->setText(labelGameStats->text() + msg);
}

void PageGameStats::clear()
{
    labelGameStats->setText("");
    healthPoints.clear();
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
            AddStatText(QString("<h1 align=\"center\">%1</h1>").arg(info));
            break;
        }
        case 'D' : {
            int i = info.indexOf(' ');
            QString message = PageGameStats::tr("<p>The best shot award was won by <b>%1</b> with <b>%2</b> pts.</p>")
                    .arg(info.mid(i + 1), info.left(i));
            AddStatText(message);
            break;
        }
        case 'k' : {
            int i = info.indexOf(' ');
            int num = info.left(i).toInt();
            QString message = PageGameStats::tr("<p>The best killer is <b>%1</b> with <b>%2</b> kills in a turn.</p>", "", num)
                    .arg(info.mid(i + 1), info.left(i));
            AddStatText(message);
            break;
        }
        case 'K' : {
            int num = info.toInt();
            QString message = PageGameStats::tr("<p>A total of <b>%1</b> hedgehog(s) were killed during this round.</p>", "", num).arg(num);
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
        }
    }
}
