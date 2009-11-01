#ifndef HEDGEHOGEDIT_H
#define HEDGEHOGEDIT_H

#include <QtGui/QFrame>

namespace Ui {
    class HedgehogEdit;
}

class HedgehogEdit : public QFrame {
    Q_OBJECT
public:
    HedgehogEdit(QWidget *parent = 0);
    ~HedgehogEdit();

    void setHedgehog(quint32 level = 0, quint32 health = 100, const QString & name = QString());
    void setHat(const QString & name);
    void setCoordinates(int x, int y);

protected:
    void changeEvent(QEvent *e);

private:
    Ui::HedgehogEdit *m_ui;
};

#endif // HEDGEHOGEDIT_H
