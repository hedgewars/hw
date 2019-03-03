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

#include <QDialog>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLineEdit>
#include <QLabel>
#include <QDebug>
#include <QCheckBox>

#include "roomnameprompt.h"

RoomNamePrompt::RoomNamePrompt(QWidget* parent, const QString & roomName) : QDialog(parent)
{
    setModal(true);
    setWindowFlags(Qt::Sheet);
    setWindowModality(Qt::WindowModal);
    setWindowTitle(tr("Create room"));
    setMinimumSize(360, 130);
    resize(360, 180);
    setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Fixed);

    // Layout
    QVBoxLayout * dialogLayout = new QVBoxLayout(this);

    // Label
    label = new QLabel(tr("Enter a name for your room."), this);
    label->setWordWrap(true);
    dialogLayout->addWidget(label);

    // Input box
    leRoomName = new QLineEdit(this);
    leRoomName->setText(roomName);
    //leRoomName->setMaxLength(59); // It didn't like 60 :(
    leRoomName->setMaxLength(40);
    leRoomName->setStyleSheet("QLineEdit { padding: 3px; }");
    leRoomName->selectAll();
    dialogLayout->addWidget(leRoomName);

    cbSetPassword = new QCheckBox(this);
    cbSetPassword->setText(tr("set password"));
    dialogLayout->addWidget(cbSetPassword);

    lePassword = new QLineEdit(this);
    lePassword->setMaxLength(30);
    lePassword->setStyleSheet("QLineEdit { padding: 3px; }");
    lePassword->setEnabled(false);
    dialogLayout->addWidget(lePassword);

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

    connect(cbSetPassword, SIGNAL(toggled(bool)), this, SLOT(checkBoxToggled()));
}

QString RoomNamePrompt::getRoomName()
{
    return leRoomName->text();
}

QString RoomNamePrompt::getPassword()
{
    return lePassword->text();
}

void RoomNamePrompt::checkBoxToggled()
{
    lePassword->setEnabled(cbSetPassword->isChecked());
}
