#include "mouseoverfilter.h"
#include "ui/page/AbstractPage.h"
#include "ui_hwform.h"

#include <QEvent>
#include <QWidget>
#include <QStackedLayout>
#include <QLabel>

MouseOverFilter::MouseOverFilter(QObject *parent) :
    QObject(parent)
{
}

bool MouseOverFilter::eventFilter( QObject *dist, QEvent *event )
{
    if (event->type() == QEvent::Enter)
    {
        QWidget * widget = dynamic_cast<QWidget*>(dist);

        abstractpage = qobject_cast<AbstractPage*>(ui->Pages->currentWidget());

        if (widget->whatsThis() != NULL)
            abstractpage->setButtonDescription(widget->whatsThis());
        else if (widget->toolTip() != NULL)
            abstractpage->setButtonDescription(widget->toolTip());

        return true;
    }
    else if (event->type() == QEvent::Leave)
    {
        abstractpage = qobject_cast<AbstractPage*>(ui->Pages->currentWidget());

        if (abstractpage->getDefautDescription() != NULL)
        {
            abstractpage->setButtonDescription( * abstractpage->getDefautDescription());
        }
        else
            abstractpage->setButtonDescription("");
    }

    return false;
}

void MouseOverFilter::setUi(Ui_HWForm *uiForm)
{
    ui = uiForm;
}
