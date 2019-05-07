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

#include "keybinder.h"
#include "HWApplication.h"
#include "DataManager.h"
#include <QHBoxLayout>
#include <QScrollArea>
#include <QTableWidget>
#include <QTableWidgetItem>
#include <QStandardItemModel>
#include <QAbstractItemModel>
#include <QListWidget>
#include <QListWidgetItem>
#include <QPushButton>
#include <QHeaderView>
#include <QComboBox>
#include <QLabel>
#include <QFrame>
#include <QDebug>

KeyBinder::KeyBinder(QWidget * parent, const QString & helpText, const QString & defaultText, const QString & resetButtonText) : QWidget(parent)
{
    this->defaultText = defaultText;
    enableSignal = false;
    p_hasConflicts = false;

    // Two-column tab layout
    QHBoxLayout * pageKeysLayout = new QHBoxLayout(this);
    pageKeysLayout->setSpacing(0);
    pageKeysLayout->setContentsMargins(0, 0, 0, 0);

    // Table for category list
    QVBoxLayout * catListContainer = new QVBoxLayout();
    catListContainer->setContentsMargins(10, 10, 10, 10);
    catList = new QListWidget();
    catList->setFixedWidth(180);
    catList->setStyleSheet("QListWidget::item { font-size: 14px; } QListWidget:hover { border-color: #F6CB1C; } QListWidget::item:selected { background: #150A61; color: yellow; }");
    catList->setFocusPolicy(Qt::NoFocus);
    connect(catList, SIGNAL(currentRowChanged(int)), this, SLOT(changeBindingsPage(int)));
    catListContainer->addWidget(catList);
    pageKeysLayout->addLayout(catListContainer);

    // Reset all binds button
    if (!resetButtonText.isEmpty())
    {
        QPushButton * btnResetAll = new QPushButton(resetButtonText);
        catListContainer->addWidget(btnResetAll);
        btnResetAll->setStyleSheet("padding: 5px 10px");
        btnResetAll->setFixedHeight(40);
        catListContainer->setStretch(1, 0);
        catListContainer->setSpacing(10);
        connect(btnResetAll, SIGNAL(clicked()), this, SIGNAL(resetAllBinds()));
    }

    // Container for pages of key bindings
    QWidget * bindingsPagesContainer = new QWidget();
    QVBoxLayout * rightLayout = new QVBoxLayout(bindingsPagesContainer);

    // Scroll area for key bindings
    QScrollArea * scrollArea = new QScrollArea();
    scrollArea->setContentsMargins(0, 0, 0, 0);
    scrollArea->setWidget(bindingsPagesContainer);
    scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    scrollArea->setWidgetResizable(true);
    scrollArea->setFrameShape(QFrame::NoFrame);
    scrollArea->setStyleSheet("background: #130F2A;");

    // Add key binding pages to bindings tab
    pageKeysLayout->addWidget(scrollArea);
    pageKeysLayout->setStretch(1, 1);

    // Custom help text
    QLabel * helpLabel = new QLabel();
    helpLabel->setText(helpText);
    helpLabel->setStyleSheet("color: #130F2A; background: #F6CB1C; border: solid 4px #F6CB1C; border-radius: 10px; padding: auto 20px;");
    helpLabel->setFixedHeight(24);
    rightLayout->addWidget(helpLabel, 0, Qt::AlignCenter);
    conflictLabel = new QLabel();
    conflictLabel->setText(tr("Warning: The same key is assigned multiple times!"));
    conflictLabel->setStyleSheet("color: white; background: #E31A1A; border: solid 4px #E31A1A; border-radius: 10px; padding: auto 20px;");
    conflictLabel->setFixedHeight(24);
    conflictLabel->setHidden(true);
    rightLayout->addWidget(conflictLabel, 0, Qt::AlignCenter);

    // Category list and bind table row heights
    const int rowHeight = 20;
    QSize catSize, headerSize;
    catSize.setHeight(36);
    headerSize.setHeight(24);

    // Category list header
    QListWidgetItem * catListHeader = new QListWidgetItem(tr("Category"));
    catListHeader->setSizeHint(headerSize);
    catListHeader->setFlags(Qt::NoItemFlags);
    catListHeader->setForeground(QBrush(QColor("#130F2A")));
    catListHeader->setBackground(QBrush(QColor("#F6CB1C")));
    catListHeader->setTextAlignment(Qt::AlignCenter);
    catList->addItem(catListHeader);

    // Populate
    bindingsPages = new QHBoxLayout();
    bindingsPages->setContentsMargins(0, 0, 0, 0);
    rightLayout->addLayout(bindingsPages);
    QWidget * curPage = NULL;
    QVBoxLayout * curLayout = NULL;
    QTableWidget * curTable = NULL;
    bool bFirstPage = true;
    selectedBindTable = NULL;
    bindComboBoxCellMappings = new QHash<QObject *, QTableWidgetItem *>();
    bindCellComboBoxMappings = new QHash<QTableWidgetItem *, QComboBox *>();

    dropDownIcon = new QIcon();
    QPixmap dd1 = QPixmap(":/res/dropdown.png");
    QPixmap dd2 = QPixmap(":/res/dropdown_selected.png");
    dropDownIcon->addPixmap(dd1, QIcon::Normal);
    dropDownIcon->addPixmap(dd2, QIcon::Selected);
    conflictIcon = new QIcon();
    QPixmap kc1 = QPixmap(":/res/keyconflict.png");
    QPixmap kc2 = QPixmap(":/res/keyconflict_selected.png");
    conflictIcon->addPixmap(kc1, QIcon::Normal);
    conflictIcon->addPixmap(kc2, QIcon::Selected);
    QPixmap emptySpace = QPixmap(16, 16);
    emptySpace.fill(QColor(0, 0, 0, 0));
    QIcon emptyIcon = QIcon(emptySpace);

    for (int i = 0; i < BINDS_NUMBER; i++)
    {
        if (cbinds[i].category != NULL)
        {
            // Add stretch at end of previous layout
            if (curLayout != NULL) curLayout->insertStretch(-1, 1);

            // Category list item
            QListWidgetItem * catItem = new QListWidgetItem(HWApplication::translate("binds (categories)", cbinds[i].category));
            catItem->setSizeHint(catSize);
            catList->addItem(catItem);

            // Create new page
            curPage = new QWidget();
            curLayout = new QVBoxLayout(curPage);
            curLayout->setSpacing(2);
            bindingsPages->addWidget(curPage);
            if (!bFirstPage) curPage->setVisible(false);
        }

        // Description
        if (cbinds[i].description != NULL)
        {
            QLabel * desc = new QLabel(HWApplication::translate("binds (descriptions)", cbinds[i].description));
            curLayout->addWidget(desc, 0);
            QFrame * divider = new QFrame();
            divider->setFrameShape(QFrame::HLine);
            divider->setFrameShadow(QFrame::Plain);
            curLayout->addWidget(divider, 0);
        }

        // New table
        if (cbinds[i].category != NULL || cbinds[i].description != NULL)
        {
            curTable = new QTableWidget(0, 2);
            curTable->verticalHeader()->setVisible(false);
            curTable->horizontalHeader()->setVisible(false);
            curTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
            curTable->verticalHeader()->setDefaultSectionSize(rowHeight);
            curTable->setShowGrid(false);
            curTable->setStyleSheet("QTableWidget { border: none; } ");
            curTable->setSelectionBehavior(QAbstractItemView::SelectRows);
            curTable->setSelectionMode(QAbstractItemView::SingleSelection);
            curTable->setFocusPolicy(Qt::NoFocus);
            connect(curTable, SIGNAL(itemSelectionChanged()), this, SLOT(bindSelectionChanged()));
            connect(curTable, SIGNAL(itemClicked(QTableWidgetItem *)), this, SLOT(bindCellClicked(QTableWidgetItem *)));
            curLayout->addWidget(curTable, 0);
        }

        // Hidden combo box
        QComboBox * comboBox;
        if (cbinds[i].action != "!MULTI")
        {
            comboBox = CBBind[i] = new QComboBox(curTable);
            comboBox->setModel((QAbstractItemModel*)DataManager::instance().bindsModel());
            comboBox->setVisible(false);
            comboBox->setMinimumWidth(400);
            comboBox->setMaxVisibleItems(50);
        }
        else
        {
            comboBox = CBBind[i] = NULL;
        }

        // Table row
        int row = curTable->rowCount();
        QTableWidgetItem * nameCell = new QTableWidgetItem(HWApplication::translate("binds", cbinds[i].name));
        curTable->insertRow(row);
        curTable->setItem(row, 0, nameCell);
        QTableWidgetItem * bindCell;
        if (cbinds[i].action != "!MULTI")
        {
            bindCell = new QTableWidgetItem(comboBox->currentText());
            nameCell->setFlags(Qt::ItemIsSelectable | Qt::ItemIsEnabled);
            bindCell->setIcon(*dropDownIcon);
            bindCell->setFlags(Qt::ItemIsSelectable | Qt::ItemIsEnabled);
        }
        else
        {
            bindCell = new QTableWidgetItem(HWApplication::translate("binds (combination)", cbinds[i].strbind.toUtf8().constData()));
            nameCell->setFlags(Qt::NoItemFlags);
            bindCell->setFlags(Qt::NoItemFlags);
            bindCell->setIcon(emptyIcon);
        }
        curTable->setItem(row, 1, bindCell);
        curTable->resizeColumnsToContents();
        curTable->setFixedHeight(curTable->verticalHeader()->length() + 10);

        if (cbinds[i].action != "!MULTI")
        {
            // Updates the text in the table cell
            connect(comboBox, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(bindChanged(const QString &)));

            // Map combo box and that row's cells to each other
            bindComboBoxCellMappings->insert(comboBox, bindCell);
            bindCellComboBoxMappings->insert(nameCell, comboBox);
            bindCellComboBoxMappings->insert(bindCell, comboBox);
        }

    }

    // Add stretch at end of last layout
    if (curLayout != NULL) curLayout->insertStretch(-1, 1);

    // Go to first page
    catList->setCurrentItem(catList->item(1));

    enableSignal = true;
}

