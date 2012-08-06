package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MetaschemePtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.SchemelistPtr;

import android.content.Context;

/**
 * Functions for handling the persistent list of schemes.
 * Schemes in that list are identified by name (case sensitive).
 */
public final class Schemes {
	private Schemes() {
		throw new AssertionError("This class is not meant to be instantiated");
	}
	
	public static File getUserSchemesFile(Context c) {
		return new File(c.getFilesDir(), "schemes_user.ini");
	}
	
	public static File getBuiltinSchemesFile(Context c) {
		return new File(c.getFilesDir(), "schemes_builtin.ini");
	}
	
	public static Map<String, Scheme> loadUserSchemes(Context c) throws IOException {
		return loadSchemes(c, getUserSchemesFile(c));
	}
	
	public static Map<String, Scheme> loadBuiltinSchemes(Context c) throws IOException {
		return loadSchemes(c, getBuiltinSchemesFile(c));
	}
	
	public static Map<String, Scheme> loadSchemes(Context c, File schemeFile) throws IOException {
		Map<String, Scheme> result = new TreeMap<String, Scheme>();
		String metaschemePath = new File(Utils.getDataPathFile(c), "metasettings.ini").getAbsolutePath();
		if(!schemeFile.isFile()) {
			// No schemes file == no schemes, no error
			return new TreeMap<String, Scheme>();
		}
		MetaschemePtr meta = null;
		SchemelistPtr schemeListPtr = null;
		try {
			meta = Flib.INSTANCE.flib_metascheme_from_ini(metaschemePath);
			if(meta==null) {
				throw new IOException("Unable to read metascheme");
			}
			schemeListPtr = Flib.INSTANCE.flib_schemelist_from_ini(meta, schemeFile.getAbsolutePath());
			if(schemeListPtr == null) {
				throw new IOException("Unable to read schemelist");
			}
			List<Scheme> schemeList = schemeListPtr.deref();
			for(Scheme scheme : schemeList) {
				result.put(scheme.name, scheme);
			}
			return result;
		} finally {
			if(schemeListPtr != null) {
				Flib.INSTANCE.flib_schemelist_destroy(schemeListPtr);
			}
			if(meta != null) {
				Flib.INSTANCE.flib_metascheme_release(meta);
			}
		}
	}
	
	public static void saveUserSchemes(Context c, Map<String, Scheme> schemes) throws IOException {
		List<Scheme> schemeList = new ArrayList<Scheme>(schemes.values());
		Collections.sort(schemeList, Scheme.caseInsensitiveNameComparator);
		SchemelistPtr ptr = SchemelistPtr.createJavaOwned(schemeList);
		Flib.INSTANCE.flib_schemelist_to_ini(getUserSchemesFile(c).getAbsolutePath(), ptr);
	}
}
