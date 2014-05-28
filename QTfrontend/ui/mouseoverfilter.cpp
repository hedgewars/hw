
#include <QEvent>
#include <QWidget>
#include <QStackedLayout>
#include <QLabel>
#include <QLineEdit>
#include <QCheckBox>
#include <QListView>

#include "mouseoverfilter.h"
#include "ui/page/AbstractPage.h"
#include "ui_hwform.h"
#include "hwform.h"
#include "gameuiconfig.h"
#include "DataManager.h"
#include "SDLInteraction.h"

MouseOverFilter::MouseOverFilter(QObject *parent) :
    QObject(parent)
{
}

bool MouseOverFilter::eventFilter( QObject *dist, QEvent *event )
{
    AbstractPage* abstractpage;

    if (event->type() == QEvent::Enter)
    {
        QWidget * widget = dynamic_cast<QWidget*>(dist);

        abstractpage = qobject_cast<AbstractPage*>(ui->Pages->currentWidget());

        if (widget->whatsThis() != NULL)
            abstractpage->setButtonDescription(widget->whatsThis());
        else if (widget->toolTip() != NULL)
            abstractpage->setButtonDescription(widget->toolTip());
    }
    else if (event->type() == QEvent::FocusIn)
    {
        abstractpage = qobject_cast<AbstractPage*>(ui->Pages->currentWidget());

        // play a sound when mouse hovers certain ui elements
        QPushButton * button = dynamic_cast<QPushButton*>(dist);
        QLineEdit * textfield = dynamic_cast<QLineEdit*>(dist);
        QCheckBox * checkbox = dynamic_cast<QCheckBox*>(dist);
        QComboBox * droplist = dynamic_cast<QComboBox*>(dist);
        QSlider * slider = dynamic_cast<QSlider*>(dist);
        QTabWidget * tab = dynamic_cast<QTabWidget*>(dist);
        QListView * listview = dynamic_cast<QListView*>(dist);
        if (button || textfield || checkbox || droplist || slider || tab || listview)
        {
            SDLInteraction::instance().playSoundFile("/Sounds/steps.ogg");
        }
    }
    else if (event->type() == QEvent::Leave)
    {
        abstractpage = qobject_cast<AbstractPage*>(ui->Pages->currentWidget());

        if (abstractpage->getDefaultDescription() != NULL)
        {
            abstractpage->setButtonDescription( * abstractpage->getDefaultDescription());
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
