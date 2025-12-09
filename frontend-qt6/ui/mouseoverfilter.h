#ifndef MOUSEOVERFILTER_H
#define MOUSEOVERFILTER_H

#include <QObject>

class Ui_HWForm;
class MouseOverFilter : public QObject
{
        Q_OBJECT
    public:
        explicit MouseOverFilter(QObject *parent = 0);
        void setUi(Ui_HWForm *uiForm);
    protected:
        bool eventFilter( QObject *dist, QEvent *event );
    Q_SIGNALS:

    public Q_SLOTS:

    private:
        Ui_HWForm *ui;

};

#endif // MOUSEOVERFILTER_H
