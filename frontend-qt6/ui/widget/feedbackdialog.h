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

#ifndef FEEDBACKDIALOG_H
#define FEEDBACKDIALOG_H

#include <QDialog>
#include <QPointer>

class QNetworkReply;
class QNetworkAccessManager;
class QCheckBox;
class QLineEdit;
class QTextBrowser;
class QLabel;

class FeedbackDialog : public QDialog {
  Q_OBJECT

 public:
  FeedbackDialog(QWidget* parent = 0);
  void EmbedSystemInfo();
  void LoadCaptchaImage();

  QPointer<QPushButton> BtnSend;
  QPointer<QPushButton> BtnViewInfo;
  QPointer<QCheckBox> CheckSendSpecs;
  QPointer<QLineEdit> summary;
  QPointer<QTextBrowser> description;
  QPointer<QLabel> info;
  QPointer<QLabel> label_summary;
  QPointer<QLabel> label_description;
  QPointer<QLabel> label_captcha;
  QPointer<QLabel> label_email;
  QPointer<QLabel> label_captcha_input;
  QPointer<QLineEdit> captcha_code;
  QPointer<QLineEdit> email;
  int captchaID;
  QString specs;

 private:
  void GenerateSpecs();
  QLayout* bodyLayoutDefinition();
  QLayout* footerLayoutDefinition();
  QNetworkAccessManager* GetNetManager();
  void ShowErrorMessage(const QString& msg);

  QPointer<QNetworkAccessManager> netManager;
  QPointer<QNetworkReply> captchaImageRequest;
  QPointer<QNetworkReply> genCaptchaRequest;
  QPointer<QNetworkAccessManager> nam;

 private Q_SLOTS:
  virtual void NetReply(QNetworkReply*);
  virtual void ShowSpecs();
  void SendFeedback();
  void finishedSlot(QNetworkReply* reply);
};

#endif  // FEEDBACKDIALOG_H
