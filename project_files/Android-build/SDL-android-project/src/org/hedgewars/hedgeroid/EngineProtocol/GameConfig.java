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

package org.hedgewars.hedgeroid.EngineProtocol;

import java.util.ArrayList;

import org.hedgewars.hedgeroid.Datastructures.GameMode;
import org.hedgewars.hedgeroid.Datastructures.Map;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.Weapon;

public class GameConfig {
	public GameMode mode = GameMode.MODE_LOCAL;
	public Map map = null;
	public String theme = null;
	public Scheme scheme = null;
	public Weapon weapon = null;
	
	public String style = null;
	public String training = null;
	public String seed = null;
	
	public ArrayList<Team> teams = new ArrayList<Team>();
	
	public GameConfig(){
		
	}
}