KeyBinder::~KeyBinder()
{
    delete bindComboBoxCellMappings;
    delete bindCellComboBoxMappings;
}

// Switches between different pages of key binds
void KeyBinder::changeBindingsPage(int page)
{
    page--; // Disregard first item (the list header)
    int pages = bindingsPages->count();
    for (int i = 0; i < pages; i++)
        bindingsPages->itemAt(i)->widget()->setVisible(false);
    bindingsPages->itemAt(page)->widget()->setVisible(true);
}

// When a key bind combobox value is changed, updates the table cell text
void KeyBinder::bindChanged(const QString & text)
{
    bindComboBoxCellMappings->value(sender())->setText(text);

    if (enableSignal)
    {
        for (int i = 0; i < BINDS_NUMBER; i++)
        {
            if (CBBind[i] == sender())
            {
                emit bindUpdate(i);
                checkConflicts();
                break;
            }
        }
    }
}

// When a row in a key bind table is clicked, this shows the popup
void KeyBinder::bindCellClicked(QTableWidgetItem * item)
{
    QComboBox * box = bindCellComboBoxMappings->value(item);
    if(box == NULL)
        return;
    QTableWidget * table = item->tableWidget();

    box->move(
        table->horizontalHeader()->sectionSize(0),
        (table->verticalHeader()->defaultSectionSize() * (item->row() + 1)) - (box->height()) + 1
    );
    box->showPopup();
}

