#ifndef TEAMEDIT_H
#define TEAMEDIT_H

#include <QtGui/QWidget>

namespace Ui {
    class TeamEdit;
}

class TeamEdit : public QWidget {
    Q_OBJECT
public:
    TeamEdit(QWidget *parent = 0);
    ~TeamEdit();

    void reset();
    void setTeam(const QString & teamName = QString(), quint32 color = 0xdd0000);
    void addHedgehog(quint32 level = 0, quint32 health = 100, const QString & name = QString());
    void setFort(const QString & name);
    void setGrave(const QString & name);
    void setLastHHHat(const QString & name);
    void setLastHHCoords(int x, int y);
    void setVoicepack(const QString & name);
protected:
    void changeEvent(QEvent *e);

private:
    Ui::TeamEdit *m_ui;
};

#endif // TEAMEDIT_H
