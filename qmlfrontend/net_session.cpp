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
      {"CONNECTED", &NetSession::handleConnected},
      {"PING", &NetSession::handlePing},
      {"BYE", &NetSession::handleBye}};

  auto handler =
      commandsMap.value(message[0], &NetSession::handleUnknownCommand);

  handler(this, message.mid(1));
}

void NetSession::handleConnected(const QStringList &parameters) {
  setSessionState(Login);
}

void NetSession::handlePing(const QStringList &parameters) {
  send("PONG", parameters);
}

void NetSession::handleBye(const QStringList &parameters) { close(); }

void NetSession::handleUnknownCommand(const QStringList &parameters) {
  Q_UNUSED(parameters);

  qWarning() << "Command is not recognized";
}

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
