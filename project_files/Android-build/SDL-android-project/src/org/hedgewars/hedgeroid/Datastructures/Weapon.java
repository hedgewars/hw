/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package org.hedgewars.hedgeroid.Datastructures;

import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;

public class Weapon implements Comparable<Weapon>{
	public static final String DIRECTORY_WEAPON = "weapons";
	public static final int maxWeapons = PascalExports.HWgetNumberOfWeapons();
	
	private String name;
	private String QT;
	private String prob;
	private String delay;
	private String crate;
	
	public Weapon(String _name, String _QT, String _prob, String _delay, String _crate){
		name = _name;
		
		//Incase there's a newer ammoStore which is bigger we append with zeros
		StringBuffer sb = new StringBuffer();
		while(_QT.length() + sb.length() < maxWeapons){
			sb.append('0');
		}
		
		QT = String.format("e%s %s%s", "ammloadt", _QT, sb);
		prob = String.format("e%s %s%s", "ammprob", _prob, sb);
		delay = String.format("e%s %s%s", "ammdelay", _delay, sb);
		crate = String.format("e%s %s%s", "ammreinf", _crate, sb);
	}
	
	public String toString(){
		return name;
	}
		
	public int compareTo(Weapon another) {
		return name.compareTo(another.name);
	}
}
