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

#include "pageroomslist.h"

#include <QComboBox>
#include <QDebug>
#include <QGridLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QLabel>
#include <QLineEdit>
#include <QMenu>
#include <QMessageBox>
#include <QPushButton>
#include <QSettings>
#include <QSortFilterProxyModel>
#include <QSplitter>
#include <QVBoxLayout>

#include "chatwidget.h"
#include "gameSchemeModel.h"
#include "hwconsts.h"
#include "lineeditcursor.h"
#include "roomnameprompt.h"
#include "roomslistmodel.h"

void RoomTableView::moveDown() {
  setCurrentIndex(moveCursor(QAbstractItemView::MoveDown, Qt::NoModifier));
}

void RoomTableView::moveUp() {
  setCurrentIndex(moveCursor(QAbstractItemView::MoveUp, Qt::NoModifier));
}

QLayout *PageRoomsList::bodyLayoutDefinition() {
  // TODO move stylesheet stuff into css/qt.css

  QVBoxLayout *pageLayout = new QVBoxLayout();
  pageLayout->setSpacing(0);

  QGridLayout *topLayout = new QGridLayout();
  topLayout->setSpacing(0);
  pageLayout->addLayout(topLayout, 0);

  // State button

  QPushButton *btnState = new QPushButton(tr("Room state"));
  btnState->setStyleSheet(QStringLiteral(
      "QPushButton { background-color: #F6CB1C; border-color: #F6CB1C; color: "
      "#130F2A; padding: 1px 3px 3px 3px; margin: 0px; border-bottom: none; "
      "border-radius: 0px; border-top-left-radius: 10px; } QPushButton:hover { "
      "background-color: #FFEB3C; border-color: #F6CB1C; color: #000000 } "
      "QPushButton:pressed { background-color: #FFEB3C; border-color: #F6CB1C; "
      "color: #000000; }"));
  btnState->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Preferred);

  // State menu

  QMenu *stateMenu = new QMenu(btnState);
  showGamesInLobby = new QAction(QAction::tr("Show games in lobby"), stateMenu);
  showGamesInLobby->setCheckable(true);
  showGamesInLobby->setChecked(true);
  showGamesInProgress =
      new QAction(QAction::tr("Show games in-progress"), stateMenu);
  showGamesInProgress->setCheckable(true);
  showGamesInProgress->setChecked(true);
  showPassword = new QAction(QAction::tr("Show password protected"), stateMenu);
  showPassword->setCheckable(true);
  showPassword->setChecked(true);
  showJoinRestricted =
      new QAction(QAction::tr("Show join restricted"), stateMenu);
  showJoinRestricted->setCheckable(true);
  showJoinRestricted->setChecked(true);
  showIncompatible = new QAction(QAction::tr("Show incompatible"), stateMenu);
  showIncompatible->setCheckable(true);
  showIncompatible->setChecked(true);
  stateMenu->addAction(showGamesInLobby);
  stateMenu->addAction(showGamesInProgress);
  stateMenu->addAction(showPassword);
  stateMenu->addAction(showJoinRestricted);
  stateMenu->addAction(showIncompatible);
  btnState->setMenu(stateMenu);

  // Help/prompt message at top
  QLabel *lblDesc = new QLabel(tr("Search for a room:"));
  lblDesc->setObjectName("lblDesc");
  lblDesc->setStyleSheet(
      QStringLiteral("#lblDesc { color: #130F2A; background: #F6CB1C; border: "
                     "solid 4px #F6CB1C; padding: 5px 10px 3px 6px;}"));
  lblDesc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
  lblDesc->setFixedHeight(24);
  lblDesc->setMinimumWidth(0);

  // Search text box
  QWidget *searchContainer = new QWidget();
  searchContainer->setFixedHeight(24);
  searchContainer->setObjectName("searchContainer");
  searchContainer->setStyleSheet(
      QStringLiteral("#searchContainer { background: #F6CB1C; "
                     "border-top-right-radius: 10px; padding: 3px; }"));
  searchContainer->setFixedWidth(200);
  searchText = new LineEditCursor(searchContainer);
  searchText->setFixedWidth(200);
  searchText->setMaxLength(60);
  searchText->setFixedHeight(22);
  searchText->setStyleSheet(QStringLiteral(
      "LineEditCursor { border-width: 0px; border-radius: 6px; margin-top: "
      "3px; margin-right: 3px; padding-left: 4px; padding-bottom: 2px; "
      "background-color: rgb(23, 11, 54); } LineEditCursor:hover, "
      "LineEditCursor:focus { background-color: rgb(13, 5, 68); }"));

  // Corner widget
  QLabel *corner = new QLabel();
  corner->setPixmap(QPixmap(QStringLiteral(":/res/inverse-corner-bl.png")));
  corner->setFixedSize(10, 10);

  const QIcon &lp = QIcon(":/res/new.png");
  // QSize sz = lp.actualSize(QSize(65535, 65535));
  BtnCreate = new QPushButton();
  BtnCreate->setText(tr("Create room"));
  BtnCreate->setIcon(lp);
  BtnCreate->setStyleSheet(
      QStringLiteral("padding: 4px 8px; margin-bottom: 6px;"));

  BtnJoin = new QPushButton(tr("Join room"));
  BtnJoin->setStyleSheet(QStringLiteral(
      "padding: 4px 8px; margin-bottom: 6px; margin-left: 6px;"));
  BtnJoin->setEnabled(false);

  // Add widgets to top layout
  topLayout->addWidget(btnState, 1, 0);
  topLayout->addWidget(lblDesc, 1, 1);
  topLayout->addWidget(searchContainer, 1, 2);
  topLayout->addWidget(corner, 1, 3, Qt::AlignBottom);
  topLayout->addWidget(BtnCreate, 0, 5, 2, 1);
  topLayout->addWidget(BtnJoin, 0, 6, 2, 1);

  // Top layout stretch
  topLayout->setRowStretch(0, 1);
  topLayout->setRowStretch(1, 0);
  topLayout->setColumnStretch(4, 1);

  // Rooms list and chat with splitter
  m_splitter = new QSplitter();
  m_splitter->setChildrenCollapsible(false);
  pageLayout->addWidget(m_splitter, 100);

  // Room list
  QWidget *roomsListWidget = new QWidget(this);
  m_splitter->setOrientation(Qt::Vertical);
  m_splitter->addWidget(roomsListWidget);

  QVBoxLayout *roomsLayout = new QVBoxLayout(roomsListWidget);
  roomsLayout->setContentsMargins(QMargins{});

  roomsList = new RoomTableView(this);
  roomsList->setSelectionBehavior(QAbstractItemView::SelectRows);
  roomsList->verticalHeader()->setVisible(false);
  roomsList->horizontalHeader()->setSectionResizeMode(QHeaderView::Interactive);
  roomsList->horizontalHeader()->stretchLastSection();
  roomsList->setAlternatingRowColors(true);
  roomsList->setShowGrid(false);
  roomsList->setSelectionMode(QAbstractItemView::SingleSelection);
  roomsList->setStyleSheet(
      QStringLiteral("QTableView { border-top-left-radius: 0px; }"));
  roomsList->setFocusPolicy(Qt::NoFocus);
  roomsLayout->addWidget(roomsList, 200);

  // Lobby chat

  chatWidget = new HWChatWidget(this, false);
  m_splitter->addWidget(chatWidget);

  return pageLayout;
}

