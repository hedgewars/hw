#include "game_config.h"

GameConfig::GameConfig() : m_isPreview(true) { setPreview(m_isPreview); }

const char** GameConfig::argv() const {
  m_argv.resize(m_arguments.size());

  for (int i = 0; i < m_arguments.size(); ++i)
    m_argv[i] = m_arguments[i].data();

  return m_argv.data();
}

int GameConfig::argc() const { return m_arguments.size(); }

const QList<QByteArray> GameConfig::config() const {
  QList<QByteArray> cfg = m_cfg;
  cfg.append("\x01!");
  return cfg;
}

void GameConfig::clear() {
  m_arguments.clear();
  m_cfg.clear();
}

void GameConfig::cmdSeed(const QByteArray& seed) { cfgAppend("eseed " + seed); }

void GameConfig::cmdTheme(const QByteArray& theme) {
  cfgAppend("e$theme " + theme);
}

void GameConfig::cmdMapgen(int mapgen) {
  cfgAppend("e$mapgen " + QByteArray::number(mapgen));
}

void GameConfig::cmdTeam(const Team& team) {
  cfgAppend("eaddteam <hash> " + team.color + " " + team.name);

  for (const Hedgehog& h : team.hedgehogs()) {
    cfgAppend("eaddhh " + QByteArray::number(h.level) + " " +
              QByteArray::number(h.hp) + " " + h.name);
    cfgAppend("ehat " + h.hat);
  }
  cfgAppend(
      "eammloadt 9391929422199121032235111001200000000211100101011111000102");
  cfgAppend(
      "eammprob 0405040541600655546554464776576666666155510101115411111114");
  cfgAppend(
      "eammdelay 0000000000000205500000040007004000000000220000000600020000");
  cfgAppend(
      "eammreinf 1311110312111111123114111111111111111211111111111111111111");
  cfgAppend("eammstore");
}

bool GameConfig::isPreview() const { return m_isPreview; }

void GameConfig::setPreview(bool isPreview) {
  m_isPreview = isPreview;

  m_arguments.clear();

  if (m_isPreview) {
    m_arguments << ""
                << "--internal"
                << "--landpreview";

  } else {
    m_arguments << ""
                << "--internal"
                << "--nomusic";
  }
}

void GameConfig::cfgAppend(const QByteArray& cmd) {
  Q_ASSERT(cmd.size() < 256);

  quint8 len = cmd.size();
  m_cfg.append(QByteArray::fromRawData(reinterpret_cast<const char*>(&len), 1) +
               cmd);
}
