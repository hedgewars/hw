
#ifndef PAGE_ROOMLIST_H
#define PAGE_ROOMLIST_H

#include "pages.h"

class HWChatWidget;

class PageRoomsList : public AbstractPage
{
    Q_OBJECT

public:
    PageRoomsList(QWidget* parent, QSettings * config, SDLInteraction * sdli);

    QLineEdit * roomName;
    QLineEdit * searchText;
    QTableWidget * roomsList;
    QPushButton * BtnBack;
    QPushButton * BtnCreate;
    QPushButton * BtnJoin;
    QPushButton * BtnRefresh;
    QPushButton * BtnAdmin;
    QPushButton * BtnClear;
    QComboBox * CBState;
    QComboBox * CBRules;
    QComboBox * CBWeapons;
    HWChatWidget * chatWidget;

private:
    bool gameInLobby;
    QString gameInLobbyName;
    QStringList listFromServer;
    AmmoSchemeModel * ammoSchemeModel;

public slots:
    void setRoomsList(const QStringList & list);
    void setAdmin(bool);

private slots:
    void onCreateClick();
    void onJoinClick();
    void onRefreshClick();
    void onClearClick();
    void onJoinConfirmation(const QString &);

signals:
    void askForCreateRoom(const QString &);
    void askForJoinRoom(const QString &);
    void askForRoomList();
    void askJoinConfirmation(const QString &);
};

#endif
