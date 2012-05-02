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

HWPasswordDialog::HWPasswordDialog(QWidget* parent, const QString & label) : QDialog(parent)
{
    setWindowTitle(tr("Password"));

    QGridLayout * layout = new QGridLayout(this);

    QLabel * lbLabel = new QLabel(this);
    lbLabel->setText(label);
    layout->addWidget(lbLabel, 0, 0);

    lePassword = new QLineEdit(this);
    lePassword->setEchoMode(QLineEdit::Password);
    layout->addWidget(lePassword, 1, 0);

    cbSave = new QCheckBox(this);
    cbSave->setText(QCheckBox::tr("Save password"));
    layout->addWidget(cbSave, 2, 0);

    QDialogButtonBox* dbbButtons = new QDialogButtonBox(this);
    QPushButton * pbOK = dbbButtons->addButton(QDialogButtonBox::Ok);
    QPushButton * pbCancel = dbbButtons->addButton(QDialogButtonBox::Cancel);
    layout->addWidget(dbbButtons, 3, 0);

    connect(pbOK, SIGNAL(clicked()), this, SLOT(accept()));
    connect(pbCancel, SIGNAL(clicked()), this, SLOT(reject()));
}
