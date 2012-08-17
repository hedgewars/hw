package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.WeaponsetListPtr;

import android.content.Context;

public final class Weaponsets {
	private Weaponsets() {
		throw new AssertionError("This class is not meant to be instantiated");
	}
	
	public static File getUserWeaponsetsFile(Context c) {
		return new File(c.getFilesDir(), "weapons_user.ini");
	}
	
	public static File getBuiltinWeaponsetsFile(Context c) {
		return new File(c.getFilesDir(), "weapons_builtin.ini");
	}
	
	public static List<Weaponset> loadAllWeaponsets(Context c) throws IOException {
		List<Weaponset> result = loadBuiltinWeaponsets(c);
		result.addAll(loadUserWeaponsets(c));
		return result;
	}
	
	public static List<Weaponset> loadUserWeaponsets(Context c) throws IOException {
		return loadWeaponsets(c, getUserWeaponsetsFile(c));
	}
	
	public static List<Weaponset> loadBuiltinWeaponsets(Context c) throws IOException {
		return loadWeaponsets(c, getBuiltinWeaponsetsFile(c));
	}
	
	public static List<Weaponset> loadWeaponsets(Context c, File weaponsetFile) throws IOException {
		if(!weaponsetFile.isFile()) {
			// No file == no weaponsets, no error
			return new ArrayList<Weaponset>();
		}
		WeaponsetListPtr weaponsetListPtr = null;
		try {
			weaponsetListPtr = Flib.INSTANCE.flib_weaponsetlist_from_ini(weaponsetFile.getAbsolutePath());
			if(weaponsetListPtr == null) {
				throw new IOException("Unable to read weaponsets from "+weaponsetFile);
			}
			return weaponsetListPtr.deref();
		} finally {
			if(weaponsetListPtr != null) {
				Flib.INSTANCE.flib_weaponsetlist_destroy(weaponsetListPtr);
			}
		}
	}
	
	public static void saveUserWeaponsets(Context c, List<Weaponset> weaponsets) throws IOException {
		WeaponsetListPtr ptr = WeaponsetListPtr.createJavaOwned(weaponsets);
		Flib.INSTANCE.flib_weaponsetlist_to_ini(getUserWeaponsetsFile(c).getAbsolutePath(), ptr);
	}
	
	public static void deleteUserWeaponset(Context c, String setToDelete) throws IOException {
		List<Weaponset> userWeaponsets = loadUserWeaponsets(c);
		for(Iterator<Weaponset> iter = userWeaponsets.iterator(); iter.hasNext();) {
			Weaponset set = iter.next();
			if(set.name.equals(setToDelete)) {
				iter.remove();
				break;
			}
		}
		saveUserWeaponsets(c, userWeaponsets);
	}
	
	public static List<String> toNameList(List<Weaponset> weaponsets) {
		List<String> result = new ArrayList<String>();
		for(Weaponset weaponset : weaponsets) {
			result.add(weaponset.name);
		}
		return result;
	}
}
