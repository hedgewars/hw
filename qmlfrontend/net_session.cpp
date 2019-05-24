#include "net_session.h"

NetSession::NetSession(QObject *parent) : QObject(parent) {}

QUrl NetSession::url() const { return m_url; }

QAbstractSocket::SocketState NetSession::state() const {
  if (m_socket)
    return m_socket->state();
  else
    return QAbstractSocket::UnconnectedState;
}

void NetSession::open() {
  m_socket.reset(new QTcpSocket());

  connect(m_socket.data(), &QAbstractSocket::stateChanged, this,
          &NetSession::stateChanged);
  connect(m_socket.data(), &QTcpSocket::readyRead, this,
          &NetSession::onReadyRead);

  m_socket->connectToHost(m_url.host(),
                          static_cast<quint16>(m_url.port(46631)));
}

QString NetSession::nickname() const { return m_nickname; }

QString NetSession::password() const { return m_password; }

NetSession::SessionState NetSession::sessionState() const {
  return m_sessionState;
}

void NetSession::setUrl(const QUrl &url) {
  if (m_url == url) return;

  m_url = url;
  emit urlChanged(m_url);
}

void NetSession::setNickname(const QString &nickname) {
  if (m_nickname == nickname) return;

  m_nickname = nickname;
  emit nicknameChanged(m_nickname);
}

void NetSession::setPassword(const QString &password) {
  if (m_password == password) return;

  m_password = password;
  emit passwordChanged(m_password);
}

void NetSession::close() {
  if (!m_socket.isNull()) {
    m_socket->disconnectFromHost();
    m_socket.clear();

    setSessionState(NotConnected);
  }
}

void NetSession::onReadyRead() {
  while (m_socket->canReadLine()) {
    auto line = QString::fromUtf8(m_socket->readLine().simplified());

    if (line.isEmpty()) {
      parseNetMessage(m_buffer);
      m_buffer.clear();
    } else {
      m_buffer.append(line);
    }
  }
}

void NetSession::parseNetMessage(const QStringList &message) {
  if (message.isEmpty()) {
    qWarning() << "Empty net message received";
    return;
  }

  qDebug() << "[SERVER]" << message;

  using Handler = std::function<void(NetSession *, const QStringList &)>;
  static QMap<QString, Handler> commandsMap{
      {"ADD_TEAM", &NetSession::handleAddTeam},
      {"ASKPASSWORD", &NetSession::handleAskPassword},
      {"BANLIST", &NetSession::handleBanList},
      {"BYE", &NetSession::handleBye},
      {"CFG", &NetSession::handleCfg},
      {"CHAT", &NetSession::handleChat},
      {"CLIENT_FLAGS", &NetSession::handleClientFlags},
      {"CONNECTED", &NetSession::handleConnected},
      {"EM", &NetSession::handleEm},
      {"ERROR", &NetSession::handleError},
      {"HH_NUM", &NetSession::handleHhNum},
      {"INFO", &NetSession::handleInfo},
      {"JOINED", &NetSession::handleJoined},
      {"JOINING", &NetSession::handleJoining},
      {"KICKED", &NetSession::handleKicked},
      {"LEFT", &NetSession::handleLeft},
      {"LOBBY:JOINED", &NetSession::handleLobbyJoined},
      {"LOBBY:LEFT", &NetSession::handleLobbyLeft},
      {"NICK", &NetSession::handleNick},
      {"NOTICE", &NetSession::handleNotice},
      {"PING", &NetSession::handlePing},
      {"PONG", &NetSession::handlePong},
      {"PROTO", &NetSession::handleProto},
      {"REDIRECT", &NetSession::handleRedirect},
      {"REMOVE_TEAM", &NetSession::handleRemoveTeam},
      {"REPLAY_START", &NetSession::handleReplayStart},
      {"ROOMABANDONED", &NetSession::handleRoomAbandoned},
      {"ROOM", &NetSession::handleRoom},
      {"ROOMS", &NetSession::handleRooms},
      {"ROUND_FINISHED", &NetSession::handleRoundFinished},
      {"RUN_GAME", &NetSession::handleRunGame},
      {"SERVER_AUTH", &NetSession::handleServerAuth},
      {"SERVER_MESSAGE", &NetSession::handleServerMessage},
      {"SERVER_VARS", &NetSession::handleServerVars},
      {"TEAM_ACCEPTED", &NetSession::handleTeamAccepted},
      {"TEAM_COLOR", &NetSession::handleTeamColor},
      {"WARNING", &NetSession::handleWarning},
  };

  auto handler =
      commandsMap.value(message[0], &NetSession::handleUnknownCommand);

  handler(this, message.mid(1));
}

