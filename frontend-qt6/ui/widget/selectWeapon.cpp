/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
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

#include "selectWeapon.h"

#include <math.h>

#include <QBitmap>
#include <QDebug>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QPushButton>
#include <QRegularExpression>
#include <QRegularExpressionValidator>
#include <QSettings>
#include <QTabWidget>

#include "hwconsts.h"
#include "weaponItem.h"

QImage getAmmoImage(int num) {
  // Show ammo image for ammo selection menu
  if (QLocale().decimalPoint() == QLatin1String(",") &&
      num == HW_AMMOTYPE_EXTRADAMAGE) {
    // Special case: Extra Damage icon showing "1,5" instead of "1.5" if locale
    // uses comma as decimal separator
    static QImage extradamage(QStringLiteral(":Ammos_ExtraDamage_comma.png"));
    return extradamage;
  } else {
    // Normal case: Pick icon from Ammos.png
    static QImage ammo(QStringLiteral(":Ammos.png"));
    int x = num / (ammo.height() / 32);
    int y = (num - ((ammo.height() / 32) * x)) * 32;
    x *= 32;
    return ammo.copy(x, y, 32, 32);
  }
}

SelWeaponItem::SelWeaponItem(bool allowInfinite, int iconNum, int wNum,
                             const QImage& image, const QImage& imagegrey,
                             QWidget* parent)
    : QWidget(parent) {
  QHBoxLayout* hbLayout = new QHBoxLayout(this);
  hbLayout->setSpacing(1);
  hbLayout->setContentsMargins(QMargins{1, 1, 1, 1});

  QLabel* lbl = new QLabel(this);
  lbl->setPixmap(QPixmap::fromImage(getAmmoImage(iconNum)));
  lbl->setMaximumWidth(30);
  lbl->setGeometry(0, 0, 30, 30);
  hbLayout->addWidget(lbl);

  item = new WeaponItem(image, imagegrey, this);
  item->setItemsNum(wNum);
  item->setInfinityState(allowInfinite);
  hbLayout->addWidget(item);

  hbLayout->setStretchFactor(lbl, 1);
  hbLayout->setStretchFactor(item, 99);
  hbLayout->setAlignment(lbl, Qt::AlignLeft | Qt::AlignVCenter);
  hbLayout->setAlignment(item, Qt::AlignLeft | Qt::AlignVCenter);
}

void SelWeaponItem::setItemsNum(const unsigned char num) {
  item->setItemsNum(num);
}

unsigned char SelWeaponItem::getItemsNum() const { return item->getItemsNum(); }

void SelWeaponItem::setEnabled(bool value) { item->setEnabled(value); }

int SelWeaponWidget::readWeaponValue(const QChar chr, int max) {
  int value = chr.digitValue();
  if (value == -1)
    value = 0;
  else if (value > max)
    value = max;
  return value;
}

