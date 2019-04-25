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

#include "pageplayrecord.h"

#include <QFont>
#include <QGridLayout>
#include <QPushButton>
#include <QListWidget>
#include <QListWidgetItem>
#include <QFileInfo>
#include <QMessageBox>
#include <QInputDialog>

#include "hwconsts.h"

#include "DataManager.h"

QLayout * PagePlayDemo::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 2);
    pageLayout->setColumnStretch(2, 1);
    pageLayout->setRowStretch(2, 100);

    BtnRenameRecord = new QPushButton(this);
    BtnRenameRecord->setText(QPushButton::tr("Rename"));
    pageLayout->addWidget(BtnRenameRecord, 0, 2);

    BtnRemoveRecord = new QPushButton(this);
    BtnRemoveRecord->setText(QPushButton::tr("Delete"));
    pageLayout->addWidget(BtnRemoveRecord, 1, 2);

    DemosList = new QListWidget(this);
    DemosList->setGeometry(QRect(170, 10, 311, 311));
    pageLayout->addWidget(DemosList, 0, 1, 3, 1);

    return pageLayout;
}

QLayout * PagePlayDemo::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    BtnPlayDemo = addButton(tr("Play demo"), bottomLayout, 0, false, Qt::AlignBottom);
    const QIcon& lp = QIcon(":/res/Start.png");
    QSize sz = lp.actualSize(QSize(65535, 65535));
    BtnPlayDemo->setStyleSheet("padding: 5px 10px");
    BtnPlayDemo->setIcon(lp);
    BtnPlayDemo->setFixedHeight(50);
    BtnPlayDemo->setIconSize(sz);
    BtnPlayDemo->setFlat(true);
    BtnPlayDemo->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Fixed);

    return bottomLayout;
}

void PagePlayDemo::connectSignals()
{
    connect(BtnRenameRecord, SIGNAL(clicked()), this, SLOT(renameRecord()));
    connect(BtnRemoveRecord, SIGNAL(clicked()), this, SLOT(removeRecord()));
    connect(&DataManager::instance(), SIGNAL(updated()), this, SLOT(refresh()));
}

PagePlayDemo::PagePlayDemo(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PagePlayDemo::FillFromDir(RecordType rectype)
{
    QDir dir;
    QString extension;

    recType = rectype;

    dir.cd(cfgdir->absolutePath());
    if (rectype == RT_Demo)
    {
        dir.cd("Demos");
        extension = "hwd";
        BtnPlayDemo->setText(QPushButton::tr("Play demo"));
        BtnPlayDemo->setWhatsThis(tr("Play the selected demo"));
    }
    else
    {
        dir.cd("Saves");
        extension = "hws";
        BtnPlayDemo->setText(QPushButton::tr("Load"));
        BtnPlayDemo->setWhatsThis(tr("Load the selected game"));
    }
    dir.setFilter(QDir::Files);

    QStringList sl = dir.entryList(QStringList(QString("*.%2.%1").arg(extension, *cProtoVer)));
    sl.replaceInStrings(QRegExp(QString("^(.*)\\.%2\\.%1$").arg(extension, *cProtoVer)), "\\1");

    DemosList->clear();
    DemosList->addItems(sl);

    for (int i = 0; i < DemosList->count(); ++i)
    {
        DemosList->item(i)->setData(Qt::UserRole, dir.absoluteFilePath(QString("%1.%3.%2").arg(sl[i], extension, *cProtoVer)));
        DemosList->item(i)->setIcon(recType == RT_Demo ? QIcon(":/res/file_demo.png") : QIcon(":/res/file_save.png"));
    }
}


void PagePlayDemo::refresh()
{
    if (this->isVisible())
        FillFromDir(recType);
}


void PagePlayDemo::renameRecord()
{
    QListWidgetItem * curritem = DemosList->currentItem();
    if (!curritem)
    {
        QMessageBox recordMsg(this);
        recordMsg.setIcon(QMessageBox::Warning);
        recordMsg.setWindowTitle(QMessageBox::tr("Error"));
        recordMsg.setText(QMessageBox::tr("Please select a file from the list."));
        recordMsg.setTextFormat(Qt::PlainText);
        recordMsg.setWindowModality(Qt::WindowModal);
        recordMsg.exec();
        return ;
    }
    QFile rfile(curritem->data(Qt::UserRole).toString());

    QFileInfo finfo(rfile);

    bool ok;

    QString newname = QInputDialog::getText(this, tr("Rename dialog"), tr("Enter new file name:"), QLineEdit::Normal, finfo.completeBaseName().replace("." + *cProtoVer, ""), &ok);

    if(ok && newname.size())
    {
        QString newfullname = QString("%1/%2.%3.%4")
                              .arg(finfo.absolutePath())
                              .arg(newname)
                              .arg(*cProtoVer)
                              .arg(finfo.suffix());

        ok = rfile.rename(newfullname);
        if(!ok)
        {
            QMessageBox renameMsg(this);
            renameMsg.setIcon(QMessageBox::Warning);
            renameMsg.setWindowTitle(QMessageBox::tr("Error"));
            renameMsg.setText(QMessageBox::tr("Cannot rename file to %1.").arg(newfullname));
            renameMsg.setTextFormat(Qt::PlainText);
            renameMsg.setWindowModality(Qt::WindowModal);
            renameMsg.exec();
        }
        else
            FillFromDir(recType);
    }
}

void PagePlayDemo::removeRecord()
{
    QListWidgetItem * curritem = DemosList->currentItem();
    if (!curritem)
    {
        QMessageBox recordMsg(this);
        recordMsg.setIcon(QMessageBox::Warning);
        recordMsg.setWindowTitle(QMessageBox::tr("Error"));
        recordMsg.setText(QMessageBox::tr("Please select a file from the list."));
        recordMsg.setTextFormat(Qt::PlainText);
        recordMsg.setWindowModality(Qt::WindowModal);
        recordMsg.exec();
        return ;
    }
    QFile rfile(curritem->data(Qt::UserRole).toString());

    bool ok;

    ok = rfile.remove();
    if(!ok)
    {
        QMessageBox removeMsg(this);
        removeMsg.setIcon(QMessageBox::Warning);
        removeMsg.setWindowTitle(QMessageBox::tr("Error"));
        removeMsg.setText(QMessageBox::tr("Cannot delete file %1.").arg(rfile.fileName()));
        removeMsg.setTextFormat(Qt::PlainText);
        removeMsg.setWindowModality(Qt::WindowModal);
        removeMsg.exec();
    }
    else
    {
        int i = DemosList->row(curritem);
        delete curritem;
        DemosList->setCurrentRow(i < DemosList->count() ? i : DemosList->count() - 1);
    }
}

bool PagePlayDemo::isSave()
{
    return recType == RT_Save;
}
