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

#include "pagetraining.h"

#include <QFile>
#include <QGridLayout>
#include <QLabel>
#include <QListWidget>
#include <QListWidgetItem>
#include <QLocale>
#include <QPushButton>
#include <QSettings>
#include <QTextStream>
#include <QVBoxLayout>

#include "DataManager.h"
#include "hwconsts.h"
#include "mission.h"
#include "physfs_integration.h"

QLayout* PageTraining::bodyLayoutDefinition() {
  QGridLayout* pageLayout = new QGridLayout();

  // declare start button, caption and description
  btnPreview = formattedButton(QStringLiteral(":/res/Trainings.png"), true);

  // tweak widget spacing
  pageLayout->setRowStretch(0, 1);
  pageLayout->setRowStretch(1, 1);
  pageLayout->setRowStretch(2, 1);
  pageLayout->setColumnStretch(0, 5);
  pageLayout->setColumnStretch(1, 1);
  pageLayout->setColumnStretch(2, 9);
  pageLayout->setColumnStretch(3, 5);

  QWidget* infoWidget = new QWidget();
  QHBoxLayout* infoLayout = new QHBoxLayout();
  // add preview, caption and description
  infoWidget->setLayout(infoLayout);
  infoLayout->addWidget(btnPreview);

  // center preview
  infoLayout->setAlignment(btnPreview, Qt::AlignRight | Qt::AlignVCenter);

  // info area (caption on top, description below)
  QWidget* infoTextWidget = new QWidget();
  QVBoxLayout* infoTextLayout = new QVBoxLayout();
  infoTextWidget->setObjectName("trainingInfo");
  infoTextWidget->setLayout(infoTextLayout);

  lblCaption = new QLabel();
  lblCaption->setMinimumWidth(360);
  lblCaption->setAlignment(Qt::AlignHCenter | Qt::AlignBottom);
  lblCaption->setWordWrap(true);
  lblDescription = new QLabel();
  lblDescription->setMinimumWidth(360);
  lblDescription->setAlignment(Qt::AlignHCenter | Qt::AlignTop);
  lblDescription->setWordWrap(true);
  lblHighscores = new QLabel();
  lblHighscores->setMinimumWidth(360);
  lblHighscores->setAlignment(Qt::AlignHCenter | Qt::AlignTop);

  infoTextLayout->addWidget(lblCaption);
  infoTextLayout->addWidget(lblDescription);
  infoTextLayout->addWidget(lblHighscores);

  infoLayout->addWidget(infoTextWidget);

  pageLayout->addWidget(infoWidget, 0, 1, 1, 2);  // span 2 columns
  pageLayout->setAlignment(infoTextWidget, Qt::AlignLeft);

  // tab widget containing all lists
  tbw = new QTabWidget(this);
  pageLayout->addWidget(tbw, 1, 0, 1, 4);  // span 4 columns
  // let's not make the tab widget use more space than needed
  tbw->setFixedWidth(400);
  pageLayout->setAlignment(tbw, Qt::AlignHCenter);

  // training/challenge/scenario lists
  lstTrainings = new QListWidget(this);
  lstTrainings->setWhatsThis(tr("Pick the training to play"));
  lstTrainings->setObjectName("trainingList");

  lstChallenges = new QListWidget(this);
  lstChallenges->setWhatsThis(tr("Pick the challenge to play"));
  lstChallenges->setObjectName("trainingList");

  lstScenarios = new QListWidget(this);
  lstScenarios->setWhatsThis(tr("Pick the scenario to play"));
  lstScenarios->setObjectName("trainingList");

  tbw->addTab(lstTrainings, tr("Trainings"));
  tbw->addTab(lstChallenges, tr("Challenges"));
  tbw->addTab(lstScenarios, tr("Scenarios"));
  tbw->setCurrentWidget(lstTrainings);

  QLabel* lblteam = new QLabel(tr("Team"));
  CBTeam = new QComboBox(this);
  CBTeam->setMaxVisibleItems(30);
  pageLayout->addWidget(lblteam, 2, 1);
  pageLayout->addWidget(CBTeam, 2, 2);

  return pageLayout;
}

QLayout* PageTraining::footerLayoutDefinition() {
  QBoxLayout* bottomLayout = new QVBoxLayout();

  const QIcon& lp = QIcon(":/res/Start.png");
  QSize sz = lp.actualSize(QSize(65535, 65535));
  btnStart = new QPushButton();
  btnStart->setStyleSheet(QStringLiteral("padding: 5px 10px"));
  btnStart->setText(QPushButton::tr("Start"));
  btnStart->setWhatsThis(tr("Start fighting"));
  btnStart->setMinimumWidth(sz.width() + 60);
  btnStart->setIcon(lp);
  btnStart->setFixedHeight(50);
  btnStart->setIconSize(sz);
  btnStart->setFlat(true);
  btnStart->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);

  bottomLayout->addWidget(btnStart);

  bottomLayout->setAlignment(btnStart, Qt::AlignRight | Qt::AlignVCenter);

  return bottomLayout;
}

