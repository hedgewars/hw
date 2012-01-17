#include "qpushbuttonwithsound.h"
#include <QMessageBox>
#include <HWDataManager.h>
#include <QDir>
#include <SDLInteraction.h>
#include <hwform.h>
#include <QSettings>
#include <gameuiconfig.h>

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

    QString soundsDir = QString("Sounds/");

    QStringList list = dataMgr.entryList(
            soundsDir,
            QDir::Files,
            QStringList() <<
                "shotgunreload.ogg"
            );
    if(!list.empty())
        SDLInteraction::instance().playSoundFile(dataMgr.findFileForRead(soundsDir + "/" + list[0]));
}