QLayout *PageRoomsList::footerLayoutDefinition() {
  QHBoxLayout *bottomLayout = new QHBoxLayout();

  BtnAdmin =
      addButton(tr("Admin features"), bottomLayout, 0, false, Qt::AlignBottom);
  BtnAdmin->setMinimumSize(180, 50);
  BtnAdmin->setStyleSheet(QStringLiteral("padding: 5px 10px"));
  BtnAdmin->setWhatsThis(tr("Open server administration page"));

  return bottomLayout;
}

void PageRoomsList::connectSignals() {
  connect(chatWidget, &HWChatWidget::nickCountUpdate, this,
          &PageRoomsList::updateNickCounter);

  connect(BtnCreate, &QAbstractButton::clicked, this,
          &PageRoomsList::onCreateClick);
  connect(BtnJoin, &QAbstractButton::clicked, this,
          &PageRoomsList::onJoinClick);
  connect(searchText, &LineEditCursor::moveUp, this,
          &PageRoomsList::moveSelectionUp);
  connect(searchText, &LineEditCursor::moveDown, this,
          &PageRoomsList::moveSelectionDown);
  connect(searchText, &QLineEdit::returnPressed, this,
          &PageRoomsList::onJoinClick);
  connect(roomsList, &QAbstractItemView::doubleClicked, this,
          &PageRoomsList::onJoinClick);
  connect(roomsList, &QAbstractItemView::clicked, this,
          [this]() { searchText->setFocus(); });
  connect(showGamesInLobby, &QAction::triggered, this,
          &PageRoomsList::onFilterChanged);
  connect(showGamesInProgress, &QAction::triggered, this,
          &PageRoomsList::onFilterChanged);
  connect(showPassword, &QAction::triggered, this,
          &PageRoomsList::onFilterChanged);
  connect(showJoinRestricted, &QAction::triggered, this,
          &PageRoomsList::onFilterChanged);
  connect(showIncompatible, &QAction::triggered, this,
          &PageRoomsList::onFilterChanged);
  connect(searchText, &QLineEdit::textChanged, this,
          &PageRoomsList::onFilterChanged);
  connect(this, &PageRoomsList::askJoinConfirmation, this,
          &PageRoomsList::onJoinConfirmation, Qt::QueuedConnection);

  // Set focus on search box
  connect(this, &PageRoomsList::pageEnter, this,
          [this]() { searchText->setFocus(); });

  // sorting
  connect(roomsList->horizontalHeader(), &QHeaderView::sortIndicatorChanged,
          this, &PageRoomsList::onSortIndicatorChanged);
}