void PageTraining::connectSignals() {
  connect(lstTrainings, &QListWidget::currentItemChanged, this,
          &PageTraining::updateInfo);
  connect(lstTrainings, &QListWidget::itemClicked, this,
          &PageTraining::updateInfo);
  connect(lstTrainings, &QListWidget::itemDoubleClicked, this,
          &PageTraining::startSelected);

  connect(lstChallenges, &QListWidget::currentItemChanged, this,
          &PageTraining::updateInfo);
  connect(lstChallenges, &QListWidget::itemClicked, this,
          &PageTraining::updateInfo);
  connect(lstChallenges, &QListWidget::itemDoubleClicked, this,
          &PageTraining::startSelected);

  connect(lstScenarios, &QListWidget::currentItemChanged, this,
          &PageTraining::updateInfo);
  connect(lstScenarios, &QListWidget::itemClicked, this,
          &PageTraining::updateInfo);
  connect(lstScenarios, &QListWidget::itemDoubleClicked, this,
          &PageTraining::startSelected);

  connect(tbw, &QTabWidget::currentChanged, this, &PageTraining::updateInfo);

  connect(btnPreview, &QAbstractButton::clicked, this,
          &PageTraining::startSelected);
  connect(btnStart, &QAbstractButton::clicked, this,
          &PageTraining::startSelected);
}

PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent) {
  initPage();

  auto& pfs = PhysFsManager::instance();
  DataManager& dataMgr = DataManager::instance();

  // get locale
  QSettings settings(dataMgr.settingsFileName(), QSettings::IniFormat);

  QString loc = QLocale().name();

  QString infoFile =
      QStringLiteral("/Locale/missions_") + loc + QStringLiteral(".txt");

  // if file is non-existant try with language only
  if (!pfs.exists(infoFile))
    infoFile = QStringLiteral("/Locale/missions_") +
               loc.remove(QRegularExpression(QStringLiteral("_.*$"))) +
               QStringLiteral(".txt");

  // fallback if file for current locale is non-existant
  if (!pfs.exists(infoFile))
    infoFile = QStringLiteral("/Locale/missions_en.txt");

  // preload mission info for current locale
  m_info = new PhysFsIniReader(infoFile, this);

  QStringList m_list;
  QListWidget* m_widget;
  QString subFolder;

  for (int i = 1; i <= 3; i++) {
    switch (i) {
      case 1:
        subFolder = QStringLiteral("Training");
        m_widget = lstTrainings;
        break;
      case 2:
        subFolder = QStringLiteral("Challenge");
        m_widget = lstChallenges;
        break;
      case 3:
        subFolder = QStringLiteral("Scenario");
        m_widget = lstScenarios;
        break;
    }
    // scripts to load
    // first, load scripts in order specified in order.cfg (if present)
    PhysFsFile orderFile(
        QStringLiteral("/Missions/%1/order.cfg").arg(subFolder));
    QStringList orderedMissions;

    if (orderFile.open(QFile::ReadOnly)) {
      QString m_id;
      QTextStream input(&orderFile);
      while (true) {
        m_id = input.readLine();
        if (m_id.isNull() || m_id.isEmpty()) {
          break;
        }
        QListWidgetItem* item = new QListWidgetItem(m_id);
        QString name =
            item->text().replace(QLatin1String("_"), QLatin1String(" "));
        name = m_info->value(m_id + QStringLiteral(".name"), name).toString();
        item->setText(name);
        item->setData(Qt::UserRole, m_id);
        m_widget->addItem(item);

        orderedMissions << m_id;
      }
    }

    // then, just load anything else in no particular order
    m_list =
        dataMgr
            .entryList(QStringLiteral("Missions/") + subFolder, QDir::Files,
                       QStringList("*.lua"))
            .replaceInStrings(QRegularExpression(QStringLiteral("\\.lua$")),
                              QLatin1String(""));

    for (auto&& m_id : m_list) {
      // Disallow duplicates from order.cfg
      if (orderedMissions.contains(m_id)) {
        continue;
      }

      QListWidgetItem* item = new QListWidgetItem(m_id);

      // fallback name: replace underscores in mission name with spaces
      QString name =
          item->text().replace(QLatin1String("_"), QLatin1String(" "));

      // see if we can get a prettier/translated name
      name = m_info->value(m_id + QStringLiteral(".name"), name).toString();

      item->setText(name);

      // store original name in data
      item->setData(Qt::UserRole, m_id);

      m_widget->addItem(item);
    }
  }

  updateInfo();

  // pre-select first mission
  if (lstTrainings->count() > 0) lstTrainings->setCurrentRow(0);

  if (lstChallenges->count() > 0) lstChallenges->setCurrentRow(0);

  if (lstScenarios->count() > 0) lstScenarios->setCurrentRow(0);
}