SelWeaponWidget::SelWeaponWidget(int numItems, QWidget* parent)
    : QFrame(parent), m_numItems(numItems) {
  wconf = new QMap<QString, QString>();
  for (int i = 0; i < cDefaultAmmos.size(); ++i) {
    wconf->insert(cDefaultAmmos[i].first, cDefaultAmmos[i].second);
  }

  if (!QDir(cfgdir.absolutePath() + QStringLiteral("/Schemes")).exists()) {
    QDir().mkdir(cfgdir.absolutePath() + QStringLiteral("/Schemes"));
  }
  QStringList defaultAmmos;
  for (int i = 0; i < cDefaultAmmos.size(); ++i) {
    defaultAmmos.append(cDefaultAmmos[i].first.toLower());
  }
  if (!QDir(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo")).exists()) {
    qDebug(
        "No /Schemes/Ammo directory found. Trying to import weapon schemes "
        "from weapons.ini.");
    QDir().mkdir(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo"));

    QSettings old_wconf(cfgdir.absolutePath() + QStringLiteral("/weapons.ini"),
                        QSettings::IniFormat);

    QStringList keys = old_wconf.allKeys();
    int imported = 0;
    for (int i = 0; i < keys.size(); i++) {
      if (!defaultAmmos.contains(keys[i].toLower())) {
        wconf->insert(keys[i],
                      fixWeaponSet(old_wconf.value(keys[i]).toString()));
        QFile file(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo/") +
                   keys[i] + QStringLiteral(".hwa"));
        if (file.open(QIODevice::WriteOnly)) {
          QTextStream stream(&file);
          stream << old_wconf.value(keys[i]).toString() << "\n";
          file.close();
        }
        imported++;
      }
    }
    qDebug("%d weapon scheme(s) imported.", imported);
  } else {
    QStringList schemes =
        QDir(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo"))
            .entryList(QDir::Files);

    for (int i = 0; i < schemes.size(); i++) {
      QFile file(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo/") +
                 schemes[i]);
      QString config;
      if (file.open(QIODevice::ReadOnly)) {
        QTextStream stream(&file);
        stream >> config;
        file.close();
      }

      // Chop off file name suffix
      QString schemeName = schemes[i];
      if (schemeName.endsWith(QLatin1String(".hwa"), Qt::CaseInsensitive)) {
        schemeName.chop(4);
      }
      // Don't load weapon scheme if name collides with any default scheme
      if (!defaultAmmos.contains(schemeName.toLower()))
        wconf->insert(schemeName, fixWeaponSet(config));
      else
        qWarning(
            "Weapon scheme \"%s\" not loaded from file, name collides with a "
            "default scheme!",
            qPrintable(schemeName));
    }
  }

  QString currentState = cDefaultAmmoStore;

  QTabWidget* tbw = new QTabWidget(this);
  QWidget* page1 = new QWidget(this);
  p1Layout = new QGridLayout(page1);
  p1Layout->setSpacing(1);
  p1Layout->setContentsMargins({1, 1, 1, 1});
  QWidget* page2 = new QWidget(this);
  p2Layout = new QGridLayout(page2);
  p2Layout->setSpacing(1);
  p2Layout->setContentsMargins({1, 1, 1, 1});
  QWidget* page3 = new QWidget(this);
  p3Layout = new QGridLayout(page3);
  p3Layout->setSpacing(1);
  p3Layout->setContentsMargins({1, 1, 1, 1});
  QWidget* page4 = new QWidget(this);
  p4Layout = new QGridLayout(page4);
  p4Layout->setSpacing(1);
  p4Layout->setContentsMargins({1, 1, 1, 1});

  tbw->addTab(page1, tr("Weapon set"));
  tbw->addTab(page2, tr("Probabilities"));
  tbw->addTab(page4, tr("Ammo in boxes"));
  tbw->addTab(page3, tr("Delays"));

  QGridLayout* pageLayout = new QGridLayout(this);
  pageLayout->addWidget(tbw);

  int j = -1;
  int i = 0, k = 0;
  for (; i < m_numItems; ++i) {
    if (k % cAmmoMenuRows == 0) ++j;
    unsigned int ammo = ammoMenuAmmos[i];
    // Hide amSkip (7)
    if (ammo == 7) continue;
    // Hide unused amCreeper (58)
    else if (ammo == 58) {
      ++k;
      continue;
    }
    int a = ammo - 1;  // ammo ID for SelWeaponItem
    SelWeaponItem* swi = new SelWeaponItem(
        true, a, readWeaponValue(currentState[a], 9),
        QImage(QStringLiteral(":/res/ammopic.png")),
        QImage(QStringLiteral(":/res/ammopicgrey.png")), this);
    weaponItems[a].append(swi);
    p1Layout->addWidget(swi, j, k % cAmmoMenuRows);

    SelWeaponItem* pwi = new SelWeaponItem(
        false, a, readWeaponValue(currentState[numItems + a], 8),
        QImage(QStringLiteral(":/res/ammopicbox.png")),
        QImage(QStringLiteral(":/res/ammopicboxgrey.png")), this);
    weaponItems[a].append(pwi);
    p2Layout->addWidget(pwi, j, k % cAmmoMenuRows);

    SelWeaponItem* dwi = new SelWeaponItem(
        false, a, readWeaponValue(currentState[numItems * 2 + a], 8),
        QImage(QStringLiteral(":/res/ammopicdelay.png")),
        QImage(QStringLiteral(":/res/ammopicdelaygrey.png")), this);
    weaponItems[a].append(dwi);
    p3Layout->addWidget(dwi, j, k % cAmmoMenuRows);

    SelWeaponItem* awi = new SelWeaponItem(
        false, a, readWeaponValue(currentState[numItems * 3 + a], 8),
        QImage(QStringLiteral(":/res/ammopic.png")),
        QImage(QStringLiteral(":/res/ammopicgrey.png")), this);
    weaponItems[a].append(awi);
    p4Layout->addWidget(awi, j, k % cAmmoMenuRows);

    ++k;
  }

  // pLayout->setRowStretch(5, 100);
  m_name = new QLineEdit(this);
  QRegularExpression rx(cSafeFileNameRegExp);
  QRegularExpressionValidator* val =
      new QRegularExpressionValidator(rx, m_name);
  m_name->setValidator(val);
  pageLayout->addWidget(m_name, i, 0, 1, 5);
}

void SelWeaponWidget::setWeapons(const QString& ammo) {
  bool enable = true;
  for (int i = 0; i < cDefaultAmmos.size(); i++) {
    if (!cDefaultAmmos[i].first.compare(m_name->text())) {
      enable = false;
      break;
    }
  }
  for (int i = 0; i < m_numItems; ++i) {
    auto it = weaponItems.constFind(i);
    if (it == weaponItems.end()) continue;
    it.value()[0]->setItemsNum(readWeaponValue(ammo[i], 9));
    it.value()[1]->setItemsNum(readWeaponValue(ammo[m_numItems + i], 8));
    it.value()[2]->setItemsNum(readWeaponValue(ammo[m_numItems * 2 + i], 8));
    it.value()[3]->setItemsNum(readWeaponValue(ammo[m_numItems * 3 + i], 8));
    it.value()[0]->setEnabled(enable);
    it.value()[1]->setEnabled(enable);
    it.value()[2]->setEnabled(enable);
    it.value()[3]->setEnabled(enable);
  }
  m_name->setEnabled(enable);
}

void SelWeaponWidget::setDefault() {
  for (int i = 0; i < cDefaultAmmos.size(); i++) {
    if (!cDefaultAmmos[i].first.compare(m_name->text())) {
      return;
    }
  }
  setWeapons(cDefaultAmmoStore);
}

// Save current weapons set.
void SelWeaponWidget::save() {
  // The save() function is called by ANY change of the combo box.
  // If an entry is deleted, this code would just re-add the deleted
  // item. We use isDeleted to check if we are currently deleting to
  // prevent this.
  if (isDeleting) return;
  if (m_name->text().isEmpty()) return;

  // Don't save an default ammo scheme
  for (int i = 0; i < cDefaultAmmos.size(); ++i) {
    if (curWeaponsName == cDefaultAmmos[i].first) return;
  }

  QString state1;
  QString state2;
  QString state3;
  QString state4;
  QString stateFull;

  for (int i = 0; i < m_numItems; ++i) {
    auto it = weaponItems.constFind(i);
    int num = it == weaponItems.end()
                  ? 9
                  : it.value()[0]->getItemsNum();  // 9 is for 'skip turn'
    state1.append(QString::number(num));
    int prob = it == weaponItems.end() ? 0 : it.value()[1]->getItemsNum();
    state2.append(QString::number(prob));
    int del = it == weaponItems.end() ? 0 : it.value()[2]->getItemsNum();
    state3.append(QString::number(del));
    int am = it == weaponItems.end() ? 0 : it.value()[3]->getItemsNum();
    state4.append(QString::number(am));
  }

  stateFull = state1 + state2 + state3 + state4;

  // Check for duplicates
  QString inputNameLower = m_name->text().toLower();
  QString curWeaponsNameLower = curWeaponsName.toLower();
  QStringList keys = wconf->keys();
  for (int i = 0; i < keys.size(); i++) {
    QString compName = keys[i];
    QString compNameLower = compName.toLower();
    // Don't allow same name as other weapon set, even case-insensitively.
    // This prevents some problems with saving/loading.
    if ((compNameLower == inputNameLower) &&
        (compNameLower != curWeaponsNameLower)) {
      // Discard changed made to current weapon scheme if there's a duplicate
      m_name->setText(curWeaponsName);
      QMessageBox deniedMsg(this);
      deniedMsg.setIcon(QMessageBox::Warning);
      deniedMsg.setWindowTitle(QMessageBox::tr("Weapons - Warning"));
      deniedMsg.setText(
          QMessageBox::tr(
              "A weapon scheme with the name '%1' already exists. Changes made "
              "to the weapon scheme have been discarded.")
              .arg(compName));
      deniedMsg.setTextFormat(Qt::PlainText);
      deniedMsg.setWindowModality(Qt::WindowModal);
      deniedMsg.exec();
      return;
    }
  }

  if (!curWeaponsName.isEmpty()) {
    // remove old entry
    wconf->remove(curWeaponsName);
  }
  wconf->insert(m_name->text(), stateFull);
  QFile file(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo/") +
             m_name->text() + QStringLiteral(".hwa"));
  if (file.open(QIODevice::WriteOnly)) {
    QTextStream stream(&file);
    stream << stateFull << "\n";
    file.close();
  }
  Q_EMIT weaponsEdited(curWeaponsName, m_name->text(), stateFull);
  curWeaponsName = m_name->text();
}

int SelWeaponWidget::operator[](unsigned int weaponIndex) const {
  twi::const_iterator it = weaponItems.find(weaponIndex);
  return it == weaponItems.end() ? 9 : it.value()[0]->getItemsNum();
}

QString SelWeaponWidget::getWeaponsString(const QString& name) const {
  return std::as_const(wconf)->find(name).value();
}

void SelWeaponWidget::deleteWeaponsName() {
  QString delWeaponsName = curWeaponsName;
  if (delWeaponsName.isEmpty()) {
    return;
  }

  for (int i = 0; i < cDefaultAmmos.size(); i++) {
    if (!cDefaultAmmos[i].first.compare(delWeaponsName)) {
      QMessageBox deniedMsg(this);
      deniedMsg.setIcon(QMessageBox::Warning);
      deniedMsg.setWindowTitle(QMessageBox::tr("Weapons - Warning"));
      deniedMsg.setText(
          QMessageBox::tr("Cannot delete default weapon set '%1'!")
              .arg(cDefaultAmmos[i].first));
      deniedMsg.setTextFormat(Qt::PlainText);
      deniedMsg.setWindowModality(Qt::WindowModal);
      deniedMsg.exec();
      return;
    }
  }

  QMessageBox reallyDeleteMsg(this);
  reallyDeleteMsg.setIcon(QMessageBox::Question);
  reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Weapons - Are you sure?"));
  reallyDeleteMsg.setText(
      QMessageBox::tr("Do you really want to delete the weapon set '%1'?")
          .arg(delWeaponsName));
  reallyDeleteMsg.setTextFormat(Qt::PlainText);
  reallyDeleteMsg.setWindowModality(Qt::WindowModal);
  reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

  if (reallyDeleteMsg.exec() == QMessageBox::Ok) {
    isDeleting = true;
    wconf->remove(delWeaponsName);
    QFile(cfgdir.absolutePath() + QStringLiteral("/Schemes/Ammo/") +
          curWeaponsName + QStringLiteral(".hwa"))
        .remove();
    Q_EMIT weaponsDeleted(delWeaponsName);
  }
}

void SelWeaponWidget::newWeaponsName() {
  save();
  QString newName = tr("New");
  if (wconf->contains(newName)) {
    // name already used -> look for an appropriate name:
    int i = 2;
    while (wconf->contains(newName = tr("New (%1)").arg(i++)));
  }
  setWeaponsName(newName);
  wconf->insert(newName, cEmptyAmmoStore);
  Q_EMIT weaponsAdded(newName, cEmptyAmmoStore);
}

void SelWeaponWidget::setWeaponsName(const QString& name) {
  m_name->setText(name);

  curWeaponsName = name;

  if (!name.isEmpty() && wconf->contains(name)) {
    setWeapons(wconf->constFind(name).value());
  } else {
    setWeapons(cEmptyAmmoStore);
  }
}

void SelWeaponWidget::switchWeapons(const QString& name) {
  // Rescue old weapons set, then select new one
  save();
  setWeaponsName(name);
}

QStringList SelWeaponWidget::getWeaponNames() const { return wconf->keys(); }

void SelWeaponWidget::copy() {
  save();
  if (wconf->contains(curWeaponsName)) {
    QString ammo = getWeaponsString(curWeaponsName);
    QString newName = tr("Copy of %1").arg(curWeaponsName);
    if (wconf->contains(newName)) {
      // name already used -> look for an appropriate name:
      int i = 2;
      while (wconf->contains(
          newName = tr("Copy of %1 (%2)").arg(curWeaponsName).arg(i++)));
    }
    setWeaponsName(newName);
    setWeapons(ammo);
    wconf->insert(newName, ammo);
    Q_EMIT weaponsAdded(newName, ammo);
  }
}

QString SelWeaponWidget::fixWeaponSet(const QString& s) {
  int neededLength = cDefaultAmmoStore.size() / 4;
  int thisSetLength = s.size() / 4;

  QStringList sl;
  sl << s.left(thisSetLength) << s.mid(thisSetLength, thisSetLength)
     << s.mid(thisSetLength * 2, thisSetLength) << s.right(thisSetLength);

  for (int i = sl.length() - 1; i >= 0; --i) {
    sl[i] = sl[i].leftJustified(neededLength, '0', true);
  }

  return sl.join(QString());
}

void SelWeaponWidget::deletionDone() { isDeleting = false; }

void SelWeaponWidget::init() { isDeleting = false; }
