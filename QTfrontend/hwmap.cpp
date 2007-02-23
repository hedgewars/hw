/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006, 2007 Igor Ulyanov <iulyanov@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

#include "hwmap.h"

HWMap::HWMap() :
  TCPBase(false)
{
}

HWMap::~HWMap()
{
}

void HWMap::getImage(std::string seed)
{
  m_seed=seed;
  Start();
}

QStringList HWMap::setArguments()
{
  QStringList arguments;
  arguments << QString("%1").arg(ipc_port);
  arguments << "landpreview";
  return arguments;
}

void HWMap::onClientDisconnect()
{
  QImage im((uchar*)(readbuffer.constData()), 256, 128, QImage::Format_Mono);
  im.setNumColors(2);
  emit ImageReceived(im);
}

void HWMap::SendToClientFirst()
{
  std::string toSend=std::string("eseed ")+m_seed;
  SendIPC(toSend.c_str());
  SendIPC("!");
}
