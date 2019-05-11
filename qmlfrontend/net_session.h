#ifndef NET_SESSION_H
#define NET_SESSION_H

#include <QSharedPointer>
#include <QSslSocket>
#include <QStringList>
#include <QUrl>

class NetSession : public QObject {
  Q_OBJECT

  // clang-format off
  Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
  Q_PROPERTY(QAbstractSocket::SocketState state READ state NOTIFY stateChanged)
  Q_PROPERTY(QString nickname READ nickname WRITE setNickname NOTIFY nicknameChanged)
  Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
  Q_PROPERTY(SessionState sessionState READ sessionState NOTIFY sessionStateChanged)
  // clang-format on

 public:
  enum SessionState { NotConnected, Login, Lobby, Room, Game };
  Q_ENUMS(SessionState)

  explicit NetSession(QObject *parent = nullptr);

  QUrl url() const;
  QAbstractSocket::SocketState state() const;

  Q_INVOKABLE void open();

  QString nickname() const;
  QString password() const;
  SessionState sessionState() const;

 public slots:
  void setUrl(const QUrl &url);
  void setNickname(const QString &nickname);
  void setPassword(const QString &password);
  void close();

 signals:
  void urlChanged(const QUrl url);
  void stateChanged(QAbstractSocket::SocketState state);
  void nicknameChanged(const QString &nickname);
  void passwordChanged(const QString &password);
  void sessionStateChanged(SessionState sessionState);

 private slots:
  void onReadyRead();
  void parseNetMessage(const QStringList &message);
  void handleConnected(const QStringList &parameters);
  void handlePing(const QStringList &parameters);
  void handleBye(const QStringList &parameters);
  void handleUnknownCommand(const QStringList &parameters);
  void send(const QString &message);
  void send(const QString &message, const QString &param);
  void send(const QString &message, const QStringList &parameters);
  void send(const QStringList &message);
  void setSessionState(SessionState sessionState);

 private:
  QUrl m_url;
  QSharedPointer<QTcpSocket> m_socket;
  QString m_nickname;
  QString m_password;
  QStringList m_buffer;
  SessionState m_sessionState;
};

#endif  // NET_SESSION_H
