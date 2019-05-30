#ifndef NET_SESSION_H
#define NET_SESSION_H

#include <QSharedPointer>
#include <QSslSocket>
#include <QStringList>
#include <QUrl>

class PlayersListModel;
class RoomsListModel;
class NetSession : public QObject {
  Q_OBJECT

  const int cMinServerVersion = 3;
  const int cProtocolVersion = 60;

  // clang-format off
  Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
  Q_PROPERTY(QAbstractSocket::SocketState state READ state NOTIFY stateChanged)
  Q_PROPERTY(QString nickname READ nickname WRITE setNickname NOTIFY nicknameChanged)
  Q_PROPERTY(SessionState sessionState READ sessionState NOTIFY sessionStateChanged)
  Q_PROPERTY(QString room READ room NOTIFY roomChanged)
  Q_PROPERTY(QString passwordHash READ passwordHash WRITE setPasswordHash NOTIFY passwordHashChanged)
  // clang-format on

 public:
  enum SessionState { NotConnected, Login, Authentication, Lobby, Room, Game };
  Q_ENUMS(SessionState)

  explicit NetSession(QObject *parent = nullptr);
  ~NetSession() override;

  QUrl url() const;
  QAbstractSocket::SocketState state() const;

  QString nickname() const;
  SessionState sessionState() const;
  QString room() const;
  QString passwordHash() const;

 public slots:
  void open();
  void close();

  void setUrl(const QUrl &url);
  void setNickname(const QString &nickname);
  void setPasswordHash(const QString &passwordHash);

 signals:
  void urlChanged(const QUrl url);
  void stateChanged(QAbstractSocket::SocketState state);
  void nicknameChanged(const QString &nickname);
  void sessionStateChanged(SessionState sessionState);
  void warning(const QString &message);
  void error(const QString &message);
  void roomChanged(const QString &room);
  void passwordHashChanged(const QString &passwordHash);
  void passwordAsked();

 private slots:
  void onReadyRead();
  void parseNetMessage(const QStringList &message);
  void handleConnected(const QStringList &parameters);
  void handlePing(const QStringList &parameters);
  void handleBye(const QStringList &parameters);
  void handleUnknownCommand(const QStringList &parameters);
  void handleAddTeam(const QStringList &parameters);
  void handleAskPassword(const QStringList &parameters);
  void handleBanList(const QStringList &parameters);
  void handleCfg(const QStringList &parameters);
  void handleChat(const QStringList &parameters);
  void handleClientFlags(const QStringList &parameters);
  void handleEm(const QStringList &parameters);
  void handleError(const QStringList &parameters);
  void handleHhNum(const QStringList &parameters);
  void handleInfo(const QStringList &parameters);
  void handleJoined(const QStringList &parameters);
  void handleJoining(const QStringList &parameters);
  void handleKicked(const QStringList &parameters);
  void handleLeft(const QStringList &parameters);
  void handleLobbyJoined(const QStringList &parameters);
  void handleLobbyLeft(const QStringList &parameters);
  void handleNick(const QStringList &parameters);
  void handleNotice(const QStringList &parameters);
  void handlePong(const QStringList &parameters);
  void handleProto(const QStringList &parameters);
  void handleRedirect(const QStringList &parameters);
  void handleRemoveTeam(const QStringList &parameters);
  void handleReplayStart(const QStringList &parameters);
  void handleRoomAbandoned(const QStringList &parameters);
  void handleRoom(const QStringList &parameters);
  void handleRooms(const QStringList &parameters);
  void handleRoundFinished(const QStringList &parameters);
  void handleRunGame(const QStringList &parameters);
  void handleServerAuth(const QStringList &parameters);
  void handleServerMessage(const QStringList &parameters);
  void handleServerVars(const QStringList &parameters);
  void handleTeamAccepted(const QStringList &parameters);
  void handleTeamColor(const QStringList &parameters);
  void handleWarning(const QStringList &parameters);

  void send(const QString &message);
  void send(const QString &message, const QString &param);
  void send(const QString &message, const QStringList &parameters);
  void send(const QStringList &message);

  void sendPassword();

  void setSessionState(SessionState sessionState);
  void setRoom(const QString &room);

 private:
  QUrl m_url;
  QSharedPointer<QTcpSocket> m_socket;
  QSharedPointer<PlayersListModel> m_playersModel;
  QSharedPointer<RoomsListModel> m_roomsModel;
  QString m_nickname;
  QStringList m_buffer;
  SessionState m_sessionState;
  QString m_serverAuthHash;
  QString m_room;
  QString m_serverSalt;
  QString m_serverHash;
  QString m_clientSalt;
  QString m_passwordHash;

  Q_DISABLE_COPY(NetSession)
};

#endif  // NET_SESSION_H
