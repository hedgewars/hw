#include "gameconfig.h"

GameConfig::GameConfig()
{
    m_arguments
        << ""
        << "--internal"
        << "--landpreview";
}

const char** GameConfig::argv() const
{
    m_argv.resize(m_arguments.size());

    for (int i = 0; i < m_arguments.size(); ++i)
        m_argv[i] = m_arguments[i].data();

    return m_argv.data();
}

int GameConfig::argc() const
{
    return m_arguments.size();
}

const QList<QByteArray> GameConfig::config() const
{
    QList<QByteArray> cfg = m_cfg;
    cfg.append("\x01!");
    return cfg;
}

void GameConfig::clear()
{
    m_arguments.clear();
    m_cfg.clear();
}

void GameConfig::cmdSeed(const QByteArray& seed)
{
    cfgAppend("eseed " + seed);
}

void GameConfig::cmdMapgen(int mapgen)
{
    cfgAppend("e$mapgen " + QByteArray::number(mapgen));
}

bool GameConfig::isPreview()
{
    return true;
}

void GameConfig::cfgAppend(const QByteArray& cmd)
{
    quint8 len = cmd.size();
    m_cfg.append(QByteArray::fromRawData(reinterpret_cast<const char*>(&len), 1) + cmd);
}
