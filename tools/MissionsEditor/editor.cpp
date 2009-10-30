#include <QtGui>
#include <QObject>
#include "editor.h"
#include "ui_editor.h"

editor::editor(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::editor)
{
    ui->setupUi(this);

    cbFlags
        << ui->cbForts
        << ui->cbMultiWeapon
        << ui->cbSolidLand
        << ui->cbBorder
        << ui->cbDivideTeams
        << ui->cbLowGravity
        << ui->cbLaserSight
        << ui->cbInvulnerable
        << ui->cbMines
        << ui->cbVampiric
        << ui->cbKarma
        << ui->cbArtillery
        << ui->cbOneClanMode
        ;
}

editor::~editor()
{
    delete ui;
}

void editor::on_actionLoad_triggered()
{
    QString fileName = QFileDialog::getOpenFileName(this, QString(), QString(), "Missions (*.txt)");

    if(!fileName.isEmpty())
        load(fileName);
}

void editor::load(const QString & fileName)
{
    int currTeam = -1;

    QFile file(fileName);

    if(!file.open(QIODevice::ReadOnly))
    {
        QMessageBox::warning(this, "File error", "No such file");
        return ;
    }

    QTextStream stream(&file);

    while(!stream.atEnd())
    {
        QString line = stream.readLine();
        if (line.startsWith("seed"))
            ui->leSeed->setText(line.mid(5));
        else
        if (line.startsWith("map"))
            ui->leMap->setText(line.mid(4));
        else
        if (line.startsWith("theme"))
            ui->leTheme->setText(line.mid(6));
        else
        if (line.startsWith("$turntime"))
            ui->sbTurnTime->setValue(line.mid(10).toInt());
        else
        if (line.startsWith("$casefreq"))
            ui->sbCrateDrops->setValue(line.mid(10).toInt());
        else
        if (line.startsWith("$damagepct"))
            ui->sbDamageModifier->setValue(line.mid(11).toInt());
        else
        if (line.startsWith("$gmflags"))
        {
            quint32 flags = line.mid(9).toInt();
            foreach(QCheckBox * cb, cbFlags)
            {
                cb->setChecked(flags & 1);
                flags >>= 1;
            }
        }
        else
        if (line.startsWith("addteam") && (currTeam < 5))
        {
            ++currTeam;
            line = line.mid(8);
            int spacePos = line.indexOf('\x20');
            quint32 teamColor = line.left(spacePos).toUInt();
            QString teamName = line.mid(spacePos + 1);

            TeamEdit * te = qobject_cast<TeamEdit *>(ui->twTeams->widget(currTeam));
            te->addTeam(teamName, teamColor);
        }
        else
        if (line.startsWith("fort") && (currTeam >= 0))
        {
            TeamEdit * te = qobject_cast<TeamEdit *>(ui->twTeams->widget(currTeam));
            te->setFort(line.mid(5));
        }
        else
        if (line.startsWith("grave") && (currTeam >= 0))
        {
            TeamEdit * te = qobject_cast<TeamEdit *>(ui->twTeams->widget(currTeam));
            te->setGrave(line.mid(6));
        }
        else
        if (line.startsWith("voicepack") && (currTeam >= 0))
        {
            TeamEdit * te = qobject_cast<TeamEdit *>(ui->twTeams->widget(currTeam));
            te->setVoicepack(line.mid(10));
        }
    }
}