void NetSession::handleConnected(const QStringList &parameters) {
  if (parameters.length() < 2 || parameters[1].toInt() < cMinServerVersion) {
    send("QUIT", "Server too old");
    emit error(tr("Server too old"));
    close();
  } else {
    setSessionState(Login);

    send("NICK", m_nickname);
    send("PROTO", QString::number(cProtocolVersion));
  }
}

void NetSession::handlePing(const QStringList &parameters) {
  send("PONG", parameters);
}

void NetSession::handleBye(const QStringList &parameters) { close(); }

void NetSession::handleUnknownCommand(const QStringList &parameters) {
  Q_UNUSED(parameters);

  qWarning() << "Command is not recognized";
}

void NetSession::handleAddTeam(const QStringList &parameters) {}

void NetSession::handleAskPassword(const QStringList &parameters) {}

void NetSession::handleBanList(const QStringList &parameters) {}

void NetSession::handleCfg(const QStringList &parameters) {}

void NetSession::handleChat(const QStringList &parameters) {}

void NetSession::handleClientFlags(const QStringList &parameters) {}

void NetSession::handleEm(const QStringList &parameters) {}

void NetSession::handleError(const QStringList &parameters) {}

void NetSession::handleHhNum(const QStringList &parameters) {}

void NetSession::handleInfo(const QStringList &parameters) {}

void NetSession::handleJoined(const QStringList &parameters) {}

void NetSession::handleJoining(const QStringList &parameters) {}

void NetSession::handleKicked(const QStringList &parameters) {}

void NetSession::handleLeft(const QStringList &parameters) {}

void NetSession::handleLobbyJoined(const QStringList &parameters) {}

void NetSession::handleLobbyLeft(const QStringList &parameters) {}

void NetSession::handleNick(const QStringList &parameters) {
  if (parameters.length()) setNickname(parameters[0]);
}

void NetSession::handleNotice(const QStringList &parameters) {}

void NetSession::handlePong(const QStringList &parameters) {
  Q_UNUSED(parameters)
}

void NetSession::handleProto(const QStringList &parameters) {}

void NetSession::handleRedirect(const QStringList &parameters) {}

void NetSession::handleRemoveTeam(const QStringList &parameters) {}

void NetSession::handleReplayStart(const QStringList &parameters) {}

void NetSession::handleRoomAbandoned(const QStringList &parameters) {}

void NetSession::handleRoom(const QStringList &parameters) {}

void NetSession::handleRooms(const QStringList &parameters) {}

void NetSession::handleRoundFinished(const QStringList &parameters) {}

void NetSession::handleRunGame(const QStringList &parameters) {}

void NetSession::handleServerAuth(const QStringList &parameters) {}

void NetSession::handleServerMessage(const QStringList &parameters) {}

void NetSession::handleServerVars(const QStringList &parameters) {}

void NetSession::handleTeamAccepted(const QStringList &parameters) {}

void NetSession::handleTeamColor(const QStringList &parameters) {}

void NetSession::handleWarning(const QStringList &parameters) {}

void NetSession::send(const QString &message) { send(QStringList(message)); }

void NetSession::send(const QString &message, const QString &param) {
  send(QStringList{message, param});
}

void NetSession::send(const QString &message, const QStringList &parameters) {
  send(QStringList(message) + parameters);
}

void NetSession::send(const QStringList &message) {
  Q_ASSERT(!m_socket.isNull());

  qDebug() << "[CLIENT]" << message;

  m_socket->write(message.join('\n').toUtf8() + "\n\n");
}

void NetSession::setSessionState(NetSession::SessionState sessionState) {
  if (m_sessionState == sessionState) return;

  m_sessionState = sessionState;

  emit sessionStateChanged(sessionState);
}
