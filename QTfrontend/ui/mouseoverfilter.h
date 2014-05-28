#ifndef MOUSEOVERFILTER_H
#define MOUSEOVERFILTER_H

#include <QObject>

#include "ui_hwform.h"
#include "ui/page/AbstractPage.h"

class MouseOverFilter : public QObject
{
        Q_OBJECT
    public:
        explicit MouseOverFilter(QObject *parent = 0);
        void setUi(Ui_HWForm *uiForm);
    protected:
        bool eventFilter( QObject *dist, QEvent *event );
    signals:

    public slots:

    private:
        Ui_HWForm *ui;

};

#endif // MOUSEOVERFILTER_H