// When a new row in a bind table is *selected*, this clears selection in any other table
void KeyBinder::bindSelectionChanged()
{
    QTableWidget * theSender = (QTableWidget*)sender();
    if (theSender != selectedBindTable)
    {
        if (selectedBindTable != NULL)
            selectedBindTable->clearSelection();
        selectedBindTable = theSender;
    }
}

// check if the given key is bound multiple times
bool KeyBinder::checkConflictsWith(int compareTo, bool updateState)
{
    // TODO: Make conflict check more efficient
    for(int i=0; i<BINDS_NUMBER; i++)
    {
        if(i == compareTo)
            continue;
        if(CBBind[i] == NULL || CBBind[compareTo] == NULL)
            continue;
        QString bind1 = CBBind[i]->currentData(Qt::UserRole + 1).toString();
        QString bind2 = CBBind[compareTo]->currentData(Qt::UserRole + 1).toString();
        // TODO: For team key binds, also check collisions with global key binds
        if((!(bind1 == "none" || bind2 == "none" || bind1 == "default" || bind2 == "default")) && (bind1 == bind2))
        {
            if(updateState)
            {
                p_hasConflicts = true;
                conflictLabel->setHidden(false);
            }
            QTableWidgetItem* item = bindComboBoxCellMappings->value(CBBind[i]);
            item->setIcon(*conflictIcon);
            item->setBackground(QBrush(QColor(0xE3, 0x1A, 0x1A)));
            item->setForeground(QBrush(Qt::white));
            item = bindComboBoxCellMappings->value(CBBind[compareTo]);
            item->setIcon(*conflictIcon);
            item->setBackground(QBrush(QColor(0xE3, 0x1A, 0x1A)));
            item->setForeground(QBrush(Qt::white));
            return true;
        }
        else
        {
            QTableWidgetItem* item = bindComboBoxCellMappings->value(CBBind[i]);
            item->setIcon(*dropDownIcon);
            item->setBackground(QBrush(Qt::transparent));
            item->setForeground(QBrush(QColor("#F6CB1C")));
            item = bindComboBoxCellMappings->value(CBBind[compareTo]);
            item->setIcon(*dropDownIcon);
            item->setBackground(QBrush(Qt::transparent));
            item->setForeground(QBrush(QColor("#F6CB1C")));
        }
    }
    if(updateState)
    {
        p_hasConflicts = false;
        conflictLabel->setHidden(true);
    }
    return false;
}

