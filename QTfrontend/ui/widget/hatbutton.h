/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef HATBUTTON_H
#define HATBUTTON_H

#include <QPushButton>
#include <QString>
#include <QModelIndex>

class HatModel;

class HatButton : public QPushButton
{
        Q_OBJECT
        Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex)
        Q_PROPERTY(QString currentHat READ currentHat WRITE setCurrentHat)

    public:
        HatButton(QWidget* parent);
        int currentIndex();
        QString currentHat() const;

    private:
        QModelIndex m_hat;
        HatModel * m_hatModel;

    signals:
        void currentIndexChanged(int);
        void currentHatChanged(const QString &);

    public slots:
        void setCurrentIndex(int index);
        void setCurrentHat(const QString & name);

    private slots:
        void showPrompt();
};

#endif // HATBUTTON_H
