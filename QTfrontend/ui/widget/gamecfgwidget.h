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

#ifndef GAMECONFIGWIDGET_H
#define GAMECONFIGWIDGET_H

#include <QWidget>
#include <QStringList>
#include <QGroupBox>
#include <QSpinBox>
#include <QRegExp>

#include "mapContainer.h"

class QCheckBox;
class QVBoxLayout;
class QLabel;
class QTableView;
class QTabWidget;

class GameCFGWidget : public QGroupBox
{
        Q_OBJECT

        Q_PROPERTY(bool master READ isMaster WRITE setMaster)

    public:
        GameCFGWidget(QWidget* parent, bool randomWithoutDLC = false);
        quint32 getGameFlags() const;
        quint32 getInitHealth() const;
        QByteArray getFullConfig() const;
        QComboBox * Scripts;
        QComboBox * GameSchemes;
        QComboBox * WeaponsName;
        HWMapContainer* pMapContainer;
        QVariant schemeData(int column) const;
        bool isMaster();

    public slots:
        void setParam(const QString & param, const QStringList & value);
        void fullNetConfig();
        void resendSchemeData();
        void setMaster(bool master);
        void setTabbed(bool tabbed);

    signals:
        void paramChanged(const QString & param, const QStringList & value);
        void goToSchemes(int);
        void goToWeapons(int);
        void goToDrawMap();

    private slots:
        void ammoChanged(int index);
        void mapChanged(const QString &);
        void templateFilterChanged(int);
        void seedChanged(const QString &);
        void themeChanged(const QString &);
        void schemeChanged(int);
        void scriptChanged(int);
        void jumpToSchemes();
        void jumpToWeapons();
        void mapgenChanged(MapGenerator m);
        void maze_sizeChanged(int s);
        void slMapFeatureSizeChanged(int s);
        void onDrawnMapChanged(const QByteArray & data);
        void updateModelViews();

    private:
        QVBoxLayout mainLayout;
        QCheckBox * bindEntries;
        QString curNetAmmoName;
        QString curNetAmmo;
        QRegExp seedRegexp;
        QString m_curScript;
        bool m_master;
        QList<QWidget *> m_childWidgets;
        QGridLayout * GBoxOptionsLayout;
        QWidget * OptionsInnerContainer;
        QWidget * StackContainer;

        QWidget * mapContainerFree;
        QWidget * mapContainerTabbed;
        QWidget * optionsContainerFree;
        QWidget * optionsContainerTabbed;
        bool tabbed;
        QTabWidget * tabs;

        void setNetAmmo(const QString& name, const QString& ammo);

};

#endif // GAMECONFIGWIDGET_H