// check if any key is bound multiple times and causing a conflict
bool KeyBinder::checkConflicts()
{
    bool conflict = false;
    for(int i=0; i<BINDS_NUMBER; i++)
    {
        conflict = checkConflictsWith(i, false);
        if(conflict)
        {
            p_hasConflicts = true;
            conflictLabel->setHidden(false);
            return true;
        }
    }
    p_hasConflicts = false;
    conflictLabel->setHidden(true);
    return false;
}

bool KeyBinder::hasConflicts()
{
    return p_hasConflicts;
}

// Set a combobox's index
void KeyBinder::setBindIndex(int keyIndex, int bindIndex)
{
    enableSignal = false;
    if(CBBind[keyIndex] != NULL)
        CBBind[keyIndex]->setCurrentIndex(bindIndex);
    enableSignal = true;
}

// Return a combobox's selected index
int KeyBinder::bindIndex(int keyIndex)
{
    if(CBBind[keyIndex] != NULL)
        return CBBind[keyIndex]->currentIndex();
    else
        return 0;
}

// Clears selection and goes to first category
void KeyBinder::resetInterface()
{
    enableSignal = false;

    catList->setCurrentItem(catList->item(1));
    changeBindingsPage(1);
    if (selectedBindTable != NULL)
    {
        selectedBindTable->clearSelection();
        selectedBindTable = NULL;
    }

    // Default bind text
    DataManager::instance().bindsModel()->item(0)->setData(defaultText, Qt::DisplayRole);
    for (int i = 0; i < BINDS_NUMBER; i++)
    {
        if (CBBind[i] != NULL)
        {
            CBBind[i]->setModel(DataManager::instance().bindsModel());
            CBBind[i]->setCurrentIndex(0);
            bindComboBoxCellMappings->value(CBBind[i])->setText(defaultText);
        }
    }

    enableSignal = true;
}
