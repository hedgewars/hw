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

    Q_INVOKABLE void connect(const QString & host, quint16 port);

    Q_INVOKABLE void sendChatMessage(const QString & msg);

    Q_INVOKABLE void joinRoom(const QString & roomName);
    Q_INVOKABLE void partRoom(const QString & message);

    Q_INVOKABLE QString myNickname();

signals:
    void errorMessage(const QString & message);
    void warningMessage(const QString & message);

    void previewIsRendering();
    void previewImageChanged();
    void localTeamAdded(const QString & teamName, int aiLevel);
    void localTeamRemoved(const QString & teamName);

    void playingTeamAdded(const QString & teamName, int aiLevel, bool isLocal);
    void playingTeamRemoved(const QString & teamName);

    void teamColorChanged(const QString & teamName, const QString & colorValue);
    void hedgehogsNumberChanged(const QString & teamName, int hedgehogsNumber);

    void netConnected();
    void netDisconnected(const QString & message);

    void lobbyClientAdded(const QString & clientName);
    void lobbyClientRemoved(const QString & clientName, const QString & reason);
    void lobbyChatLine(const QString & nickname, const QString & line);

    void roomClientAdded(const QString & clientName);
    void roomClientRemoved(const QString & clientName, const QString & reason);
    void roomChatLine(const QString & nickname, const QString & line);

    void movedToLobby();
    void movedToRoom();

    void seedChanged(const QString & seed);
    void themeChanged(const QString & theme);
    void scriptChanged(const QString & script);
    void featureSizeChanged(int featureSize);
    void mapGenChanged(int mapgen);
    void mapChanged(const QString & map);
    void mazeSizeChanged(int mazeSize);
    void templateChanged(int templ);
    void ammoChanged(const QString & ammo);
    void schemeChanged(const QString & scheme);

    void roomAdded(quint32 flags
                   , const QString & name
                   , int players
                   , int teams
                   , const QString & host
                   , const QString & map
                   , const QString & script
                   , const QString & scheme
                   , const QString & weapons);
    void roomUpdated(const QString & name
                   , quint32 flags
                   , const QString & newName
                   , int players
                   , int teams
                   , const QString & host
                   , const QString & map
                   , const QString & script
                   , const QString & scheme
                   , const QString & weapons);
    void roomRemoved(const QString & name);

public slots:

private:
    QQmlEngine * m_engine;
    QString m_myNickname;

    static void guiMessagesCallback(void * context, MessageType mt, const char * msg, uint32_t len);
    void fillModels();

private slots:
    void engineMessageHandler(MessageType mt, const QByteArray &msg);
};

#endif // HWENGINE_H

