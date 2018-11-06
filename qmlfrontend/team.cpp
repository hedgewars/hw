#include "team.h"

Hedgehog::Hedgehog()
    : name(QObject::tr("unnamed", "default hedgehog name").toUtf8())
    , hat("NoHat")
    , hp(100)
    , level(0)
{
}

Team::Team()
    : name(QObject::tr("unnamed", "default team name").toUtf8())
    , color("12345678")
    , m_hedgehogsNumber(4)
{
    m_hedgehogs.resize(8);
}

void Team::resize(int number)
{
    m_hedgehogsNumber = number;
}

QVector<Hedgehog> Team::hedgehogs() const
{
    return m_hedgehogs.mid(0, m_hedgehogsNumber);
}