void PageRoomsList::moveSelectionUp() { roomsList->moveUp(); }

void PageRoomsList::moveSelectionDown() { roomsList->moveDown(); }

void PageRoomsList::roomSelectionChanged(const QModelIndex &current,
                                         const QModelIndex &previous) {
  Q_UNUSED(previous);

  BtnJoin->setEnabled(current.isValid());
}

PageRoomsList::PageRoomsList(QWidget *parent) : AbstractPage(parent) {
  initPage();
}

void PageRoomsList::displayError(const QString &message) {
  chatWidget->displayError(message);
}

void PageRoomsList::displayNotice(const QString &message) {
  chatWidget->displayNotice(message);
}

void PageRoomsList::displayWarning(const QString &message) {
  chatWidget->displayWarning(message);
}

void PageRoomsList::setAdmin(bool flag) { BtnAdmin->setVisible(flag); }

void PageRoomsList::onCreateClick() {
  RoomNamePrompt prompt(
      this,
      m_gameSettings->value("frontend/lastroomname", QString()).toString());
  if (prompt.exec())
    onRoomNameChosen(prompt.getRoomName(), prompt.getPassword());
}

void PageRoomsList::onRoomNameChosen(const QString &roomName,
                                     const QString &password) {
  if (!roomName.trimmed().isEmpty()) {
    m_gameSettings->setValue("frontend/lastroomname", roomName);
    Q_EMIT askForCreateRoom(roomName, password);
  } else {
    onCreateClick();
  }
}

void PageRoomsList::onJoinClick() {
  QModelIndexList mdl = roomsList->selectionModel()->selectedRows();

  if (mdl.size() != 1) {
    QMessageBox roomNameMsg(this);
    roomNameMsg.setIcon(QMessageBox::Warning);
    roomNameMsg.setWindowTitle(QMessageBox::tr("Room Name - Error"));
    roomNameMsg.setText(QMessageBox::tr("Please select room from the list"));
    roomNameMsg.setTextFormat(Qt::PlainText);
    roomNameMsg.setWindowModality(Qt::WindowModal);
    roomNameMsg.exec();
    return;
  }

  bool gameInLobby = roomsList->model()
                         ->index(mdl[0].row(), 0)
                         .data()
                         .toString()
                         .compare(QLatin1String("True"));
  QString roomName =
      roomsList->model()->index(mdl[0].row(), 1).data().toString();

  if (!gameInLobby)
    Q_EMIT askJoinConfirmation(roomName);
  else
    Q_EMIT askForJoinRoom(roomName, QString());
}

void PageRoomsList::onRefreshClick() { Q_EMIT askForRoomList(); }

void PageRoomsList::onJoinConfirmation(const QString &room) {
  QMessageBox reallyJoinMsg(this);
  reallyJoinMsg.setIcon(QMessageBox::Question);
  reallyJoinMsg.setWindowTitle(QMessageBox::tr("Room Name - Are you sure?"));
  reallyJoinMsg.setText(
      QMessageBox::tr("The game you are trying to join has started.\nDo you "
                      "still want to join the room?"));
  reallyJoinMsg.setTextFormat(Qt::PlainText);
  reallyJoinMsg.setWindowModality(Qt::WindowModal);
  reallyJoinMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

  if (reallyJoinMsg.exec() == QMessageBox::Ok) {
    Q_EMIT askForJoinRoom(room, QString());
  }
}

void PageRoomsList::updateNickCounter(int cnt) {
  setDefaultDescription(tr("%1 players online", 0, cnt).arg(cnt));
}

void PageRoomsList::setUser(const QString &nickname) {
  chatWidget->setUser(nickname);
}

