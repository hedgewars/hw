#include <QMessageBox>
#include <QDir>

#include "qpushbuttonwithsound.h"
#include "HWDataManager.h"
#include "SDLInteraction.h"
#include "hwform.h"
#include "gameuiconfig.h"

QPushButtonWithSound::QPushButtonWithSound(QWidget *parent) :
    QPushButton(parent),
    isSoundEnabled(true)
{
    connect(this, SIGNAL(clicked()), this, SLOT(buttonClicked()));
}

void QPushButtonWithSound::buttonClicked()
{
    if ( !isSoundEnabled || !HWForm::config->isFrontendSoundEnabled())
        return;

    HWDataManager & dataMgr = HWDataManager::instance();

    if (this->isEnabled())
        SDLInteraction::instance().playSoundFile(dataMgr.findFileForRead("Sounds/roperelease.ogg"));
}
