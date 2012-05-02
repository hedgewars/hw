#include <QMessageBox>
#include <QDir>

#include "qpushbuttonwithsound.h"
#include "DataManager.h"
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

    DataManager & dataMgr = DataManager::instance();

    if (this->isEnabled())
        SDLInteraction::instance().playSoundFile(dataMgr.findFileForRead("Sounds/roperelease.ogg"));
}