void PageRoomsList::setModel(RoomsListModel *model) {
  // filter chain:
  // model -> versionFilteredModel -> stateFilteredModel -> schemeFilteredModel
  // ->
  // -> weaponsFilteredModel -> roomsModel (search filter+sorting)

  if (roomsModel == NULL) {
    roomsModel = new QSortFilterProxyModel(this);
    roomsModel->setDynamicSortFilter(true);
    roomsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    roomsModel->sort(RoomsListModel::StateColumn, Qt::AscendingOrder);

    versionFilteredModel = new QSortFilterProxyModel(this);
    versionFilteredModel->setDynamicSortFilter(true);
    versionFilteredModel->setFilterKeyColumn(RoomsListModel::VersionColumn);
    versionFilteredModel->setFilterRole(Qt::UserRole);

    stateFilteredModel = new QSortFilterProxyModel(this);
    stateFilteredModel->setDynamicSortFilter(true);
    stateFilteredModel->setFilterKeyColumn(RoomsListModel::StateColumn);
    stateFilteredModel->setSourceModel(versionFilteredModel);

    roomsModel->setFilterKeyColumn(-1);  // search in all columns

    roomsModel->setFilterCaseSensitivity(Qt::CaseInsensitive);

    roomsModel->setSourceModel(stateFilteredModel);

    // let the table view display the last model in the filter chain
    roomsList->setModel(roomsModel);

    // When the data changes
    connect(roomsModel, &QSortFilterProxyModel::layoutChanged, roomsList,
            qOverload<>(&RoomTableView::repaint));

    // When a selection changes
    connect(roomsList->selectionModel(),
            &QItemSelectionModel::currentRowChanged, this,
            &PageRoomsList::roomSelectionChanged);
  }

  versionFilteredModel->setSourceModel(model);

  QHeaderView *h = roomsList->horizontalHeader();

  h->setSortIndicatorShown(true);
  h->setSortIndicator(RoomsListModel::StateColumn, Qt::AscendingOrder);
  h->setSectionResizeMode(RoomsListModel::NameColumn, QHeaderView::Stretch);

  h->resizeSection(RoomsListModel::PlayerCountColumn, 32);
  h->resizeSection(RoomsListModel::TeamCountColumn, 32);
  h->resizeSection(RoomsListModel::OwnerColumn, 100);
  h->resizeSection(RoomsListModel::MapColumn, 100);
  h->resizeSection(RoomsListModel::SchemeColumn, 100);
  h->resizeSection(RoomsListModel::WeaponsColumn, 100);

  // hide column used for filtering
  roomsList->hideColumn(RoomsListModel::StateColumn);

  roomsList->repaint();
}

void PageRoomsList::onSortIndicatorChanged(int logicalIndex,
                                           Qt::SortOrder order) {
  if (roomsModel == NULL) return;

  if (logicalIndex == 0) {
    roomsModel->sort(0, Qt::AscendingOrder);
    return;
  }

  // three state sorting: asc -> dsc -> default (by room state)
  if ((order == Qt::AscendingOrder) &&
      (logicalIndex == roomsModel->sortColumn()))
    roomsList->horizontalHeader()->setSortIndicator(RoomsListModel::StateColumn,
                                                    Qt::AscendingOrder);
  else
    roomsModel->sort(logicalIndex, order);
}

void PageRoomsList::onFilterChanged() {
  if (roomsModel == NULL) return;

  roomsModel->setFilterFixedString(searchText->text());

  bool stateLobby = showGamesInLobby->isChecked();
  bool stateProgress = showGamesInProgress->isChecked();
  bool statePassword = showPassword->isChecked();
  bool stateJoinRestricted = showJoinRestricted->isChecked();
  bool stateIncompatible = showIncompatible->isChecked();

  if (!stateIncompatible)
    versionFilteredModel->setFilterFixedString(cProtoVer);
  else
    versionFilteredModel->setFilterFixedString(QLatin1String(""));

  QString filter;
  if (!stateLobby && !stateProgress)
    filter = QStringLiteral("O_o");
  else if (stateLobby && stateProgress && statePassword && stateJoinRestricted)
    filter = QLatin1String("");
  else {
    QString exclude = QStringLiteral("[^");
    if (!stateProgress) exclude += QLatin1String("g");
    if (!statePassword) exclude += QLatin1String("p");
    if (!stateJoinRestricted) exclude += QLatin1String("j");
    exclude += QLatin1String("]*");
    if (stateProgress && statePassword && stateJoinRestricted)
      exclude = QStringLiteral(".*");
    filter = QStringLiteral("^") + exclude;
    if (!stateLobby) filter += QStringLiteral("g") + exclude;
    filter += QLatin1String("$");
  }
  // qDebug() << filter;

  stateFilteredModel->setFilterRegularExpression(filter);
}

void PageRoomsList::setSettings(QSettings *settings) {
  m_gameSettings = settings;
}
