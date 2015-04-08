#ifndef HWENGINE_H
#define HWENGINE_H

#include <QObject>
#include <QByteArray>
#include <QVector>
#include <QPixmap>

#include "flib.h"

class QQmlEngine;

class HWEngine : public QObject
{
    Q_OBJECT
public:
    explicit HWEngine(QQmlEngine * engine, QObject *parent = 0);
    ~HWEngine();

    static void exposeToQML();
    Q_INVOKABLE void getPreview();
    Q_INVOKABLE void runQuickGame();
    Q_INVOKABLE void runLocalGame();
    Q_INVOKABLE QString currentSeed();
    Q_INVOKABLE void getTeamsList();
    Q_INVOKABLE void resetGameConfig();

    Q_INVOKABLE void setTheme(const QString & theme);
    Q_INVOKABLE void setScript(const QString & script);
    Q_INVOKABLE void setScheme(const QString & scheme);
    Q_INVOKABLE void setAmmo(const QString & ammo);

    Q_INVOKABLE void tryAddTeam(const QString & teamName);
    Q_INVOKABLE void tryRemoveTeam(const QString & teamName);
    Q_INVOKABLE void changeTeamColor(const QString & teamName, int dir);

signals:
    void previewImageChanged();
    void localTeamAdded(const QString & teamName, int aiLevel);
    void localTeamRemoved(const QString & teamName);

    void playingTeamAdded(const QString & teamName, int aiLevel, bool isLocal);
    void playingTeamRemoved(const QString & teamName);

    void teamColorChanged(const QString & teamName, const QString & colorValue);

public slots:

private:
    QQmlEngine * m_engine;

    static void guiMessagesCallback(void * context, MessageType mt, const char * msg, uint32_t len);
    void fillModels();

private slots:
    void engineMessageHandler(MessageType mt, const QByteArray &msg);
};

#endif // HWENGINE_H

