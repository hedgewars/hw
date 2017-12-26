#ifndef GAMECONFIG_H
#define GAMECONFIG_H

#include <QList>
#include <QVector>

class GameConfig {
public:
    explicit GameConfig();

    const char** argv() const;
    int argc() const;
    const QList<QByteArray> config() const;

    void clear();
    void cmdSeed(const QByteArray& seed);
    void cmdMapgen(int mapgen);

    bool isPreview();

private:
    mutable QVector<const char*> m_argv;
    QList<QByteArray> m_arguments;
    QList<QByteArray> m_cfg;

    void cfgAppend(const QByteArray& cmd);
};

#endif // GAMECONFIG_H
