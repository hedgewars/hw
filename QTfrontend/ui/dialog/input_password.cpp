/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QLineEdit>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QGridLayout>
#include <QCheckBox>
#include <QLabel>

#include "input_password.h"

HWPasswordDialog::HWPasswordDialog(QWidget* parent) : QDialog(parent)
{
    setWindowTitle(tr("Login"));
    
    QString titleLabelText = "To connect to the server, please log in.\n\nIf you don't have an account on www.hedgewars.org,\njust enter your nickname.";
    QString nickLabelText = "Nickname:";
    QString passLabelText = "Password:";

    QGridLayout * layout = new QGridLayout(this);

    QLabel * titleLabel = new QLabel(this);
    titleLabel->setText(titleLabelText);
    layout->addWidget(titleLabel, 0, 0);
    
    QLabel * nickLabel = new QLabel(this);
    nickLabel->setText(nickLabelText);
    layout->addWidget(nickLabel, 1, 0);
    
    leNickname = new QLineEdit(this);
    leNickname->setEchoMode(QLineEdit::Normal);
    layout->addWidget(leNickname, 2, 0);
    
    QLabel * passLabel = new QLabel(this);
    passLabel->setText(passLabelText);
    layout->addWidget(passLabel, 3, 0);

    lePassword = new QLineEdit(this);
    lePassword->setEchoMode(QLineEdit::Password);
    layout->addWidget(lePassword, 4, 0);

    cbSave = new QCheckBox(this);
    cbSave->setText(QCheckBox::tr("Save password"));
    layout->addWidget(cbSave, 5, 0);

    QDialogButtonBox* dbbButtons = new QDialogButtonBox(this);
    pbNewAccount = dbbButtons->addButton(QString("New Account"), QDialogButtonBox::ActionRole);
    QPushButton * pbOK = dbbButtons->addButton(QDialogButtonBox::Ok);
    QPushButton * pbCancel = dbbButtons->addButton(QDialogButtonBox::Cancel);
    layout->addWidget(dbbButtons, 6, 0);

    connect(pbOK, SIGNAL(clicked()), this, SLOT(accept()));
    connect(pbCancel, SIGNAL(clicked()), this, SLOT(reject()));

    this->setWindowModality(Qt::WindowModal);
}
