package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Comparator;

import org.hedgewars.hedgeroid.Utils;

import android.content.Context;
import android.widget.AdapterView.OnItemSelectedListener;

/**
 * Represents a map from the data directory
 */
public final class MapFile {
	public static final String MISSION_PREFIX = "Mission: "; // TODO move text generation to UI to allow translation
	public static final String MAP_DIRECTORY = "Maps";
	
	public final String name;
	public final boolean isMission;
	
	public MapFile(String name, boolean isMission) {
		this.name = name;
		this.isMission = isMission;
	}
	
	/**
	 * @throws FileNotFoundException if the sdcard is not available. Does NOT throw if the requested map file does not exist.
	 */
	public static File getFileForMapname(Context ctx, String mapname) throws FileNotFoundException {
		return new File(new File(Utils.getDataPathFile(ctx), MAP_DIRECTORY), mapname);
	}
	
	public static final Comparator<MapFile> MISSIONS_FIRST_NAME_ORDER = new Comparator<MapFile>() {
		public int compare(MapFile lhs, MapFile rhs) {
			if(lhs.isMission != rhs.isMission) {
				return lhs.isMission && !rhs.isMission ? -1 : 1;
			} else {
				return lhs.name.compareToIgnoreCase(rhs.name);
			}
		}
	};
	
	@Override
	public String toString() {
		return (isMission ? MISSION_PREFIX : "") + name;
	}

	public File getPreviewFile(Context c) throws FileNotFoundException {
		return new File(new File(new File(Utils.getDataPathFile(c), MAP_DIRECTORY), name), "preview.png");
	};
}
