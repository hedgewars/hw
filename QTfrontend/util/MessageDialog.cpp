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

#include "MessageDialog.h"
#include "HWApplication.h"



int MessageDialog::ShowFatalMessage(const QString & msg, QWidget * parent)
{
    return ShowMessage(QMessageBox::tr("Hedgewars - Error"),
                       msg,
                       QMessageBox::Critical,
                       parent);
}

int MessageDialog::ShowErrorMessage(const QString & msg, QWidget * parent)
{
    return ShowMessage(QMessageBox::tr("Hedgewars - Warning"),
                       msg,
                       QMessageBox::Warning,
                       parent);
}

int MessageDialog::ShowInfoMessage(const QString & msg, QWidget * parent)
{
    return ShowMessage(QMessageBox::tr("Hedgewars - Information"),
                       msg,
                       QMessageBox::Information,
                       parent);
}

int MessageDialog::ShowMessage(const QString & title, const QString & msg, QMessageBox::Icon icon, QWidget * parent)
{
    // if no parent try to use active window
    parent = parent ? parent : HWApplication::activeWindow();

    // didn't work? make child of hwform (e.g. for style and because modal)
    if (!parent)
    {
        try
        {
            HWApplication * app = dynamic_cast<HWApplication*>(HWApplication::instance());
            if (app->form)
                parent = app->form;
        }
        catch (...) { /* nothing */ }
    }

    QMessageBox msgMsg(parent);
    msgMsg.setWindowTitle(title != NULL ? title : "Hedgewars");
    msgMsg.setText(msg);
    msgMsg.setIcon(icon);
    msgMsg.setTextFormat(Qt::PlainText);
    msgMsg.setWindowModality(Qt::WindowModal);

    return msgMsg.exec();
}
