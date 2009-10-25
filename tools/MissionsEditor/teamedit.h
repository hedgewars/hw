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

protected:
    void changeEvent(QEvent *e);

private:
    Ui::TeamEdit *m_ui;
};

#endif // TEAMEDIT_H