QString PageTraining::getSubFolderOfSelected() {
  QString subFolder;
  if (tbw->currentWidget() == lstTrainings) {
    subFolder = QStringLiteral("Training");
  } else if (tbw->currentWidget() == lstChallenges) {
    subFolder = QStringLiteral("Challenge");
  } else if (tbw->currentWidget() == lstScenarios) {
    subFolder = QStringLiteral("Scenario");
  } else {
    subFolder = QStringLiteral("Training");
  }
  return subFolder;
}

void PageTraining::startSelected() {
  QListWidget* list;
  list = (QListWidget*)tbw->currentWidget();
  QListWidgetItem* curItem = list->currentItem();

  if ((curItem != NULL) && (CBTeam->currentIndex() != -1))
    Q_EMIT startMission(curItem->data(Qt::UserRole).toString(),
                        getSubFolderOfSelected());
}

void PageTraining::updateInfo() {
  if (tbw->currentWidget()) {
    QString subFolder;
    QListWidget* list;
    subFolder = getSubFolderOfSelected();
    list = (QListWidget*)tbw->currentWidget();
    if (list->currentItem()) {
      QString missionName = list->currentItem()->data(Qt::UserRole).toString();
      QString thumbFile = QStringLiteral("/Graphics/Missions/") + subFolder +
                          QStringLiteral("/") + missionName +
                          QStringLiteral("@2x.png");

      auto& pfs = PhysFsManager::instance();
      if (pfs.exists(thumbFile))
        btnPreview->setIcon(pfs.readIcon(thumbFile));
      else if (tbw->currentWidget() == lstChallenges)
        btnPreview->setIcon(QIcon(":/res/Challenges.png"));
      else if (tbw->currentWidget() == lstScenarios)
        // TODO: Prettier scenario fallback image
        btnPreview->setIcon(QIcon(":/res/Scenarios.png"));
      else
        btnPreview->setIcon(QIcon(":/res/Trainings.png"));

      btnPreview->setWhatsThis(tr("Start fighting"));

      QString caption = m_info
                            ->value(missionName + QStringLiteral(".name"),
                                    list->currentItem()->text())
                            .toString();

      QString description = m_info
                                ->value(missionName + QStringLiteral(".desc"),
                                        tr("No description available"))
                                .toString();

      lblCaption->setText(QStringLiteral("<h2>") + caption +
                          QStringLiteral("</h2>"));
      lblDescription->setText(description);

      // Challenge highscores
      QString highscoreText = QLatin1String("");
      QString teamName = CBTeam->currentText();
      if (missionValueExists(missionName, teamName,
                             QStringLiteral("Highscore")))
        highscoreText = highscoreText +
                        //: Highest score of a team
                        tr("Team highscore: %1")
                            .arg(getMissionValue(missionName, teamName,
                                                 QStringLiteral("Highscore"))
                                     .toString()) +
                        QStringLiteral("\n");
      if (missionValueExists(missionName, teamName, QStringLiteral("Lowscore")))
        highscoreText = highscoreText +
                        //: Lowest score of a team
                        tr("Team lowscore: %1")
                            .arg(getMissionValue(missionName, teamName,
                                                 QStringLiteral("Lowscore"))
                                     .toString()) +
                        QStringLiteral("\n");
      if (missionValueExists(missionName, teamName,
                             QStringLiteral("AccuracyRecord")))
        highscoreText =
            highscoreText +
            //: Best accuracy of a team (in a challenge)
            tr("Team's top accuracy: %1%")
                .arg(getMissionValue(missionName, teamName,
                                     QStringLiteral("AccuracyRecord"))
                         .toString()) +
            QStringLiteral("\n");
      if (missionValueExists(missionName, teamName,
                             QStringLiteral("TimeRecord"))) {
        double time = ((double)getMissionValue(missionName, teamName,
                                               QStringLiteral("TimeRecord"))
                           .toInt()) /
                      1000.0;
        highscoreText = highscoreText +
                        tr("Team's best time: %L1 s").arg(time, 0, 'f', 3) +
                        QStringLiteral("\n");
      }
      if (missionValueExists(missionName, teamName,
                             QStringLiteral("TimeRecordHigh"))) {
        double time = ((double)getMissionValue(missionName, teamName,
                                               QStringLiteral("TimeRecordHigh"))
                           .toInt()) /
                      1000.0;
        highscoreText = highscoreText +
                        tr("Team's longest time: %L1 s").arg(time, 0, 'f', 3) +
                        QStringLiteral("\n");
      }

      lblHighscores->setText(highscoreText);
    } else {
      btnPreview->setIcon(QIcon(":/res/Trainings.png"));
      lblCaption->setText(tr("Select a mission!"));
      lblDescription->setText(QLatin1String(""));
      lblHighscores->setText(QLatin1String(""));
    }
  }
}
