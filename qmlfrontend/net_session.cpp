#include "net_session.h"

#include <QUuid>

#include "players_model.h"
#include "rooms_model.h"

NetSession::NetSession(QObject *parent)
    : QObject(parent),
      m_playersModel(new PlayersListModel()),
      m_roomsModel(new RoomsListModel()),
      m_sessionState(NotConnected) {}

NetSession::~NetSession() { close(); }

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

NetSession::SessionState NetSession::sessionState() const {
  return m_sessionState;
}

QString NetSession::room() const { return m_room; }

QString NetSession::passwordHash() const { return m_passwordHash; }

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

void NetSession::setPasswordHash(const QString &passwordHash) {
  if (m_passwordHash == passwordHash) return;

  m_passwordHash = passwordHash;
  emit passwordHashChanged(m_passwordHash);

  if (m_sessionState == Authentication) sendPassword();
}

void NetSession::setRoom(const QString &room) {
  if (m_room == room) return;

  m_room = room;
  emit roomChanged(m_room);
}

void NetSession::close() {
  if (!m_socket.isNull()) {
    m_socket->disconnectFromHost();
    m_socket.clear();

    setSessionState(NotConnected);
    setRoom({});
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

void NetSession::handleAskPassword(const QStringList &parameters) {
  if (parameters.length() != 1 || parameters[0].length() < 16) {
    qWarning("Bad ASKPASSWORD message");
    return;
  }

  setSessionState(Authentication);

  m_serverSalt = parameters[0];
  m_clientSalt = QUuid::createUuid().toString();

  if (m_passwordHash.isEmpty()) {
    emit passwordAsked();
  } else {
    sendPassword();
  }
}

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

void NetSession::handleLobbyJoined(const QStringList &parameters) {
  for (auto player : parameters) {
    if (player == m_nickname) {
      // check if server is authenticated or no authentication was performed at
      // all
      if (!m_serverAuthHash.isEmpty()) {
        emit error(tr("Server authentication error"));

        close();
      }

      setSessionState(Lobby);
    }

    m_playersModel->addPlayer(player, false);
  }
}

void NetSession::handleLobbyLeft(const QStringList &parameters) {
  if (parameters.length() == 1) {
    m_playersModel->removePlayer(parameters[0]);
  } else if (parameters.length() == 2) {
    m_playersModel->removePlayer(parameters[0], parameters[1]);
  } else {
    qWarning("Malformed LOBBY:LEFT message");
  }
}

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

void NetSession::handleRoom(const QStringList &parameters) {
  if (parameters.size() == 10 && parameters[0] == "ADD") {
    m_roomsModel->addRoom(parameters.mid(1));
  } else if (parameters.length() == 11 && parameters[0] == "UPD") {
    m_roomsModel->updateRoom(parameters[1], parameters.mid(2));

    // keep track of room name so correct name is displayed
    if (m_room == parameters[1]) {
      setRoom(parameters[2]);
    }
  } else if (parameters.size() == 2 && parameters[0] == "DEL") {
    m_roomsModel->removeRoom(parameters[1]);
  }
}

void NetSession::handleRooms(const QStringList &parameters) {
  if (parameters.size() % 9) {
    qWarning("Net: Malformed ROOMS message");
    return;
  }

  m_roomsModel->setRoomsList(parameters);
}

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

void NetSession::sendPassword() {
  /* When we got password hash, and server asked us for a password, perform
   * mutual authentication: at this point we have salt chosen by server. Client
   * sends client salt and hash of secret (password hash) salted with client
   * salt, server salt, and static salt (predefined string + protocol number).
   * Server should respond with hash of the same set in different order.
   */

  if (m_passwordHash.isEmpty() || m_serverSalt.isEmpty()) return;

  QString hash =
      QCryptographicHash::hash(m_clientSalt.toLatin1()
                                   .append(m_serverSalt.toLatin1())
                                   .append(m_passwordHash)
                                   .append(QByteArray::number(cProtocolVersion))
                                   .append("!hedgewars"),
                               QCryptographicHash::Sha1)
          .toHex();

  m_serverHash =
      QCryptographicHash::hash(m_serverSalt.toLatin1()
                                   .append(m_clientSalt.toLatin1())
                                   .append(m_passwordHash)
                                   .append(QByteArray::number(cProtocolVersion))
                                   .append("!hedgewars"),
                               QCryptographicHash::Sha1)
          .toHex();

  send("PASSWORD", QStringList{hash, m_clientSalt});
}

void NetSession::setSessionState(NetSession::SessionState sessionState) {
  if (m_sessionState == sessionState) return;

  m_sessionState = sessionState;

  emit sessionStateChanged(sessionState);
}
