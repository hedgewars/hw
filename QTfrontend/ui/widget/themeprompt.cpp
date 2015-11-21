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
#include <QGridLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QPushButton>
#include <QToolButton>
#include <QWidgetItem>
#include <QModelIndex>
#include <QListView>
#include <QLineEdit>
#include <QLabel>
#include <QSortFilterProxyModel>
#include <QDebug>

#include "DataManager.h"
#include "lineeditcursor.h"
#include "ThemeModel.h"
#include "themeprompt.h"


void ThemeListView::moveUp()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveUp, Qt::NoModifier));
}

void ThemeListView::moveDown()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveDown, Qt::NoModifier));
}

void ThemeListView::moveLeft()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveLeft, Qt::NoModifier));
}

void ThemeListView::moveRight()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveRight, Qt::NoModifier));
}

ThemePrompt::ThemePrompt(int currentIndex, QWidget* parent) : QDialog(parent)
{
    setModal(true);
    setWindowFlags(Qt::Sheet);
    setWindowModality(Qt::WindowModal);
    setWindowTitle(tr("Choose a theme"));
    setMinimumSize(550, 430);
    resize(550, 430);
    setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);

    setStyleSheet("QPushButton { padding: 5px; margin-top: 10px; }");

    // Theme model, and a model for setting a filter
    ThemeModel * themeModel = DataManager::instance().themeModel();
    filterModel = new QSortFilterProxyModel();
    filterModel->setSourceModel(themeModel);
    filterModel->setFilterCaseSensitivity(Qt::CaseInsensitive);

    // Grid
    QGridLayout * dialogLayout = new QGridLayout(this);
    dialogLayout->setSpacing(0);
    dialogLayout->setColumnStretch(1, 1);

    QHBoxLayout * topLayout = new QHBoxLayout();

    // Help/prompt message at top
    QLabel * lblDesc = new QLabel(tr("Search for a theme:"));
    lblDesc->setObjectName("lblDesc");
    lblDesc->setStyleSheet("#lblDesc { color: #130F2A; background: #F6CB1C; border: solid 4px #F6CB1C; border-top-left-radius: 10px; padding: 4px 10px;}");
    lblDesc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    lblDesc->setFixedHeight(24);
    lblDesc->setMinimumWidth(0);

    // Filter text box
    QWidget * filterContainer = new QWidget();
    filterContainer->setFixedHeight(24);
    filterContainer->setObjectName("filterContainer");
    filterContainer->setStyleSheet("#filterContainer { background: #F6CB1C; border-top-right-radius: 10px; padding: 3px; }");
    filterContainer->setFixedWidth(150);
    txtFilter = new LineEditCursor(filterContainer);
    txtFilter->setFixedWidth(150);
    txtFilter->setFocus();
    txtFilter->setFixedHeight(22);
    txtFilter->setStyleSheet("LineEditCursor { border-width: 0px; border-radius: 6px; margin-top: 3px; margin-right: 3px; padding-left: 4px; padding-bottom: 2px; background-color: rgb(23, 11, 54); } LineEditCursor:hover, LineEditCursor:focus { background-color: rgb(13, 5, 68); }");
    connect(txtFilter, SIGNAL(textChanged(const QString &)), this, SLOT(filterChanged(const QString &)));
    connect(txtFilter, SIGNAL(moveUp()), this, SLOT(moveUp()));
    connect(txtFilter, SIGNAL(moveDown()), this, SLOT(moveDown()));
    connect(txtFilter, SIGNAL(moveLeft()), this, SLOT(moveLeft()));
    connect(txtFilter, SIGNAL(moveRight()), this, SLOT(moveRight()));

    // Corner widget
    QLabel * corner = new QLabel();
    corner->setPixmap(QPixmap(QString::fromUtf8(":/res/inverse-corner-bl.png")));
    corner->setFixedSize(10, 10);

    // Add widgets to top layout
    topLayout->addWidget(lblDesc);
    topLayout->addWidget(filterContainer);
    topLayout->addWidget(corner, 0, Qt::AlignBottom);
    topLayout->addStretch(1);

    // Cancel button (closes dialog)
    QPushButton * btnCancel = new QPushButton(tr("Cancel"));
    connect(btnCancel, SIGNAL(clicked()), this, SLOT(reject()));

    // Select button
    QPushButton * btnSelect = new QPushButton(tr("Use selected theme"));
    btnSelect->setDefault(true);
    connect(btnSelect, SIGNAL(clicked()), this, SLOT(onAccepted()));

    // Add themes
    list = new ThemeListView();
    list->setModel(filterModel);
    list->setViewMode(QListView::IconMode);
    list->setResizeMode(QListView::Adjust);
    list->setMovement(QListView::Static);
    list->setEditTriggers(QAbstractItemView::NoEditTriggers);
    list->setSpacing(8);
    list->setWordWrap(true);
    list->setSelectionMode(QAbstractItemView::SingleSelection);
    list->setObjectName("themeList");
    list->setCurrentIndex(filterModel->index(currentIndex, 0));
    connect(list, SIGNAL(activated(const QModelIndex &)), this, SLOT(themeChosen(const QModelIndex &)));
    connect(list, SIGNAL(clicked(const QModelIndex &)), this, SLOT(themeChosen(const QModelIndex &)));

    // Add elements to layouts
    dialogLayout->addLayout(topLayout, 0, 0, 1, 3);
    dialogLayout->addWidget(list, 1, 0, 1, 3);
    dialogLayout->addWidget(btnCancel, 2, 0, 1, 1, Qt::AlignLeft);
    dialogLayout->addWidget(btnSelect, 2, 2, 1, 1, Qt::AlignRight);
}

void ThemePrompt::moveUp()
{
    list->moveUp();
}

void ThemePrompt::moveDown()
{
    list->moveDown();
}

void ThemePrompt::moveLeft()
{
    list->moveLeft();
}

void ThemePrompt::moveRight()
{
    list->moveRight();
}

void ThemePrompt::onAccepted()
{
    themeChosen(list->currentIndex());
}

// When a theme is selected
void ThemePrompt::themeChosen(const QModelIndex & index)
{
    done(filterModel->mapToSource(index).row() + 1); // Since returning 0 means canceled
}

// When the text in the filter text box is changed
void ThemePrompt::filterChanged(const QString & text)
{
    filterModel->setFilterFixedString(text);
    list->setCurrentIndex(filterModel->index(0, 0));
}
