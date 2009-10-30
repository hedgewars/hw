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

    void addTeam(const QString & teamName = QString(), quint32 color = 0xdd0000);
    void setFort(const QString & name);
    void setGrave(const QString & name);
    void setVoicepack(const QString & name);
protected:
    void changeEvent(QEvent *e);

private:
    Ui::TeamEdit *m_ui;
};

#endif // TEAMEDIT_H
