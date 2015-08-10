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

#include <QDebug>

#include "hatprompt.h"
#include "HatModel.h"
#include "hatbutton.h"

HatButton::HatButton(QWidget* parent) : QPushButton(parent)
{
    setIconSize(QSize(32, 37));
    setFixedSize(44, 44);

    m_hatModel = 0;
    connect(this, SIGNAL(clicked()), this, SLOT(showPrompt()));
}

void HatButton::setModel(HatModel *model)
{
    m_hatModel = model;

    setCurrentIndex(0);
}

void HatButton::setCurrentIndex(int index)
{
    m_hat = m_hatModel->index(index, 0);
    setWhatsThis(QString(tr("Change hat (%1)")).arg(m_hat.data(Qt::DisplayRole).toString()));
    setToolTip(m_hat.data(Qt::DisplayRole).toString());
    setIcon(m_hat.data(Qt::DecorationRole).value<QIcon>());
}

int HatButton::currentIndex()
{
    return m_hat.row();
}

void HatButton::setCurrentHat(const QString & name)
{
    QList<QStandardItem *> hats = m_hatModel->findItems(name);

    if (hats.count() > 0)
        setCurrentIndex(hats[0]->row());
}

QString HatButton::currentHat() const
{
    return m_hat.data(Qt::DisplayRole).toString();
}

void HatButton::showPrompt()
{
    HatPrompt prompt(currentIndex(), this);
    int hatID = prompt.exec() - 1; // Since 0 means canceled, so all indexes are +1'd
    if (hatID < 0) return;

    setCurrentIndex(hatID);
    emit currentIndexChanged(hatID);
    emit currentHatChanged(currentHat());
}
