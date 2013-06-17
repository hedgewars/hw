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

#include <QDialog>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLineEdit>
#include <QLabel>
#include <QDebug>

#include "roomnameprompt.h"

RoomNamePrompt::RoomNamePrompt(QWidget* parent, const QString & roomName) : QDialog(parent)
{
    setModal(true);
    setWindowFlags(Qt::Sheet);
    setWindowModality(Qt::WindowModal);
    setMinimumSize(360, 130);
    resize(360, 130);
    setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Fixed);

    // Layout
    QVBoxLayout * dialogLayout = new QVBoxLayout(this);

    // Label
    label = new QLabel(tr("Enter a name for your room."));
    label->setWordWrap(true);
    dialogLayout->addWidget(label, 0);

    // Input box
    editBox = new QLineEdit();
    editBox->setText(roomName);
    editBox->setMaxLength(59); // It didn't like 60 :(
    editBox->setStyleSheet("QLineEdit { padding: 3px; }");
    editBox->selectAll();
    dialogLayout->addWidget(editBox, 1);

    dialogLayout->addStretch(1);

    // Buttons
    QHBoxLayout * buttonLayout = new QHBoxLayout();
    buttonLayout->addStretch(1);
    dialogLayout->addLayout(buttonLayout);

    QPushButton * btnCancel = new QPushButton(tr("Cancel"));
    QPushButton * btnOkay = new QPushButton(tr("Create room"));
    connect(btnCancel, SIGNAL(clicked()), this, SLOT(reject()));
    connect(btnOkay, SIGNAL(clicked()), this, SLOT(accept()));
#ifdef Q_OS_MAC
        buttonLayout->addWidget(btnCancel);
        buttonLayout->addWidget(btnOkay);
#else
        buttonLayout->addWidget(btnOkay);
        buttonLayout->addWidget(btnCancel);
#endif
    btnOkay->setDefault(true);

    setStyleSheet("QPushButton { padding: 5px; }");

    connect(btnOkay, SIGNAL(clicked()), this, SLOT(setRoomName()));
}

void RoomNamePrompt::setRoomName()
{
    emit roomNameChosen(editBox->text());
}
